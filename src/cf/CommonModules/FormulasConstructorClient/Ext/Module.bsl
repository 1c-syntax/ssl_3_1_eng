///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Opens the formula editor.
//
// Parameters:
//  Parameters - See FormulaEditingOptions
//  CompletionHandler - NotifyDescription 
//
Procedure StartEditingTheFormula(Parameters, CompletionHandler) Export
	
	OpenForm("DataProcessor.FormulasConstructor.Form.FormulaEdit", Parameters, , , , , CompletionHandler);
	
EndProcedure

// The FormulaParameters parameter constructor for the FormulaPresentation function.
// 
// Returns:
//  Structure:
//   * Formula - String
//   * Operands - String - an address in the temporary operand collection storage. The collection type can be: 
//                         ValueTable - see FieldsTable 
//                         ValueTree - see FieldsTree 
//                         DataCompositionSchema - the operand list is taken from the FilterAvailableFields collection
//                                                  of the Settings Composer. You can override the collection name
//                                                  in the DCSCollectionName parameter.
//   * Operators - String - an address in the temporary operator collection storage. The collection type can be: 
//                         ValueTable - see FieldsTable 
//                         ValueTree - see FieldsTree 
//                         DataCompositionSchema - the operand list is taken from the FilterAvailableFields collection
//                                                  of the Settings Composer. You can override the collection name
//                                                  in the DCSCollectionName parameter.
//   * OperandsDCSCollectionName  - String - a field collection name in the Settings Composer. Use the parameter
//                                          if a data composition schema is passed in the Operands parameter.
//                                          The default value is FilterAvailableFields.
//   * OperatorsDCSCollectionName - String - a field collection name in the Settings Composer. Use the parameter
//                                          if a data composition schema is passed in the Operators parameter.
//                                          The default value is FilterAvailableFields.
//   * Description - Undefined - the description is not used for the formula and the field is not available.
//                  - String       - 
//                                   
//   * ForQuery   - Boolean - the formula is for inserting in a query. This parameter affects the default operator list
//                             and the selection of the formula check algorithm.
//
Function FormulaEditingOptions() Export
	
	Return FormulasConstructorClientServer.FormulaEditingOptions();
	
EndFunction

// Handler of expanding the list being connected.
// 
// Parameters:
//  Form   - ClientApplicationForm - the list owner.
//  Item - FormTable - a list where string expansion is executed.
//  String  - Number - list string ID.
//  Cancel   - Boolean - indicates that expansion is canceled.
//
Procedure ListOfFieldsBeforeExpanding(Form, Item, String, Cancel) Export
	
	FieldListSettings = FieldListSettings(Form, Item.Name);
	ItemsCollection = Form[Item.Name].FindByID(String).GetItems();
	If ItemsCollection.Count() > 0 And ItemsCollection[0].Field = Undefined Then
		Cancel = True;
		FieldListSettings.ExpandableBranches = FieldListSettings.ExpandableBranches + Format(String, "NZ=0; NG=0;") + ";";
		Form.AttachIdleHandler("Attachable_ExpandTheCurrentFieldListItem", 0.1, True);
	EndIf;
	
EndProcedure

// Handler of expanding the list being connected.
// Expands the current list item.
//
// Parameters:
//  Form - ClientApplicationForm
// 
Procedure ExpandTheCurrentFieldListItem(Form) Export
	
	For Each AttachedFieldList In Form.ConnectedFieldLists Do
		FieldList = Form.Items[AttachedFieldList.NameOfTheFieldList];
		
		For Each RowID In StrSplit(AttachedFieldList.ExpandableBranches, ";", False) Do
			FillParameters = New Structure;
			FillParameters.Insert("RowID", RowID);
			FillParameters.Insert("ListName", FieldList.Name);
			
			Form.Attachable_FillInTheListOfAvailableFields(FillParameters);
			FieldList.Expand(RowID);
		EndDo;
		
		AttachedFieldList.ExpandableBranches = "";
	EndDo;
	
EndProcedure

// Handler of dragging the list being connected
// 
// Parameters:
//  Form   - ClientApplicationForm - the list owner.
//  Item - FormTable - a list where dragging is executed.
//  DragParameters - DragParameters - contains a dragged value, an action type, 
//                                                      and possible values when dragging.
//  Perform - Boolean - if False, cannot start dragging.
//
Procedure ListOfFieldsStartDragging(Form, Item, DragParameters, Perform) Export
	
	NameOfTheFieldList = Item.Name;
	Attribute = Form[NameOfTheFieldList].FindByID(DragParameters.Value);
	
	FieldListSettings = FormulasConstructorClientServer.FieldListSettings(Form, NameOfTheFieldList);
	If FieldListSettings.ViewBrackets Then
		DragParameters.Value = "[" + Attribute.RepresentationOfTheDataPath + "]";
	Else
		DragParameters.Value = Attribute.RepresentationOfTheDataPath;
	EndIf;
	
EndProcedure

// Returns details of the current selected field of the list being connected.
//
// Parameters:
//  Form - ClientApplicationForm - the list owner.
//  NameOfTheFieldList - String - a list name set upon calling FormulasConstructor.AddFieldsListToForm.
//  
// Returns:
//  Structure:
//   * Name - String
//   * Title - String
//   * DataPath - String
//   * RepresentationOfTheDataPath - String
//   * Type - TypeDescription
//   * Parent - See TheSelectedFieldInTheFieldList
//
Function TheSelectedFieldInTheFieldList(Form, NameOfTheFieldList = Undefined) Export
	
	If Form.ConnectedFieldLists.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	If NameOfTheFieldList = Undefined Then
		FieldList = Form.CurrentItem; // FormTable
		NameOfTheFieldList = FieldList.Name;
		If FormulasConstructorClientServer.FieldListSettings(Form, NameOfTheFieldList)= Undefined Then
			NameOfTheFieldList = Form.ConnectedFieldLists[0].NameOfTheFieldList;
		EndIf;
	EndIf;
	
	FieldList = Form.Items[NameOfTheFieldList];
	CurrentData = FieldList.CurrentData;
	
	If CurrentData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return DescriptionOfTheSelectedField(CurrentData);
	
EndFunction

// Handler of the event of the string searching the list being connected.
// 
// Parameters:
//  Form   - ClientApplicationForm - the list owner.
//  Item - FormField - search bar.
//  Text - String - search string text.
//  StandardProcessing - Boolean - if False, cannot execute the standard action.
//
Procedure SearchStringEditTextChange(Form, Item, Text, StandardProcessing) Export
	
	UpdateNameOfSearchString(Form, Item.Name);
	
	Form[Form.NameOfCurrSearchString] = Text;
	
	Form.DetachIdleHandler("Attachable_PerformASearchInTheListOfFields");
	Form.DetachIdleHandler("Attachable_StartSearchInFieldsList");
	AttachedFieldListParameters = AttachedFieldListParameters(Form, Form.NameOfCurrSearchString);
	If AttachedFieldListParameters.UseBackgroundSearch Then
		Form.AttachIdleHandler("Attachable_StartSearchInFieldsList", 0.5, True);
	Else
		Form.AttachIdleHandler("Attachable_PerformASearchInTheListOfFields", 0.5, True);
	EndIf;
	
EndProcedure

// Handler of the event of the string searching the list being connected.
// 
// Parameters:
//  Form   - ClientApplicationForm - the list owner.
//  Item - FormButton -
//  DeleteStandardDataProcessor - Boolean -
//
Procedure SearchStringClearing(Form, Item, DeleteStandardDataProcessor = Undefined) Export

	UpdateNameOfSearchString(Form, Item.Name);
	
	AttachedFieldList = AttachedFieldListParameters(Form, Form.NameOfCurrSearchString);
	
	If AttachedFieldList.UseBackgroundSearch Then
		AdditionalParameters = HandlerParameters();
		AdditionalParameters.RunAtServer = True;
		AdditionalParameters.OperationKey = "ClearUpSearchString";
		Form.Attachable_FormulaEditorHandlerClient(Item.Name, AdditionalParameters);
		Item = Form.Items[StrReplace(Item.Name, "Clearing", "")];
		Item.UpdateEditText();
	EndIf;
	
	SearchStringEditTextChange(Form, Item, "", DeleteStandardDataProcessor);
	
EndProcedure

#EndRegion

#Region Internal

// Parameters:
//  Operator - See TheSelectedFieldInTheFieldList
//
Function ExpressionToInsert(Operator) Export
	
	If ValueIsFilled(Operator.ExpressionToInsert) Then
		Return Operator.ExpressionToInsert;
	EndIf;
	
	Result = Operator.Title + "()";
	
	If Not ValueIsFilled(Operator.Parent) Then
		Return "";
	EndIf;
	
	OperatorsGroup = Operator.Parent; // See TheSelectedFieldInTheFieldList
	OperatorGroupName = OperatorsGroup.Name;
	
	If OperatorGroupName = "Separators" Then
		Result = "+ """ + Operator.Title + """ +";
		If Operator.Name = "[ ]" Then
			Result = "+ "" "" +";
		EndIf;
	EndIf;
	
	If OperatorGroupName = "LogicalOperatorsAndConstants"
		Or OperatorGroupName = "Operators"
		Or OperatorGroupName = "OperationsOnStrings"
		Or OperatorGroupName = "LogicalOperations"
		Or OperatorGroupName = "ComparisonOperation" And Operator.Name <> "In" Then
		Result = Operator.Title;
	EndIf;
	
	If OperatorGroupName = "OtherFunctions" Then
		If Operator.Name = "[?]" Or Operator.Name = "Format" Then
			Result = Operator.Title + "(,,)";
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// 
// Parameters:
//  Form   - ClientApplicationForm -
//
Procedure StartSearchInFieldsList(Form) Export
	
	NameOfTheSearchString = Form.NameOfCurrSearchString;
	AttachedFieldList = AttachedFieldListParameters(Form, Form.NameOfCurrSearchString);
	
	Filter = Form[Form.NameOfCurrSearchString];
	FilterStringLength = StrLen(Filter);
	
	If FilterStringLength <> 0 And FilterStringLength >= AttachedFieldList.NumberOfCharsToAllowSearching Then
		Form.Items[NameOfTheSearchString+"Clearing"].Picture = PictureLib.TimeConsumingOperation16;
	EndIf;
	
	AdditionalParameters = HandlerParameters();
	AdditionalParameters.RunAtServer = True;
	AdditionalParameters.OperationKey = "RunBackgroundSearchInFieldList";
	
	TimeConsumingOperation = Undefined;
	
	Form.Attachable_FormulaEditorHandlerClient(TimeConsumingOperation, AdditionalParameters);
	
	If TimeConsumingOperation <> Undefined Then 
		CompletionParameters = New Structure("Form, JobID", Form, TimeConsumingOperation.JobID);
		
		CompletionNotification = New NotifyDescription("CompletionChangeBorderColor", ThisObject, CompletionParameters);
		ExecutionProgressNotification = New NotifyDescription("HandleSearchInFieldsList", ThisObject, Form); 
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(Form);
		IdleParameters.MessageText = NStr("en = 'Search for fields';");
		IdleParameters.UserNotification.Show = False;
		IdleParameters.OutputIdleWindow = False;
		IdleParameters.OutputMessages = False;
		IdleParameters.ExecutionProgressNotification = ExecutionProgressNotification;
		IdleParameters.Interval = 1;
		
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
	EndIf;
EndProcedure

// 
// 
// Parameters:
//  Result - See TimeConsumingOperationsClient.WaitCompletion.CompletionNotification2.Результат.
//  CompletionParameters - Structure:
//    * Form - ClientApplicationForm
//    * JobID - UUID - ID of the background task.
//
Procedure CompletionChangeBorderColor(Result, CompletionParameters) Export
			
	JobID = CompletionParameters.JobID;
	Form = CompletionParameters.Form;
	
	MatchingTasks = GetFromTempStorage(Form.AddressOfLongRunningOperationDetails);
	For Each Job In MatchingTasks Do
		If Job.Value = JobID Then
			NameOfTheSearchString = Job.Key;
			Break;
		EndIf;
	EndDo;
	
	If NameOfTheSearchString = Undefined Then
		Return;
	EndIf;
	
	Form.Items[NameOfTheSearchString+"Clearing"].Picture = PictureLib.InputFieldClear;
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Messages <> Undefined Then
		ProcessMessages(Form, Result.Messages, JobID);
	EndIf;

	ProcessSearchResults(Form, Result.ResultAddress, JobID);
			
EndProcedure

// 
// 
// Parameters:
//  Result - See TimeConsumingOperationsClient.WaitCompletion.CompletionNotification2.Результат
//  Form - ClientApplicationForm -
//
Procedure HandleSearchInFieldsList(Result, Form) Export
	If Result = Undefined Then
		Return;
	EndIf;
		
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	JobID = Result.JobID;
	
	NameOfTheSearchString = "";
	MatchingTasks = GetFromTempStorage(Form.AddressOfLongRunningOperationDetails);
	For Each Job In MatchingTasks Do
		If Job.Value = JobID Then
			NameOfTheSearchString = Job.Key;
			Break;
		EndIf;
	EndDo;
	
	If Result.Status = "Running" Then
		If ValueIsFilled(NameOfTheSearchString) Then
			Form.Items[NameOfTheSearchString+"Clearing"].Picture = PictureLib.TimeConsumingOperation16;
			AttachedFieldList = AttachedFieldListParameters(Form, NameOfTheSearchString);
			
			FilterStringLength = StrLen(Form[NameOfTheSearchString]);
			
			If FilterStringLength < AttachedFieldList.NumberOfCharsToAllowSearching Then
				Form.Items[NameOfTheSearchString+"Clearing"].Picture = PictureLib.InputFieldClear;
				Return;
			Else
				Form.Items[NameOfTheSearchString+"Clearing"].Picture = PictureLib.TimeConsumingOperation16;
			EndIf;
		EndIf;
		
		If Result.Messages <> Undefined Then
			ProcessMessages(Form, Result.Messages, JobID);
		EndIf;
	Else
		If ValueIsFilled(NameOfTheSearchString) Then
			Form.Items[NameOfTheSearchString+"Clearing"].Picture = PictureLib.InputFieldClear;
		EndIf;
	EndIf;
	
EndProcedure

// 
// 
// Parameters:
//  Form - ClientApplicationForm
//  Parameter - Arbitrary
//  AdditionalParameters - See HandlerParameters
//
Procedure FormulaEditorHandler(Form, Parameter, AdditionalParameters) Export
	If AdditionalParameters = Undefined Then
		AdditionalParameters = HandlerParameters();
	EndIf;
EndProcedure

// 
// 
// Returns:
//  Structure:
//   * RunAtServer - Boolean -
//   * OperationKey - String 
//
Function HandlerParameters() Export
	Parameters = New Structure;
	Parameters.Insert("RunAtServer", False);
	Parameters.Insert("OperationKey");
	Return Parameters;
EndFunction

#EndRegion

#Region Private

Function DescriptionOfTheSelectedField(Field)
	
	Result = New Structure;
	Result.Insert("Name");
	Result.Insert("Title");
	Result.Insert("DataPath");
	Result.Insert("RepresentationOfTheDataPath");
	Result.Insert("Type");
	Result.Insert("Parent");
	Result.Insert("ExpressionToInsert");
	
	FillPropertyValues(Result, Field);
	
	Parent = Field.GetParent();
	If Parent <> Undefined Then
		Result.Parent = DescriptionOfTheSelectedField(Parent);
	EndIf;
	
	Return Result;
	
EndFunction

Procedure ProcessMessages(Form, Messages, JobID)
	AdditionalParameters = HandlerParameters();
	AdditionalParameters.OperationKey = "HandleSearchMessage";
	AdditionalParameters.RunAtServer = True;
	
	ParameterStructure = New Structure("Messages, JobID");
	ParameterStructure.Messages = Messages;
	ParameterStructure.JobID = JobID;
	
	Form.Attachable_FormulaEditorHandlerClient(ParameterStructure, AdditionalParameters);
EndProcedure

Procedure ProcessSearchResults(Form, ResultAddress, JobID)
	AdditionalParameters = HandlerParameters();
	AdditionalParameters.OperationKey = "ProcessSearchResults";
	AdditionalParameters.RunAtServer = True;
	
	ParameterStructure = New Structure("ResultAddress, JobID");
	ParameterStructure.ResultAddress = ResultAddress;
	ParameterStructure.JobID = JobID;
	
	Form.Attachable_FormulaEditorHandlerClient(ParameterStructure, AdditionalParameters);
EndProcedure

Function AttachedFieldListParameters(Form, AttributeName)
	NameOfTheFieldList = NameOfFieldsListAttribute(AttributeName);
	If StrEndsWith(NameOfTheFieldList, "Clearing") Then
		NameOfTheFieldList = StrReplace(NameOfTheFieldList+" ", "Clearing ", "");
	EndIf;
	
	RowFilter = New Structure("NameOfTheFieldList", NameOfTheFieldList);
	FieldsListLine = Form.ConnectedFieldLists.FindRows(RowFilter);
	AttachedFieldList = FieldsListLine[0];
	Return AttachedFieldList;
EndFunction

Function NameOfFieldsListAttribute(NameOfFieldLIstSearchString)
	
	Result = StrReplace(NameOfFieldLIstSearchString, "SearchString", "");
	
	Return Result;
	
EndFunction

Procedure UpdateNameOfSearchString(Form, Name)
	RemovableEnding = "Clearing";
	If StrEndsWith(Name, RemovableEnding) Then
		NameLength = StrLen(Name) - StrLen(RemovableEnding);
		Form.NameOfCurrSearchString = Left(Name, NameLength); 
	Else
		Form.NameOfCurrSearchString = Name;
	EndIf;
EndProcedure

Function FieldListSettings(Form, NameOfTheFieldList)
	
	For Each AttachedFieldList In Form.ConnectedFieldLists Do
		If NameOfTheFieldList = AttachedFieldList.NameOfTheFieldList Then
			Return AttachedFieldList;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion
