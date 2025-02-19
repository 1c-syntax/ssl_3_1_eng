///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Management of AccessKinds and AccessValues tables in edit forms.

#Region FormTableItemsEventHandlersAccessValues

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//
Procedure AccessValuesPick(Form) Export
	
	AccessValueStartChoice(Form, Undefined, Undefined, Null);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//
Procedure AccessValuesOnChange(Form, Item) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	
	If Item.CurrentData <> Undefined
	   And Item.CurrentData.AccessKind = Undefined Then
		
		Filter = AccessManagementInternalClientServer.FilterInAllowedValuesEditFormTables(
			Form, Form.CurrentAccessKind);
		
		FillPropertyValues(Item.CurrentData, Filter);
		
		Item.CurrentData.RowNumberByKind = Parameters.AccessValues.FindRows(Filter).Count();
	EndIf;
	
	AccessManagementInternalClientServer.FillNumbersOfAccessValuesRowsByKind(
		Form, Items.AccessKinds.CurrentData);
	
	AccessManagementInternalClientServer.FillAllAllowedPresentation(
		Form, Items.AccessKinds.CurrentData);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//  NewRow - Boolean
//  Copy - Boolean
//
Procedure AccessValuesOnStartEdit(Form, Item, NewRow, Copy) Export
	
	Items = Form.Items;
	
	If Item.CurrentData.AccessValue = Undefined Then
		If Form.CurrentTypesOfValuesToSelect.Count() > 1
		   And Form.CurrentAccessKind <> Form.AccessKindExternalUsers
		   And Form.CurrentAccessKind <> Form.AccessKindUsers Then
			
			Items.AccessValuesAccessValue.ChoiceButton = True;
		Else
			Items.AccessValuesAccessValue.ChoiceButton = Undefined;
			Items.AccessValues.CurrentData.AccessValue = Form.CurrentTypesOfValuesToSelect[0].Value;
			Form.CurrentTypeOfValuesToSelect = Form.CurrentTypesOfValuesToSelect[0].Value
		EndIf;
	EndIf;
	
	Items.AccessValuesAccessValue.ClearButton
		= Form.CurrentTypeOfValuesToSelect <> Undefined
		And Form.CurrentTypesOfValuesToSelect.Count() > 1;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//  ValueSelected - Arbitrary
//  StandardProcessing - Boolean
//
Procedure AccessValuesChoiceProcessing(Form, Item, ValueSelected, StandardProcessing) Export
	
	Values = ?(TypeOf(ValueSelected) = Type("Array"),
		ValueSelected, CommonClientServer.ValueInArray(ValueSelected));
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	CurrentTypes = New Array;
	For Each ListItem In Form.CurrentTypesOfValuesToSelect Do
		CurrentTypes.Add(TypeOf(ListItem.Value));
	EndDo;
	
	Filter = AccessManagementInternalClientServer.FilterInAllowedValuesEditFormTables(
		Form, Form.CurrentAccessKind);
	
	For Each Value In Values Do
		If CurrentTypes.Find(TypeOf(Value)) = Undefined Then
			Continue;
		EndIf;
		Filter.Insert("AccessValue", Value);
		If Not ValueIsFilled(Parameters.AccessValues.FindRows(Filter)) Then
			NewRow = Parameters.AccessValues.Add();
			FillPropertyValues(NewRow, Filter);
		EndIf;
	EndDo;
	
	AccessManagementInternalClientServer.FillNumbersOfAccessValuesRowsByKind(Form,
		Form.Items.AccessKinds.CurrentData);
	
EndProcedure

// For internal use only.
Procedure AccessValueStartChoice(Form, Item, ChoiceData, StandardProcessing) Export
	
	Context = New Structure("Form, IsPick", Form, StandardProcessing = Null);
	StandardProcessing = False;
	
	If Form.CurrentTypesOfValuesToSelect.Count() = 1 Then
		
		Form.CurrentTypeOfValuesToSelect = Form.CurrentTypesOfValuesToSelect[0].Value;
		
		AccessValueStartChoiceCompletion(Context);
		Return;
		
	ElsIf Form.CurrentTypesOfValuesToSelect.Count() > 0 Then
		
		If Form.CurrentTypesOfValuesToSelect.Count() = 2 Then
		
			If Form.CurrentAccessKind = Form.AccessKindUsers Then
				Form.CurrentTypeOfValuesToSelect = PredefinedValue(
					"Catalog.Users.EmptyRef");
				
				AccessValueStartChoiceCompletion(Context);
				Return;
			EndIf;
			
			If Form.CurrentAccessKind = Form.AccessKindExternalUsers Then
				Form.CurrentTypeOfValuesToSelect = PredefinedValue(
					"Catalog.ExternalUsers.EmptyRef");
				
				AccessValueStartChoiceCompletion(Context);
				Return;
			EndIf;
		EndIf;
		
		Form.CurrentTypesOfValuesToSelect.ShowChooseItem(
			New CallbackDescription("AccessValueStartChoiceFollowUp", ThisObject, Context),
			NStr("en = 'Select data type';"),
			Form.CurrentTypesOfValuesToSelect[0]);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessValuesOnEditEnd(Form, Item, NewRow, CancelEdit) Export
	
	If Form.CurrentAccessKind = Undefined Then
		Parameters = AllowedValuesEditFormParameters(Form);
		
		Filter = New Structure("AccessKind", Undefined);
		
		FoundRows = Parameters.AccessValues.FindRows(Filter);
		
		For Each String In FoundRows Do
			Parameters.AccessValues.Delete(String);
		EndDo;
		
		CancelEdit = True;
	EndIf;
	
	If CancelEdit Then
		AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	EndIf;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//  StandardProcessing - Boolean
//
Procedure AccessValueClearing(Form, Item, StandardProcessing) Export
	
	Items = Form.Items;
	
	StandardProcessing = False;
	Form.CurrentTypeOfValuesToSelect = Undefined;
	Items.AccessValuesAccessValue.ClearButton = False;
	
	If Form.CurrentTypesOfValuesToSelect.Count() > 1
	   And Form.CurrentAccessKind <> Form.AccessKindExternalUsers
	   And Form.CurrentAccessKind <> Form.AccessKindUsers Then
		
		Items.AccessValuesAccessValue.ChoiceButton = True;
		Items.AccessValues.CurrentData.AccessValue = Undefined;
	Else
		Items.AccessValuesAccessValue.ChoiceButton = Undefined;
		Items.AccessValues.CurrentData.AccessValue = Form.CurrentTypesOfValuesToSelect[0].Value;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessValueAutoComplete(Form, Item, Text, ChoiceData, Waiting, StandardProcessing) Export
	
	GenerateAccessValuesChoiceData(Form, Text, ChoiceData, StandardProcessing);
	
EndProcedure

// For internal use only.
Procedure AccessValueTextInputCompletion(Form, Item, Text, ChoiceData, StandardProcessing) Export
	
	GenerateAccessValuesChoiceData(Form, Text, ChoiceData, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccessKinds

// For internal use only.
Procedure AccessKindsOnActivateRow(Form, Item) Export
	
	AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//
Procedure AccessKindsOnActivateCell(Form, Item) Export
	
	If Form.IsAccessGroupProfile Then
		Return;
	EndIf;
	
	Items = Form.Items;
	
	If Items.AccessKinds.CurrentItem <> Items.AccessKindsAllAllowedPresentation Then
		Items.AccessKinds.CurrentItem = Items.AccessKindsAllAllowedPresentation;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessKindsBeforeAddRow(Form, Item, Cancel, Copy, Parent, Group) Export
	
	If Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessKindsBeforeDeleteRow(Form, Item, Cancel) Export
	
	Form.CurrentAccessKind = Undefined;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//  NewRow - Boolean
//  Copy - Boolean
//
Procedure AccessKindsOnStartEdit(Form, Item, NewRow, Copy) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If NewRow Then
		CurrentData.Used = True;
	EndIf;
	
	AccessManagementInternalClientServer.FillAllAllowedPresentation(Form, CurrentData, False);
	
EndProcedure

// For internal use only.
Procedure AccessKindsOnEditEnd(Form, Item, NewRow, CancelEdit) Export
	
	AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//
Procedure AccessKindsAccessKindPresentationOnChange(Form, Item) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.AccessKindPresentation = "" Then
		CurrentData.AccessKind   = Undefined;
		CurrentData.Used = True;
	EndIf;
	
	AccessManagementInternalClientServer.FillAccessKindsPropertiesInForm(Form);
	AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//  ValueSelected - Arbitrary
//  StandardProcessing - Boolean
// 
Procedure AccessKindsAccessKindPresentationChoiceProcessing(Form, Item, ValueSelected, StandardProcessing) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	Filter = New Structure("AccessKindPresentation", ValueSelected);
	Rows = Parameters.AccessKinds.FindRows(Filter);
	
	If Rows.Count() > 0
	   And Rows[0].GetID() <> Form.Items.AccessKinds.CurrentRow Then
		
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The ""%1"" access kind is already selected.
			           |Please select another one.';"),
			ValueSelected));
		
		StandardProcessing = False;
		Return;
	EndIf;
	
	Filter = New Structure("Presentation", ValueSelected);
	CurrentData.AccessKind = Form.AllAccessKinds.FindRows(Filter)[0].Ref;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//
Procedure AccessKindsAllAllowedPresentationOnChange(Form, Item) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.AllAllowedPresentation = "" Then
		CurrentData.AllAllowed = False;
		If Form.IsAccessGroupProfile Then
			CurrentData.Predefined = False;
		EndIf;
	EndIf;
	
	If Form.IsAccessGroupProfile Then
		AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
		AccessManagementInternalClientServer.FillAllAllowedPresentation(Form, CurrentData, False);
	Else
		Form.Items.AccessKinds.EndEditRow(False);
		AccessManagementInternalClientServer.FillAllAllowedPresentation(Form, CurrentData);
	EndIf;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//  ValueSelected - Arbitrary
//  StandardProcessing - Boolean
//
Procedure AccessKindsAllAllowedPresentationChoiceProcessing(Form, Item, ValueSelected, StandardProcessing) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	Filter = New Structure("Presentation", ValueSelected);
	Name = Form.PresentationsAllAllowed.FindRows(Filter)[0].Name;
	
	If Form.IsAccessGroupProfile Then
		CurrentData.Predefined = (Name = "AllAllowed" Or Name = "AllDenied");
	EndIf;
	
	CurrentData.AllAllowed = (Name = "AllAllowedByDefault" Or Name = "AllAllowed");
	
EndProcedure

#Region ReportFormCommonFormEventHandlers

// Handles mouse double-click, "Enter" key, and hyperlink activation in report spreadsheets.
// See "Form field extension for a spreadsheet document field.Choice" in Syntax Assistant.
//
// Parameters:
//   ReportForm          - ClientApplicationForm - a report form.
//   Item              - FormField        - Spreadsheet document.
//   Area              - SpreadsheetDocumentRange - a selected value.
//   StandardProcessing - Boolean - indicates whether standard event processing is executed.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName = "Report.AccessRights"
	   And TypeOf(Area) = Type("SpreadsheetDocumentRange")
	   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rectangle
	   And TypeOf(Area.Details) = Type("String")
	   And StrStartsWith(Area.Details, "OpenListForm: ") Then
			
		StandardProcessing = False;
		OpenForm(Mid(Area.Details, StrLen("OpenListForm: ") + 1) + ".ListForm");
		Return;
	EndIf;
	
	If ReportForm.ReportSettings.FullName <> "Report.AccessRightsAnalysis" Then
		Return;
	EndIf;
	
	If TypeOf(Area) = Type("SpreadsheetDocumentRange")
		And Area.AreaType = SpreadsheetDocumentCellAreaType.Rectangle
		And Area.Details <> Undefined Then
		
		ReportForm.DetailProcessing = True;
	EndIf;
	
EndProcedure

// See ReportsClientOverridable.DetailProcessing
Procedure OnProcessDetails(ReportForm, Item, Details, StandardProcessing) Export
	
	OnProcessReportDrilldown(ReportForm, Item, Details, StandardProcessing, False);
	
EndProcedure

// See ReportsClientOverridable.AdditionalDetailProcessing.
Procedure OnProcessAdditionalDetails(ReportForm, Item, Details, StandardProcessing) Export
	
	OnProcessReportDrilldown(ReportForm, Item, Details, StandardProcessing, True);
	
EndProcedure

// See ReportsClientOverridable.AtStartValueSelection
Procedure AtStartValueSelection(ReportForm, SelectionConditions, ClosingNotification1, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName = "Report.AccessRightsAnalysis" Then
		AttheStartofSelectingReportValuesAnalysisAccessPermissions(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
	
	ElsIf ReportForm.ReportSettings.FullName = "Report.RolesRights" Then
		AttheStartofSelectingReportValuesRoleRights(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
	EndIf;
	
EndProcedure

Procedure ShowUserRightsOnTables(User) Export
	
	Filter = New Structure("User", User);
	VariantKey = "UserRightsToTables";
	PurposeUseKey = VariantKey;
	RefineUseDestinationKey(PurposeUseKey, Filter, "User");
	ShortenUseDestinationKey(PurposeUseKey);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", Filter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	OpenForm("Report.AccessRightsAnalysis.Form", ReportParameters, ThisObject);
	
EndProcedure

Procedure ShowReportUsersRights(Report, TablesToUse) Export
	
	VariantKey = "UsersRightsToReportTables";
	
	Filter = New Structure;
	Filter.Insert("Report", Report);
	Filter.Insert("CanSignIn", True);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", Filter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", VariantKey);
	ReportParameters.Insert("TablesToUse", TablesToUse);
	
	OpenForm("Report.AccessRightsAnalysis.Form", ReportParameters, ThisObject);
	
EndProcedure

// Opens the "AccessUpdateOnRecordsLevel" form.
//
// Parameters:
//  DisableProgressAutoUpdate - Boolean
//  ShowProgressPerLists - Boolean
//
Procedure OpenAccessUpdateOnRecordsLevelForm(DisableProgressAutoUpdate = False,
			ShowProgressPerLists = False) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("DisableProgressAutoUpdate",   DisableProgressAutoUpdate);
	FormParameters.Insert("ShowProgressPerLists", ShowProgressPerLists);
	
	OpenForm("InformationRegister.DataAccessKeysUpdate.Form.AccessUpdateOnRecordsLevel",
		FormParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

// Continue running the AccessValueStartChoice event handler.
Procedure AccessValueStartChoiceFollowUp(SelectedElement, Context) Export
	
	If SelectedElement <> Undefined Then
		Context.Form.CurrentTypeOfValuesToSelect = SelectedElement.Value;
		AccessValueStartChoiceCompletion(Context);
	EndIf;
	
EndProcedure

// Completes the AccessValueStartChoice event handler.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//
Procedure AccessValueStartChoiceCompletion(Context)
	
	Form    = Context.Form;
	Items = Form.Items;
	CurrentData = Items.AccessValues.CurrentData;
	
	If Context.IsPick Then
		Item = Items.AccessValues;
		CurrentRow = ?(CurrentData = Undefined, Undefined, CurrentData.AccessValue);
	Else
		Item = Items.AccessValuesAccessValue;
		
		If Not ValueIsFilled(CurrentData.AccessValue)
		   And CurrentData.AccessValue <> Form.CurrentTypeOfValuesToSelect Then
			
			CurrentData.AccessValue = Form.CurrentTypeOfValuesToSelect;
		EndIf;
		CurrentRow = CurrentData.AccessValue;
		
		Items.AccessValuesAccessValue.ChoiceButton = Undefined;
		Items.AccessValuesAccessValue.ClearButton
			= Form.CurrentTypeOfValuesToSelect <> Undefined
			And Form.CurrentTypesOfValuesToSelect.Count() > 1;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow", CurrentRow);
	FormParameters.Insert("IsAccessValueSelection");
	If Context.IsPick Then
		FormParameters.Insert("CloseOnChoice", False);
		FormParameters.Insert("MultipleChoice", True);
	EndIf;
	
	If Form.CurrentAccessKind = Form.AccessKindUsers Then
		FormParameters.Insert("UsersGroupsSelection", True);
		OpenForm("Catalog.Users.ChoiceForm", FormParameters, Item);
		Return;
		
	ElsIf Form.CurrentAccessKind = Form.AccessKindExternalUsers Then
		FormParameters.Insert("SelectExternalUsersGroups", True);
		OpenForm("Catalog.ExternalUsers.ChoiceForm", FormParameters, Item);
		Return;
	EndIf;
	
	Filter = New Structure("ValuesType", Form.CurrentTypeOfValuesToSelect);
	FoundRows = Form.AllTypesOfValuesToSelect.FindRows(Filter);
	
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;
	
	If FoundRows[0].HierarchyOfItems Then
		FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.FoldersAndItems);
	EndIf;
	
	OpenForm(FoundRows[0].TableName + ".ChoiceForm", FormParameters, Item);
	
EndProcedure

// Management of AccessKinds and AccessValues tables in edit forms.

Function AllowedValuesEditFormParameters(Form, CurrentObject = Undefined)
	
	Return AccessManagementInternalClientServer.AllowedValuesEditFormParameters(
		Form, CurrentObject);
	
EndFunction

Procedure GenerateAccessValuesChoiceData(Form, Text, ChoiceData, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
		
	If Form.CurrentAccessKind <> Form.AccessKindExternalUsers
	   And Form.CurrentAccessKind <> Form.AccessKindUsers Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ChoiceData = AccessManagementInternalServerCall.GenerateUserSelectionData(Text,
		False,
		Form.CurrentAccessKind = Form.AccessKindExternalUsers,
		Form.CurrentAccessKind <> Form.AccessKindUsers);
	
EndProcedure

// Process report details.

// 
Procedure OnProcessReportDrilldown(ReportForm, Item, Details,
			StandardProcessing, IsAdditionalDrilldown)
	
	If ReportForm.ReportSettings.FullName = "Report.AccessRightsAnalysis" Then
		Actions = AccessRightsAnalysisReportDrilldownActions(ReportForm, Item, Details);
		
	ElsIf ReportForm.ReportSettings.FullName = "Report.RolesRights" Then
		Actions = RolesRightsReportDrilldownActions(ReportForm, Item, Details);
	Else
		Return;
	EndIf;
	
	StandardProcessing = False;
	If Not ValueIsFilled(Actions) Then
		Return;
	EndIf;
	
	If IsAdditionalDrilldown
	 Or StrFind(Actions[0].Value.URL, "/command/") > 0 Then
		
		Notification = New CallbackDescription("ProcessDrilldownAction", ThisObject);
		ReportForm.ShowChooseFromMenu(Notification, Actions, Item);
	Else
		ProcessDrilldownAction(Actions[0], Undefined);
	EndIf;
	
EndProcedure

// 
Procedure ProcessDrilldownAction(Action, Context) Export
	
	If Action = Undefined Then
		Return;
	EndIf;
	
	Parameters = Action.Value;
	
	If ValueIsFilled(Parameters.URL) Then
		FileSystemClient.OpenURL(Parameters.URL);
		
	ElsIf Parameters.Value <> Undefined Then
		ShowValue(, Parameters.Value);
		
	ElsIf Parameters.User <> Undefined Then
		OpenUserRights(Parameters.User);
	Else
		OpenForm(Parameters.FullFormName, Parameters.FormParameters, Parameters.FormOwner);
	EndIf;
	
EndProcedure

// 
Function AccessRightsAnalysisReportDrilldownActions(ReportForm, Item, Details)
	
	Actions = New ValueList;
	CurVersion = ReportForm.Report.SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	If CurVersion = "UsersRightsToObject" Then
		Return Actions;
	EndIf;
	
	DetailsParameters = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
		ReportForm.ReportDetailsData, Details);
	
	If DetailsParameters.DetailsFieldName1 = "RightsValue" Then
		Return Actions;
	ElsIf DetailsParameters.DetailsFieldName1 = "OwnerOrUserSettings"
	        And DetailsParameters.FieldList.Get("ThisSettingsOwner") = True Then
		SettingsOwner = DetailsParameters.FieldList.Get("OwnerOrUserSettings");
		If Not ValueIsFilled(SettingsOwner) Then
			Return Actions;
		EndIf;
		Parameters = NewActionExecutionParameters();
		Parameters.FullFormName = "CommonForm.ObjectsRightsSettings";
		Parameters.FormParameters = New Structure("ObjectReference", SettingsOwner);
		Actions.Insert(0, Parameters, NStr("en = 'Access right settings';"));
		Return Actions;
	ElsIf DetailsParameters.DetailsFieldName1 = "AccessValue" Then
		AccessGroup = DetailsParameters.FieldList.Get("AccessGroup");
		If Not ValueIsFilled(AccessGroup)
		 Or TypeOf(AccessGroup) <> Type("CatalogRef.AccessGroups") Then
			Return Actions;
		EndIf;
		AccessKind = DetailsParameters.FieldList.Get("AccessKind");
		AccessValue = DetailsParameters.FieldList.Get("AccessValue");
		If AccessKind = Undefined Or AccessValue = Undefined Then
			Return Actions;
		EndIf;
		Parameters = NewActionExecutionParameters();
		Parameters.FullFormName = "Catalog.AccessGroups.ObjectForm";
		Parameters.FormParameters.Insert("Key", AccessGroup);
		Parameters.FormParameters.Insert("GotoViewAccess", AccessKind);
		Parameters.FormParameters.Insert("JumpToAccessValue", AccessValue);
		Actions.Insert(0, Parameters, NStr("en = 'View value in access group';"));
		Return Actions;
	EndIf;
	
	Table = DetailsParameters.FieldList.Get("MetadataObjectFullName");
	If ValueIsFilled(Table)
	   And Actions <> Undefined
	   And DetailsParameters.RoleRightsReportIsAvailable Then
		
		Filter = New Structure("MetadataObject", Table);
		AddOpenRolesRightsReportOption(ReportForm,
			"RightsOfRolesAndProfilesToMetadataObject", Details, Filter, Actions,
			?(DetailsParameters.DetailsFieldName1 = "Report",
				NStr("en = 'Role and profile rights that apply to report';"),
				NStr("en = 'Role and profile rights that apply to table';")));
		Filter = New Structure("MetadataObject, Profile", Table);
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, Filter, Actions,
			?(DetailsParameters.DetailsFieldName1 = "Report",
				NStr("en = 'Detailed profile rights that apply to report';"),
				NStr("en = 'Detailed profile rights that apply to table';")));
		Filter = New Structure("MetadataObject", Table);
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, Filter, Actions,
			?(DetailsParameters.DetailsFieldName1 = "Report",
				NStr("en = 'Detailed role rights that apply to report';"),
				NStr("en = 'Detailed role rights that apply to table';")));
	EndIf;
	
	URL = DetailsParameters.FieldList.Get("MetadataObjectURL");
	If DetailsParameters.DetailsFieldName1 = "ReportTitleMetadataObject"
	 Or DetailsParameters.DetailsFieldName1 = "FilterTitle" Then
		If Not ValueIsFilled(URL) Then
			Return Actions;
		EndIf;
		Parameters = NewActionExecutionParameters();
		Parameters.URL = URL;
		Actions.Insert(0, Parameters, ?(DetailsParameters.DetailsFieldName1 = "FilterTitle",
			NStr("en = 'Open';"), NStr("en = 'Show list';")));
		Return Actions;
	EndIf;
	
	If ValueIsFilled(URL) And Actions <> Undefined Then
		Parameters = NewActionExecutionParameters();
		Parameters.URL = URL;
		Actions.Add(Parameters, ?(DetailsParameters.DetailsFieldName1 = "Report",
			NStr("en = 'Open';"), NStr("en = 'Show list';")));
	EndIf;
	
	If DetailsParameters.DetailsFieldName1 = "User" Then
		User = DetailsParameters.FieldList.Get("User");
		If ValueIsFilled(User) Then
			Parameters = NewActionExecutionParameters();
			Parameters.User = User;
			Actions.Add(Parameters, NStr("en = 'View user right settings';"));
			Parameters = NewActionExecutionParameters();
			Parameters.Value = User;
			Actions.Add(Parameters, NStr("en = 'Open';"));
		EndIf;
	EndIf;
	
	Filter = New Structure;
	For Each FilterElement In ReportForm.Report.SettingsComposer.Settings.Filter.Items Do
		Setting = ReportForm.Report.SettingsComposer.UserSettings.Items.Find(
			FilterElement.UserSettingID);
		If Setting = Undefined Then
			Setting = FilterElement;
		EndIf;
		If Setting.Use Then
			If FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			 Or FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
				
				Filter.Insert(FilterElement.LeftValue, Setting.RightValue);
			EndIf;
		EndIf;
	EndDo;
	
	ParameterName = "User";
	ParameterValue = ParameterValue(ReportForm.Report.SettingsComposer, ParameterName);
	If ParameterValue <> Null Then
		Filter.Insert(ParameterName, ParameterValue);
	EndIf;
	
	If CurVersion = "UsersRightsToReportTables"
	   And DetailsParameters.DetailsFieldName1 <> "User"
	 Or CurVersion = "UserRightsToReportTables" Then
		
		Filter.Delete("Report");
	EndIf;
	
	If DetailsParameters.DetailsFieldName1 = "Right"
	 Or DetailsParameters.DetailsFieldName1 = "ViewRight"
	 Or DetailsParameters.DetailsFieldName1 = "EditRight"
	 Or DetailsParameters.DetailsFieldName1 = "InteractiveAddRight" Then
		
		VariantKey = "UserRightsToTable";
		
		If VariantKey = CurVersion Then
			Return Actions;
		EndIf;
		
		If DetailsParameters.FieldList["User"] <> Undefined Then
			Filter.Insert("User", DetailsParameters.FieldList["User"]);
		Else
			VariantKey = "UsersRightsToTable";
		EndIf;
		
		If DetailsParameters.FieldList["MetadataObject"] <> Undefined Then
			Filter.Insert("MetadataObject", DetailsParameters.FieldList["MetadataObject"]);
		ElsIf DetailsParameters.FieldList["Report"] <> Undefined Then
			Filter.Insert("Report", DetailsParameters.FieldList["Report"]);
			VariantKey = "UserRightsToReportTables";
		EndIf;
		
		If VariantKey = CurVersion Then
			Return Actions;
		EndIf;
		
		If VariantKey <> "UserRightsToReportTables" Then
			RightsValue = DetailsParameters.FieldList[DetailsParameters.DetailsFieldName1];
			If TypeOf(RightsValue) = Type("Number")  And RightsValue = 0
			 Or TypeOf(RightsValue) = Type("Boolean") And Not RightsValue Then
				Return Actions;
			EndIf;
		EndIf;
		
	ElsIf DetailsParameters.DetailsFieldName1 = "MetadataObject" Then
		
		VariantKey = "UsersRightsToTable";
		Filter.Insert("MetadataObject", DetailsParameters.FieldList["MetadataObject"]);

		If CurVersion = "UserRightsToTables"
			Or CurVersion = "UserRightsToReportTables" Then
			VariantKey = "UserRightsToTable";
		EndIf;
		
	ElsIf DetailsParameters.DetailsFieldName1 = "User" 
		And CurVersion <> "UserRightsToTables"
		And CurVersion <> "UserRightsToTable"
		And CurVersion <> "UserRightsToReportsTables" Then
		
		VariantKey = "UserRightsToTables";
		Filter.Insert("User", DetailsParameters.FieldList["User"]);
		Filter.Delete("CanSignIn");
		
		If CurVersion = "UsersRightsToTable" Then
			VariantKey = "UserRightsToTable";
		EndIf;
		
		If CurVersion = "UsersRightsToReportTables" Then
			VariantKey = "UserRightsToReportTables";
		EndIf;
		
		If CurVersion = "AccessRightsAnalysis"
		   And DetailsParameters.FieldList["OutputGroup"] = 1 Then
			
			VariantKey = "UserRightsToReportsTables";
		EndIf;
		
	ElsIf DetailsParameters.DetailsFieldName1 = "Report" Then
		
		If CurVersion = "UserRightsToReportTables"
		 Or CurVersion = "UsersRightsToReportTables" Then
			Return Actions;
		EndIf;
		
		VariantKey = "UsersRightsToReportTables";
		Filter.Insert("Report", DetailsParameters.FieldList["Report"]);
		
	Else
		DetailsValue = DetailsParameters.FieldList[DetailsParameters.DetailsFieldName1];
		If ValueIsFilled(DetailsValue)
		   And TypeOf(DetailsValue) <> Type("EnumRef.AdditionalAccessValues") Then
			
			If DetailsParameters.DetailsFieldName1 <> "User" Then
				Parameters = NewActionExecutionParameters();
				Parameters.Value = DetailsValue;
				Actions.Insert(0, Parameters, NStr("en = 'Open';"));
			EndIf;
		EndIf;
		
		Return Actions;
		
	EndIf;
	
	AddOpenAccessRightsAnalysisReportOption(ReportForm, VariantKey, Details, Filter, Actions);
	
	Return Actions;
	
EndFunction

Procedure AddOpenAccessRightsAnalysisReportOption(ReportForm, VariantKey, Details, Filter,
			Actions, PresentationAction = Undefined)
	
	If Filter.Property("MetadataObject")
	   And Not ValueIsFilled(Filter.MetadataObject)
	   And (    VariantKey = "UsersRightsToTable"
	      Or VariantKey = "UserRightsToTable" ) Then
		
		Return;
	EndIf;
	
	PurposeUseKey = VariantKey;
	RefineUseDestinationKey(PurposeUseKey, Filter, "Report");
	RefineUseDestinationKey(PurposeUseKey, Filter, "User");
	RefineUseDestinationKey(PurposeUseKey, Filter, "MetadataObject");
	ShortenUseDestinationKey(PurposeUseKey);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Details", Details);
	ReportParameters.Insert("Filter", Filter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	Parameters = NewActionExecutionParameters();
	Parameters.FullFormName = "Report.AccessRightsAnalysis.Form";
	Parameters.FormParameters = ReportParameters;
	Parameters.FormOwner  = ReportForm;
	
	If PresentationAction = Undefined Then
		Actions.Insert(0, Parameters,
			AccessRightsAnalysisReportOptionPresentation(VariantKey));
	Else
		Actions.Add(Parameters, ?(ValueIsFilled(PresentationAction), PresentationAction,
			AccessRightsAnalysisReportOptionPresentation(VariantKey)));
	EndIf;
	
EndProcedure

// 
Function RolesRightsReportDrilldownActions(ReportForm, Item, Details)
	
	Actions = New ValueList;
	DetailsParameters = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
		ReportForm.ReportDetailsData, Details);
	
	If DetailsParameters.DetailsFieldName1 = "Profile" Then
		Profile = DetailsParameters.FieldList["Profile"];
		If TypeOf(Profile) = Type("CatalogRef.AccessGroupProfiles")
		   And ValueIsFilled(Profile) Then
			
			Parameters = NewActionExecutionParameters();
			Parameters.Value = Profile;
			Actions.Insert(0, Parameters, NStr("en = 'Open';"));
		EndIf;
	EndIf;
	
	CurVersion = ReportForm.Report.SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	URL = DetailsParameters.FieldList.Get("MetadataObjectURL");
	If ValueIsFilled(URL) Then
		Parameters = NewActionExecutionParameters();
		Parameters.URL = URL;
		If StrFind(URL, "/command/") > 0 Then
			Actions.Add(Parameters, NStr("en = 'Run command';"));
		ElsIf StrStartsWith(URL, "e1cib/list/") Then
			Actions.Add(Parameters, NStr("en = 'Show list';"));
		ElsIf StrStartsWith(URL, "e1cib/app/") Then
			Actions.Add(Parameters, NStr("en = 'Open';"));
		EndIf;
	EndIf;
	
	If CurVersion = "DetailedRolesRightsToMetadataObject" Then
		Return Actions;
	EndIf;
	
	Filter = New Structure;
	SetParameterValue(Filter, "NameFormat", ReportForm);
	
	If DetailsParameters.DetailsFieldName1 = "AccessLevel" Then
		If ValueIsFilled(DetailsParameters.FieldList["FullObjectName"]) Then
			Filter.Insert("MetadataObject", DetailsParameters.FieldList["FullObjectName"]);
		Else
			Properties = New Structure("ReportSpreadsheetDocument");
			FillPropertyValues(Properties, ReportForm);
			If TypeOf(Properties.ReportSpreadsheetDocument) <> Type("SpreadsheetDocument") Then
				Return Actions;
			EndIf;
			ObjectScope = Properties.ReportSpreadsheetDocument.Area(Item.CurrentArea.Top, 2);
			If TypeOf(ObjectScope.Details) <> Type("DataCompositionDetailsID") Then
				Return Actions;
			EndIf;
			ObjectDecryptionParameters = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
				ReportForm.ReportDetailsData, ObjectScope.Details);
			If ValueIsFilled(ObjectDecryptionParameters.FieldList["FullObjectName"]) Then
				Filter.Insert("MetadataObject", ObjectDecryptionParameters.FieldList["FullObjectName"]);
			Else
				Return Actions;
			EndIf;
		EndIf;
	EndIf;
	
	If CurVersion = "RolesRights"
	   And DetailsParameters.DetailsFieldName1 = "AccessLevel" Then
		
		VariantKey = "DetailedRolesRightsToMetadataObject";
		
		If ValueIsFilled(DetailsParameters.FieldList["NameOfRole"]) Then
			Filter.Insert("Role", DetailsParameters.FieldList["NameOfRole"]);
		ElsIf TypeOf(ObjectDecryptionParameters) = Type("Structure") Then
			NumberLineItem = ObjectDecryptionParameters.FieldList["NumberLineItem"];
			If Not ValueIsFilled(NumberLineItem) Then
				Return Actions;
			EndIf;
			ScopeRoles = Properties.ReportSpreadsheetDocument.Area(Item.CurrentArea.Top - NumberLineItem,
				Item.CurrentArea.Left);
			If TypeOf(ScopeRoles.Details) <> Type("DataCompositionDetailsID") Then
				Return Actions;
			EndIf;
			ParametersDecryptionRoles = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
				ReportForm.ReportDetailsData, ScopeRoles.Details);
			If ValueIsFilled(ParametersDecryptionRoles.FieldList["NameOfRole"]) Then
				Filter.Insert("Role", ParametersDecryptionRoles.FieldList["NameOfRole"]);
			Else
				Return Actions;
			EndIf;
		EndIf;
		
	ElsIf CurVersion = "RolesRights"
	        And DetailsParameters.DetailsFieldName1 = "NameOfRole" Then
		
		VariantKey = "RightsOfRoleAndProfilesToMetadataObjects";
		
		SetParameterValue(Filter, "MetadataObject", ReportForm);
		SetParameterValue(Filter, "RightsOnDetails", ReportForm, True);
		SetParameterValue(Filter, "ShowPermissionsofNonInterfaceSubsystems", ReportForm, True);
		SetParameterValue(Filter, "DontWarnAboutLargeReportSize", ReportForm, True);
		
		AddOpenRolesRightsReportOption(ReportForm,
			VariantKey, Details, Filter, Actions);
		
		NameOfRole = DetailsParameters.FieldList["NameOfRole"];
		If Not ValueIsFilled(NameOfRole) Then
			Return Actions;
		EndIf;
		Filter.Insert("Role", NameOfRole);
		
	ElsIf CurVersion = "RolesRights"
	        And DetailsParameters.DetailsFieldName1 = "Level" Then
		
		VariantKey = "RightsOfRolesAndProfilesToMetadataObject";
		
		FullObjectName = DetailsParameters.FieldList["FullObjectName"];
		If Not ValueIsFilled(FullObjectName) Then
			Return Actions;
		EndIf;
		Filter.Insert("MetadataObject", FullObjectName);
		FilterWithoutRole = New Structure(New FixedStructure(Filter));
		SetParameterValue(Filter, "Role", ReportForm);
		
		FilterWithoutRole.Insert("Profile");
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, FilterWithoutRole, Actions);
		
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, Filter, Actions);
		
	ElsIf CurVersion = "RightsOfRolesAndProfilesToMetadataObject"
	        And (    DetailsParameters.DetailsFieldName1 = "Profile"
	           Or DetailsParameters.DetailsFieldName1 = "NameOfRole3") Then
		
		VariantKey = "DetailedRolesRightsToMetadataObject";
		
		Filter.Insert("MetadataObject", InitialFilterValue(ReportForm, "MetadataObject"));
		If Not ValueIsFilled(Filter.MetadataObject) Then
			Return Actions;
		EndIf;
		If DetailsParameters.DetailsFieldName1 = "NameOfRole3" Then
			Filter.Insert("Role", DetailsParameters.FieldList["NameOfRole3"]);
		Else
			Filter.Insert("Profile", DetailsParameters.FieldList["Profile3"]);
			If Not ValueIsFilled(Filter.Profile) Then
				Return Actions;
			EndIf;
		EndIf;
		
	ElsIf CurVersion = "RightsOfRoleAndProfilesToMetadataObjects" Then
		
		VariantKey = "DetailedRolesRightsToMetadataObject";
		
		If DetailsParameters.DetailsFieldName1 = "Level" Then
			Filter.Insert("MetadataObject", DetailsParameters.FieldList["FullObjectName"]);
		EndIf;
		If Not Filter.Property("MetadataObject")
		 Or Not ValueIsFilled(Filter.MetadataObject) Then
			Return Actions;
		EndIf;
		If DetailsParameters.DetailsFieldName1 = "AccessLevel" Then
			Filter.Insert("Profile", DetailsParameters.FieldList["Profile4"]);
			If Not ValueIsFilled(Filter.Profile) Then
				Return Actions;
			EndIf;
		Else
			InitialRole = InitialFilterValue(ReportForm, "Role");
			If ValueIsFilled(InitialRole) Then
				Filter.Insert("Role", InitialRole);
			Else
				SetParameterValue(Filter, "Role", ReportForm);
			EndIf;
		EndIf;
	Else
		Return Actions;
	EndIf;
	
	AddOpenRolesRightsReportOption(ReportForm, VariantKey, Details, Filter, Actions);
	
	Return Actions;
	
EndFunction

Procedure AddOpenRolesRightsReportOption(ReportForm, VariantKey, Details, Filter,
			Actions, PresentationAction = Undefined)
	
	FilterComposition = New Structure("Role, Profile", False, False);
	PurposeUseKey = VariantKey;
	RefineUseDestinationKey(PurposeUseKey, Filter, "Role",    FilterComposition.Role);
	RefineUseDestinationKey(PurposeUseKey, Filter, "Profile", FilterComposition.Profile);
	RefineUseDestinationKey(PurposeUseKey, Filter, "MetadataObject");
	ShortenUseDestinationKey(PurposeUseKey);
	If FilterComposition.Profile And Filter.Profile = Undefined Then
		FilterComposition.Profile = Undefined;
	EndIf;
	
	InitialSelection = New Structure(New FixedStructure(Filter));
	FixedFilter = New Structure;
	If InitialSelection.Property("MetadataObject")
	   And (    VariantKey = "DetailedRolesRightsToMetadataObject"
	      Or VariantKey = "RightsOfRolesAndProfilesToMetadataObject") Then
		
		FixedFilter.Insert("MetadataObject", InitialSelection.MetadataObject);
		InitialSelection.Delete("MetadataObject");
	EndIf;
	FixedFilter.Insert("InitialSelection", InitialSelection);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Details", Details);
	ReportParameters.Insert("Filter", FixedFilter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	Parameters = NewActionExecutionParameters();
	Parameters.FullFormName = "Report.RolesRights.Form";
	Parameters.FormParameters = ReportParameters;
	Parameters.FormOwner  = ReportForm;
	
	If PresentationAction = Undefined Then
		Actions.Insert(0, Parameters,
			RolesRightsReportOptionPresentation(VariantKey, FilterComposition));
	Else
		Actions.Add(Parameters, ?(ValueIsFilled(PresentationAction), PresentationAction,
			RolesRightsReportOptionPresentation(VariantKey, FilterComposition)));
	EndIf;
	
EndProcedure

// Intended for procedures "OnProcessAccessRightsAnalysisReportDrillDown"
// and "OnProcessRolesRightsReportDrillDown".
//
Function ParameterValue(SettingsComposer, ParameterName, UsedAlways = False)
	
	Parameter = SettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	Setting = SettingsComposer.UserSettings.Items.Find(Parameter.UserSettingID);
	
	If Setting <> Undefined
	   And (UsedAlways Or Setting.Use) Then
		
		Return Setting.Value;
	EndIf;
	
	If Parameter <> Undefined
	   And (UsedAlways Or Parameter.Use) Then
		
		Return Parameter.Value;
	EndIf;
	
	Return Null;
	
EndFunction

Function InitialFilterValue(ReportForm, ParameterName)
	
	If ReportForm.ParametersForm.Filter.Property(ParameterName) Then
		Filter = ReportForm.ParametersForm.Filter;
		
	ElsIf Not ReportForm.ParametersForm.Filter.Property("InitialSelection") Then
		Return Undefined;
	Else
		Filter = ReportForm.ParametersForm.Filter.InitialSelection;
		
		If TypeOf(Filter) <> Type("Structure")
		 Or Not Filter.Property(ParameterName) Then
			Return Undefined;
		EndIf;
	EndIf;
	
	Return Filter[ParameterName];
	
EndFunction

// Intended for procedures "OnProcessAccessRightsAnalysisReportDrillDown"
// and "OnProcessRolesRightsReportDrillDown".
//
Procedure RefineUseDestinationKey(Var_Key, Filter, PropertyName, ThereIsProperty = False)
	
	If Not Filter.Property(PropertyName) Then
		Return;
	EndIf;
	
	ThereIsProperty = True;
	Value = Filter[PropertyName];
	If Not ValueIsFilled(Value) Then
		Return;
	EndIf;
	
	RefType = New TypeDescription(
		"CatalogRef.MetadataObjectIDs,
		|CatalogRef.ExtensionObjectIDs,
		|CatalogRef.Users,
		|CatalogRef.UserGroups,
		|CatalogRef.ExternalUsers,
		|CatalogRef.ExternalUsersGroups");
	
	If RefType.ContainsType(TypeOf(Value)) Then
		Var_Key = Var_Key + "/" + String(Value.UUID());
	ElsIf TypeOf(Value) = Type("String") Then
		Var_Key = Var_Key + "/" + Value;
	EndIf;
	
EndProcedure

// Intended for procedures "OnProcessAccessRightsAnalysisReportDrillDown"
// and "OnProcessRolesRightsReportDrillDown".
//
Procedure ShortenUseDestinationKey(PurposeUseKey)
	
	If StrLen(PurposeUseKey) <= 128 Then
		Return;
	EndIf;
	
	PurposeUseKey =
		AccessManagementInternalServerCall.ShortcutUseDestinationKey(
			PurposeUseKey);
	
EndProcedure

// Intended for procedure "OnProcessRolesRightsReportDrillDown".
Procedure SetParameterValue(Filter, ParameterName, ReportForm, UsedAlways = False)
	
	ParameterValue = ParameterValue(ReportForm.Report.SettingsComposer, ParameterName, UsedAlways);
	If ParameterValue <> Null Then
		Filter.Insert(ParameterName, ParameterValue);
	EndIf;
	
EndProcedure

Function NewActionExecutionParameters()
	
	Result = New Structure;
	Result.Insert("URL", "");
	Result.Insert("Value");
	Result.Insert("User");
	Result.Insert("FullFormName", "");
	Result.Insert("FormParameters", New Structure);
	Result.Insert("FormOwner");
	
	Return Result;
	
EndFunction

Procedure OpenUserRights(User)
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If ClientRunParameters.SimplifiedAccessRightsSetupInterface Then
		FormName = "CommonForm.AccessRightsSimplified";
	Else
		FormName = "CommonForm.AccessRights";
	EndIf;
	
	Form = OpenForm("Catalog.Users.ObjectForm", New Structure("Key", User));
	OpenForm(FormName, New Structure("User", User), Form, , Form.Window);
	
EndProcedure

Function AccessRightsAnalysisReportOptionPresentation(VariantKey)
	
	If VariantKey = "AccessRightsAnalysis" Then
		Return NStr("en = 'Access rights analysis';");
		
	ElsIf VariantKey = "UsersRightsToTables" Then
		Return NStr("en = 'Users rights to tables';");
		
	ElsIf VariantKey = "UserRightsToTables" Then
		Return NStr("en = 'User rights to tables';");
		
	ElsIf VariantKey = "UsersRightsToTable" Then
		Return NStr("en = 'Users rights to a table';");
		
	ElsIf VariantKey = "UserRightsToTable" Then
		Return NStr("en = 'User rights to table';");
		
	ElsIf VariantKey = "UsersRightsToReportTables" Then
		Return NStr("en = 'Users rights to report tables';");
		
	ElsIf VariantKey = "UserRightsToReportTables" Then
		Return NStr("en = 'User rights to report tables';");
		
	ElsIf VariantKey = "UserRightsToReportsTables" Then
		Return NStr("en = 'User rights to reports tables';");
		
	ElsIf VariantKey = "UsersRightsToObject" Then
		Return NStr("en = 'User rights to object';");
		
	ElsIf VariantKey = "UsersRightsByAllowedValue" Then
		Return NStr("en = 'User rights by allowed value';");
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Unknown report option name: %1.';"), VariantKey);
	
	Raise(ErrorText, ErrorCategory.ConfigurationError);
	
EndFunction

Function RolesRightsReportOptionPresentation(VariantKey, FilterComposition)
	
	If VariantKey = "RolesRights" Then
		Return NStr("en = 'Role rights';");
		
	ElsIf VariantKey = "DetailedRolesRightsToMetadataObject" Then
		If FilterComposition.Profile = True Then
			Return NStr("en = 'Detailed profile rights that apply to metadata object';");
		ElsIf FilterComposition.Profile = Undefined Then
			Return NStr("en = 'Detailed profile rights that apply to metadata object';");
		ElsIf FilterComposition.Role Then
			Return NStr("en = 'Detailed role rights that apply to metadata object';");
		Else
			Return NStr("en = 'Detailed role rights that apply to metadata object';");
		EndIf;
		
	ElsIf VariantKey = "RightsOfRolesAndProfilesToMetadataObject" Then
		Return NStr("en = 'Role and profile rights that apply to metadata object';");
		
	ElsIf VariantKey = "RightsOfRoleAndProfilesToMetadataObjects" Then
		If FilterComposition.Role Then
			Return NStr("en = 'Role and profile rights that apply to metadata object';");
		Else
			Return NStr("en = 'Profile rights that apply to metadata objects';");
		EndIf;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Unknown report option name: %1.';"), VariantKey);
	
	Raise(ErrorText, ErrorCategory.ConfigurationError);
	
EndFunction


// Intended for procedure "OnValueChoiceStart".
Procedure AttheStartofSelectingReportValuesAnalysisAccessPermissions(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing)
	
	If SelectionConditions.FieldName = "MetadataObject" Then
		OnStartSelectMetadataObjectOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
		
	ElsIf SelectionConditions.FieldName = "DataElement" Then
		OnStartSelectDataElementOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
	EndIf;
	
EndProcedure

// 
Procedure OnStartSelectMetadataObjectOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing)
	
	StandardProcessing = False;
	
	Collections = New ValueList;
	Collections.Add("Catalogs");
	Collections.Add("Documents");
	Collections.Add("DocumentJournals");
	Collections.Add("ChartsOfCharacteristicTypes");
	Collections.Add("ChartsOfAccounts");
	Collections.Add("ChartsOfCalculationTypes");
	Collections.Add("InformationRegisters");
	Collections.Add("AccumulationRegisters");
	Collections.Add("AccountingRegisters");
	Collections.Add("CalculationRegisters");
	Collections.Add("BusinessProcesses");
	Collections.Add("Tasks");
	
	Selected_ = CommonClient.CopyRecursive(SelectionConditions.Marked);
	DeleteDisabledValues(Selected_);
	
	PickingParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	PickingParameters.ChooseRefs = True;
	PickingParameters.SelectedMetadataObjects = Selected_;
	PickingParameters.MetadataObjectsToSelectCollection = Collections;
	PickingParameters.ObjectsGroupMethod = "BySections,ByKinds";
	PickingParameters.Title = NStr("en = 'Pick tables';");
	
	Context = New Structure;
	Context.Insert("SelectionConditions", SelectionConditions);
	Context.Insert("ClosingNotification1", ClosingNotification1);
	
	Handler = New CallbackDescription("AfterSelectingMetadataObjects", ThisObject, Context);
	StandardSubsystemsClient.ChooseMetadataObjects(PickingParameters, Handler);
	
EndProcedure


// 
Procedure OnStartSelectDataElementOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing)
	
	StandardProcessing = False;
	
	Context = New Structure;
	Context.Insert("ClosingNotification1", ClosingNotification1);
	Context.Insert("InitialValue", ?(ValueIsFilled(SelectionConditions.Marked),
		SelectionConditions.Marked[0].Value, Undefined));
	
	List = AccessManagementInternalServerCall.ListOfTypesForSelection(
		SelectionConditions.AvailableTypes);
	
	Notification = New CallbackDescription(
		"OnStartSelectDataElementOfAccessRightsAnalysisReportAfterTypeSelected", ThisObject, Context);
	
	InitialItem = ?(ValueIsFilled(Context.InitialValue),
		List.FindByValue(TypeOf(Context.InitialValue)), Undefined);
	
	Title = NStr("en = 'Select data type';");
	
	List.ShowChooseItem(Notification, Title, InitialItem);
	
EndProcedure

// 
Procedure OnStartSelectDataElementOfAccessRightsAnalysisReportAfterTypeSelected(Result, Context) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FullName = AccessManagementInternalServerCall.FullNameOfReferenceTypeTable(
		Result.Value);
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentRow", Context.InitialValue);
	FormParameters.Insert("CloseOnChoice", True);
	
	Notification = New CallbackDescription(
		"OnStartSelectDataElementOfAccessRightsAnalysisReportAfterValueSelected", ThisObject, Context);
	
	If ValueIsFilled(FullName) Then
		OpenForm(FullName + ".ChoiceForm", FormParameters,,,,,Notification);
	Else
		FormParameters.Insert("DataItemType", Result.Value);
		OpenForm("Report.AccessRightsAnalysis.Form.SelectRegisterRow", FormParameters,,,,,Notification);
	EndIf;
	
	
EndProcedure

// 
Procedure OnStartSelectDataElementOfAccessRightsAnalysisReportAfterValueSelected(Result, Context) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	SelectedValues = CommonClientServer.ValueInArray(Result);
	RunCallback(Context.ClosingNotification1, SelectedValues);
	
EndProcedure


// Intended for procedure "OnValueChoiceStart".
Procedure AttheStartofSelectingReportValuesRoleRights(ReportForm, SelectionConditions, ClosingNotification1, StandardProcessing)
	
	If SelectionConditions.FieldName <> "Role"
	   And SelectionConditions.FieldName <> "MetadataObject" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Selected_ = CommonClient.CopyRecursive(SelectionConditions.Marked);
	DeleteDisabledValues(Selected_);
	Collections = New ValueList;
	
	PickingParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	PickingParameters.SelectedMetadataObjects = Selected_;
	PickingParameters.MetadataObjectsToSelectCollection = Collections;
	
	If SelectionConditions.FieldName = "Role" Then
		For Each ListItem In Selected_ Do
			ListItem.Value = "Role." + ListItem.Value;
		EndDo;
		PickingParameters.ObjectsGroupMethod = "ByKinds";
		PickingParameters.Title = NStr("en = 'Pick roles';");
		Collections.Add("Roles");
	Else
		PickingParameters.ObjectsGroupMethod = "ByKinds,BySections";
		PickingParameters.Title = NStr("en = 'Pick metadata objects';");
		PickingParameters.SelectCollectionsWhenAllObjectsSelected = True;
		AccessManagementInternalClientServer.AddMetadataObjectCollectionWithRights(Collections);
	EndIf;
	
	Context = New Structure;
	Context.Insert("SelectionConditions", SelectionConditions);
	Context.Insert("ClosingNotification1", ClosingNotification1);
	
	Handler = New CallbackDescription("AfterSelectingMetadataObjects", ThisObject, Context);
	StandardSubsystemsClient.ChooseMetadataObjects(PickingParameters, Handler);
	
EndProcedure

// Intended for procedure "OnValueChoiceStart".
Procedure AfterSelectingMetadataObjects(SelectedValues, Context) Export
	
	If Context.SelectionConditions.FieldName = "Role"
	   And ValueIsFilled(SelectedValues) Then
		
		For Each ListItem In SelectedValues Do
			ListItem.Value = StrSplit(ListItem.Value, ".")[1];
		EndDo;
	EndIf;
	
	RunCallback(Context.ClosingNotification1, SelectedValues);
	
EndProcedure

// Intended for procedure "OnValueChoiceStart".
Procedure DeleteDisabledValues(MarkedValues)
	
	IndexOf = MarkedValues.Count() - 1;
	
	While IndexOf >= 0 Do 
		Item = MarkedValues[IndexOf];
		IndexOf = IndexOf - 1;
		
		If Not ValueIsFilled(Item.Value) Then 
			MarkedValues.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion