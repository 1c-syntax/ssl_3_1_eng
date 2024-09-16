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

// Performs the specified accounting check with the specified parameters.
//
// Parameters:
//   Validation                    - CatalogRef.AccountingCheckRules
//                               - String - 
//                                 
//   CheckExecutionParameters - Structure
//                               - Array - 
//                                  
//                                 See AccountingAudit.CheckExecutionParameters.
//                               - Structure:
//       * Property1 - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//       * Property2 - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//       * Property3 - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//                                                     
//     - Array -  
//   ObjectsToCheck - AnyRef -  if passed, the check will be performed only for this object.
//                                     The check must support selective checking and it must have
//                                     the property Supports Selective checking set to True.
//                                     See AccountingAuditOverridable.OnDefineChecks.
//                      - Array - 
//
// Example:
//   1. Verification = Control of accounting.Checking the identifier ("Check the link integrity");
//      Accounting control.Perform a check (Check);
//   2. Check Completion Parameter = New Array;
//      Parameter1 = Accounting control.Check completion Parameter1("Closing the month", Company1, closing the month);
//      The parameter of the verification execution.Add(Parameter1);
//      Parameter2 = Accounting control.The parameter of the completion of the check ("Closing the month", Company2, closing the month);
//      The parameter of the verification execution.Add(Parameter2);
//      Perform a check ("Check the document execution", the check execution parameter);
//
Procedure ExecuteCheck(Val Validation, Val CheckExecutionParameters = Undefined, ObjectsToCheck = Undefined) Export
	
	If TypeOf(Validation) = Type("String") Then
		CheckToExecute = CheckByID(Validation);
		If CheckToExecute.IsEmpty() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Data integrity check with ID %1 does not exist (see %2).';"),
				Validation,
				"AccountingAuditOverridable.OnDefineChecks");
		EndIf;
	Else
		CommonClientServer.CheckParameter("AccountingAudit.ExecuteCheck", "Validation",
			Validation, Type("CatalogRef.AccountingCheckRules"));
		CheckToExecute = Validation;
	EndIf;
	
	If CheckExecutionParameters <> Undefined Then
		CheckCheckExecutionParameters(CheckExecutionParameters, "AccountingAudit.ExecuteCheck");
	EndIf;
	
	AccountingAuditInternal.ExecuteCheck(CheckToExecute, CheckExecutionParameters, ObjectsToCheck);
	
EndProcedure

// Performs checks according to a given context - a common feature that binds together a package of checks.
// If the specified attribute is set for a group of checks, then all checks of this group are performed. 
// In this case, the presence (or absence) of the specified attribute in the check itself does not matter.
// Checks with the Use flag set to False are skipped.
//
// Parameters:
//    AccountingChecksContext - DefinedType.AccountingChecksContext -  the context of the checks being performed.
//
// Example:
//    Accounting control.Perform a check in the context(Enumerations.Economic operations.Closing of the month);
//
Procedure ExecuteChecksInContext(AccountingChecksContext) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.ExecuteChecksInContext",
		"AccountingChecksContext", AccountingChecksContext,
		Metadata.DefinedTypes.AccountingChecksContext.Type);
	
	ChecksByContext = AccountingAuditInternal.ChecksByContext(AccountingChecksContext);
	
	MethodParameters        = New Map;
	CheckUpperBoundary = ChecksByContext.UBound();
	
	For IndexOfCheck = 0 To CheckUpperBoundary Do
		ParametersArray = New Array;
		ParametersArray.Add(ChecksByContext[IndexOfCheck]);
		
		MethodParameters.Insert(IndexOfCheck, ParametersArray);
	EndDo;
	
	ProcedureName = "AccountingAudit.ExecuteCheck";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Data integrity';");
	ExecutionParameters.WaitCompletion = Undefined;
	
	ExecutionResult = TimeConsumingOperations.ExecuteProcedureinMultipleThreads(
		ProcedureName,
		ExecutionParameters,
		MethodParameters);
	
	If ExecutionResult.Status <> "Completed2" Then
		If ExecutionResult.Status = "Error" Then
			Refinement = CommonClientServer.ExceptionClarification(ExecutionResult.ErrorInfo);
			Raise(Refinement.Text, Refinement.Category,,, ExecutionResult.ErrorInfo);
		ElsIf ExecutionResult.Status = "Canceled" Then
			ErrorText = NStr("en = 'The background job is canceled.';");
		Else
			ErrorText = NStr("en = 'Background job error';");
		EndIf;
		Raise ErrorText;
	EndIf;
	
	Results = GetFromTempStorage(ExecutionResult.ResultAddress); // Map
	If TypeOf(Results) <> Type("Map") Then
		ErrorText = NStr("en = 'The background job did not return a result';");
		Raise ErrorText;
	EndIf;
	
	For Each ResultDetails In Results Do
		Result = ResultDetails.Value; // See TimeConsumingOperations.ExecuteProcedure
		If Result.Status <> "Completed2" Then
			If Result.Status = "Error" Then
				Refinement = CommonClientServer.ExceptionClarification(Result.ErrorInfo);
				Raise(Refinement.Text, Refinement.Category,,, Result.ErrorInfo);
			ElsIf Result.Status = "Canceled" Then
				ErrorText = NStr("en = 'The background job is canceled.';");
			Else
				ErrorText = NStr("en = 'Background job error';");
			EndIf;
			Raise ErrorText;
		EndIf;
	EndDo;
	
	If MethodParameters.Count() <> Results.Count() Then
		ErrorText = NStr("en = 'Some checks were not performed';");
		Raise ErrorText;
	EndIf;
	
EndProcedure

// Returns a summary of the number of detected problems of the specified type of check.
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds -  link to the type of check.
//                              - String - 
//                              - Array of String - 
//   SearchByExactMap - Boolean -  adjusts accuracy capabilities. If True, then the search is
//                                based on the passed properties for equality, the remaining properties must be equal
//                                Undefined (the tabular part of the additional properties should be empty).
//                                If False, then the values of the other properties can be arbitrary, the main
//                                thing is that the corresponding properties are equal to the properties of the structure. By default, True.
//   ConsiderPersonResponsible    - Boolean -  if True, then only the problems with the unfilled responsible
//                                and those for which the current user is responsible are taken into account.
//                                By default, it is False.
//
// Returns:
//  Structure:
//    * Count - Number -  the total number of problems found.
//    * HasErrors - Boolean -  a sign of whether there are errors among the problems found (with the importance "Error").
//
// Example:
//   1) Result = Summary of informationspecifications ("System checks");
//   2) Type Check = New Array;
//      View check.Add("Closing the month");
//      View check.Add(Company);
//      View check.Add(months of closure);
//      Result = Summary Informationview Check(View Check);
//
Function SummaryInformationOnChecksKinds(ChecksKind = Undefined, SearchByExactMap = True, ConsiderPersonResponsible = False) Export
	
	ProcedureName = "AccountingAudit.SummaryInformationOnChecksKinds";
	If ChecksKind <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	EndIf;
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	Return AccountingAuditInternal.SummaryInformationOnChecksKinds(ChecksKind, SearchByExactMap, ConsiderPersonResponsible);
	
EndFunction

// Returns detailed information about identified problems of one or more types of verification of interest.
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds -  link to the type of check.
//                              - String - 
//                              - Array of String - 
//   SearchByExactMap - Boolean - 
//                                
//                                
//                                
//
// Returns:
//   ValueTable:
//     * ObjectWithIssue         - AnyRef -  a reference to the object that the problem is related to.
//     * IssueSeverity         - EnumRef.AccountingIssueSeverity -  The importance of the accounting problem
//                                  is "Information", "Warning", "Error", "Useful advice" and "Important information".
//     * CheckRule          - CatalogRef.AccountingCheckRules -  a completed check with a description of the problem.
//     * ChecksKind              - CatalogRef.ChecksKinds -  type of check.
//     * IssueSummary        - String -  text clarification of the found problem.
//     * EmployeeResponsible            - CatalogRef.Users -  filled in if
//                                  the verification algorithm has identified a specific person responsible for the identified problem.
//     * Detected                 - Date -  date and time when the problem was detected.
//     * AdditionalInformation - ValueStorage -  arbitrary additional information related 
//                                  to the identified problem.
//
// Example:
//   1) Result = Detailed informationspecifications ("System Checks");
//   2) Type Check = New Array;
//      View check.Add("Closing the month");
//      View check.Add(Company);
//      View check.Add(months of closure);
//      Result = Detailed Informationview Check(View Check);
//   3) Select all the problems of closing the month for all periods for the specified company:
//      Type of Check = New Array;
//      View check.Add("Closing the month");
//      View check.Add(Company);
//      Result = Detailed information about the type of verification (type of verification, False); 
//
Function DetailedInformationOnChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.DetailedInformationOnChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	Return AccountingAuditInternal.DetailedInformationOnChecksKinds(ChecksKind, SearchByExactMap);
	
EndFunction

// Returns verification by the passed ID.
//
// Parameters:
//   Id - String -  the string ID of the check. For example, "Check the link integrity".
//
// Returns: 
//   CatalogRef.AccountingCheckRules -  
//      
//
Function CheckByID(Id) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.CheckByID", "Id", Id, Type("String"));
	Return AccountingAuditInternal.CheckByID(Id);
	
EndFunction

// Returns the number of problems identified with the passed object.
//
// Parameters:
//   ObjectWithIssue - AnyRef -  the object to calculate the number of problems for.
//
// Returns:
//   Number
//
Function IssuesCountByObject(ObjectWithIssue) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.IssuesCountByObject", "ObjectWithIssue",
		ObjectWithIssue, Common.AllRefsTypeDetails());
	
	Query = New Query(
	"SELECT ALLOWED
	|	COUNT(*) AS Count
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	AccountingCheckResults.ObjectWithIssue = &ObjectWithIssue
	|	AND NOT AccountingCheckResults.IgnoreIssue");
	Query.SetParameter("ObjectWithIssue", ObjectWithIssue);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Select();
	Return ?(Result.Next(), Result.Count, 0); 
	
EndFunction

// Calculates the number of problems identified by the passed validation rule.
//
// Parameters:
//   CheckRule - CatalogRef.AccountingCheckRules -  the rule for which
//                     you need to calculate the number of problems.
//
// Returns:
//   Number
//
Function IssuesCountByCheckRule(CheckRule) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.IssuesCountByCheckRule", "CheckRule",
		CheckRule, Type("CatalogRef.AccountingCheckRules"));
	
	Query = New Query(
		"SELECT ALLOWED
		|	COUNT(*) AS Count
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckRule = &CheckRule
		|	AND NOT AccountingCheckResults.IgnoreIssue");
	Query.SetParameter("CheckRule", CheckRule);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Select();
	If Result.Next() Then
		IssuesCount = Result.Count;
	Else
		IssuesCount = 0;
	EndIf;
	
	Return IssuesCount;
	
EndFunction

// Generates the parameters of the verification execution to be passed to the procedures and functions to perform the verification, the description of the problem,
// View checks and others.
// The parameters contain a clarification of what exactly needs to be checked,
// for example, to check the closing of the month for a specific company for a specific period.
// The order of the parameters is taken into account.
//
// Parameters:
//     Parameter1     - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//     Parameter2     - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//     Parameter3     - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//     Parameter4     - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//     Parameter5     - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//     AnotherParameters - Array -  other validation parameters (elements of the types Any link, Boolean, Number, String, Date).
//
// Returns:
//    Structure:
//       * Description - String -  representation of the type of verification. 
//       * Property1 - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//       * Property2 - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//       * Property3 - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//                                                     
//       *  - AnyRef
//                   - Boolean
//                   - Number
//                   - String
//                   - Date - 
//
// Example:
//     1. Parameters = Parameters of the verification execution ("System checks");
//     2. Parameters = The parameter of the completion of the check ("Closing the month", company link, closing the month);
//
Function CheckExecutionParameters(Val Parameter1, Val Parameter2 = Undefined, Val Parameter3 = Undefined,
	Val Parameter4 = Undefined, Val Parameter5 = Undefined, Val AnotherParameters = Undefined) Export
	
	Return AccountingAuditInternal.CheckExecutionParameters(Parameter1, Parameter2, Parameter3, Parameter4, Parameter5, AnotherParameters);
	
EndFunction

// Clears the results of previous checks, leaving only those problems that were ignored earlier
// (the Ignore Problem flag = True).
// For nonparametric checks, the previous results are cleared automatically, and then the verification algorithm is executed.
// For checks with parameters, pre-cleaning of previous results should be performed explicitly using
// this procedure in the verification algorithm itself. Otherwise, the same problem will be registered 
// repeatedly with several consecutive runs of the check.
//
// Parameters:
//     Validation                    - CatalogRef.AccountingCheckRules -  a check whose
//                                   results need to be cleared.
//     CheckExecutionParameters - See AccountingAudit.CheckExecutionParameters
//                                 - Array - several validation parameters (array elements of the Structure type,
//                                               as described above).
//
Procedure ClearPreviousCheckResults(Val Validation, Val CheckExecutionParameters) Export
	
	CommonClientServer.CheckParameter("AccountingAudit.ClearPreviousCheckResults", "Validation",
		Validation, Type("CatalogRef.AccountingCheckRules"));
	CheckCheckExecutionParameters(CheckExecutionParameters, "AccountingAudit.ClearPreviousCheckResults");
	
	AccountingAuditInternal.ClearPreviousCheckResults(Validation, CheckExecutionParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Generates a description of the problem for subsequent registration
// using the Accounting control procedure.Write the problem in the validation handler procedure.
//
// Parameters:
//   ObjectWithIssue  - AnyRef -  the object that the identified problem is associated with.
//   CheckParameters - Structure -  
//                                   :
//     * Validation         - CatalogRef.AccountingCheckRules -  completed verification.
//     * CheckKind      - CatalogRef.ChecksKinds - 
//     * IssueSeverity   - EnumRef.AccountingIssueSeverity - 
//                            :
//                            
//     * Id      - String -  the string ID of the check.
//     * CheckStartDate - Date -  threshold date indicating the boundary of the objects to be checked
//                            (only for objects with a date). Objects whose date is less than 
//                            however, it should not be checked. By default, it is not filled in (i.e. check everything).
//     * IssuesLimit       - Number -  the number of objects to be checked.
//                            By default, 1000. If 0 is specified, then all objects should be checked.
//     * CheckKind        - CatalogRef.ChecksKinds -  a reference to the type of check
//                            that the performed check belongs to.
//
// Returns:
//   Structure:
//     * ObjectWithIssue         - AnyRef - 
//     * Validation                 - CatalogRef.AccountingCheckRules -  a link to the completed check.
//                                  Taken from the passed structure of the verification parameters.
//     * CheckKind              - CatalogRef.ChecksKinds -  a reference to the type of check that
//                                  the performed check belongs to. Taken from the passed structure of the verification parameterreferences
//     * IssueSeverity         - CatalogRef.ChecksKinds -  a reference to the type of check that
//                                  the performed check belongs to. Taken from the passed structure of the verification parameters.
//     * IssueSummary        - String -  the problem clarification string. By default, it is not filled in.
//     * UniqueKey         - UUID -  the key to the uniqueness of the problem.
//     * Detected                 - Date -  the moment the problem was detected.
//     * AdditionalInformation - ValueStorage
//                                - Undefined - 
//                                  
//     * EmployeeResponsible            - CatalogRef.Users
//                                - Undefined -  
//                                  
//
// Example:
//  Problem = Accounting control.Description of the problem(problem document, verification parameters);
//  Problem.View Checks = View Checks;
//  Problem.Clarification of the problem = stringfunctionclientserver.Substitute the parameter string(
//    NStr("ru = 'For the counterparty ""%1"" there is an unverified document ""%2""'"), The result.Counterparty, 
//      Problematic Document);
//  Accounting control.Write down the problem(Problem, Check parameters);
//
Function IssueDetails(ObjectWithIssue, CheckParameters) Export
	
	ProcedureName = "AccountingAudit.IssueDetails";
	CommonClientServer.CheckParameter(ProcedureName, "ObjectWithIssue", ObjectWithIssue, 
		Common.AllRefsTypeDetails());
	CommonClientServer.CheckParameter(ProcedureName, "CheckParameters", CheckParameters, Type("Structure"), 
		AccountingAuditInternal.CheckParametersPropertiesExpectedTypes());
		
	Return AccountingAuditInternal.IssueDetails(ObjectWithIssue, CheckParameters);
	
EndFunction

// Records the result of the check.
//
// Parameters:
//   Issue1          - See AccountingAudit.IssueDetails.
//   CheckParameters - See AccountingAudit.IssueDetails.CheckParameters.
//
Procedure WriteIssue(Issue1, CheckParameters = Undefined) Export
	
	ProcedureName = "AccountingAudit.WriteIssue";
	CommonClientServer.CheckParameter(ProcedureName, "Issue1", Issue1, Type("Structure"), 
		AccountingAuditInternal.IssueDetailsPropertiesTypesToExpect());
	If CheckParameters <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "CheckParameters", CheckParameters, Type("Structure"), 
			AccountingAuditInternal.CheckParametersPropertiesExpectedTypes());
	EndIf;
	
	AccountingAuditInternal.WriteIssue(Issue1, CheckParameters);
	
EndProcedure

// Sets or removes the sign of ignoring the accounting problem. 
// When the Ignore parameter is set to True, the problem ceases to be displayed to users in the object forms 
// and the report on the results of checks. For example, this is useful if the user has decided that 
// the detected problem is not significant or it is not planned to deal with it.
// When reset to False, the problem becomes relevant again.
//
// Parameters:
//   IssueDetails             - Structure:
//     * ObjectWithIssue         - AnyRef -  a reference to the object that the problem is related to.
//     * CheckRule          - CatalogRef.AccountingCheckRules -  a completed check with a description of the problem.
//     * ChecksKind              - CatalogRef.ChecksKinds -  type of check.
//     * IssueSummary        - String -  text clarification of the found problem.
//     * AdditionalInformation - ValueStorage -  additional information about the ignored problem.
//   Ignore - Boolean -  the set value for the specified problem.
//
Procedure IgnoreIssue(Val IssueDetails, Val Ignore) Export
	
	ProcedureName = "AccountingAudit.IgnoreIssue";
	CommonClientServer.CheckParameter(ProcedureName, "Ignore", Ignore, Type("Boolean"));
	CommonClientServer.CheckParameter(ProcedureName, "IssueDetails", IssueDetails, Type("Structure"), 
		AccountingAuditInternal.IssueDetailsPropertiesTypesToExpect(False));
	
	AccountingAuditInternal.IgnoreIssue(IssueDetails, Ignore);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// In the form of a list, it displays a column with a picture signaling the presence of problems with objects in the rows. 
// It is called from the event of the list form server connection.
// Dynamic lists must have a primary table defined. 
//
// Parameters:
//   Form                  - ClientApplicationForm -  list form.
//   ListsNames           - String -  names of dynamic lists separated by commas.
//   AdditionalProperties - Structure
//                          - Undefined - :
//      * ProblemIndicatorFieldID - String -  the name of the dynamic list field that
//                            will be used to display an indicator
//                            of the presence of problems with the object.
//
Procedure OnCreateListFormAtServer(Form, ListsNames, AdditionalProperties = Undefined) Export
	
	ProcedureName = "AccountingAudit.OnCreateListFormAtServer";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ClientApplicationForm"));
	CommonClientServer.CheckParameter(ProcedureName, "ListsNames", ListsNames, Type("String"));
	ProblemIndicatorFieldID = Undefined;
	If AdditionalProperties <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "AdditionalProperties", AdditionalProperties, Type("Structure"));
		AdditionalProperties.Property("ProblemIndicatorFieldID", ProblemIndicatorFieldID);
	EndIf;
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	GlobalSettings = AccountingAuditInternal.GlobalSettings();
	NamesList          = StrSplit(ListsNames, ",");
	ValuesPicture    = PictureLib.AccountingIssuesSeverityCollection;
	
	For Each ListName In NamesList Do
		FormTable = Form.Items.Find(TrimAll(ListName));
		If FormTable = Undefined Then
			Continue;
		EndIf;
			
		CurrentList   = Form[FormTable.DataPath];
		MainTable = CurrentList.MainTable;
		If Not ValueIsFilled(MainTable) Then
			Continue;
		EndIf;
			
		QueryText = "";
		If CurrentList.CustomQuery Then
			QueryText = CurrentList.QueryText;
		Else
			SchemaToPerform               = FormTable.GetPerformingDataCompositionScheme();
			DynamicListDataSet = SchemaToPerform.DataSets.Find("DynamicListDataSet"); // DataCompositionSchemaDataSetQuery
			If DynamicListDataSet <> Undefined Then
				CurrentList.CustomQuery = True;
				QueryText = DynamicListDataSet.Query;
			EndIf;
		EndIf;
		
		If Not ValueIsFilled(QueryText) Or Not StrStartsWith(QueryText, "SELECT") Then // @query-part-1
			Continue;
		EndIf;
			
		If ProblemIndicatorFieldID = Undefined Then
			ColumnName = "ErrorIndicator_" + Common.CheckSumString(Form.FormName + GetPathSeparator() + ListName);
		Else
			ColumnName = ProblemIndicatorFieldID;
		EndIf;
		
		SeparatedName = StrSplit(MainTable, ".");
		
		ComposerAdditionalProperties = CurrentList.SettingsComposer.Settings.AdditionalProperties;
		ComposerAdditionalProperties.Insert("IndicatorColumn",    ColumnName);
		ComposerAdditionalProperties.Insert("MetadataObjectKind", SeparatedName.Get(0));
		ComposerAdditionalProperties.Insert("MetadataObjectName", SeparatedName.Get(1));
		ComposerAdditionalProperties.Insert("ListName",            ListName);
		
		If ProblemIndicatorFieldID = Undefined Then
			DynamicListPropertiesStructure = Common.DynamicListPropertiesStructure();
			FieldToAdd = "	0 AS " + ColumnName + ",";
			QueryAsArray = StrSplit(QueryText, Chars.LF);
			InsertionPosition = Undefined;
			If StrOccurrenceCount(QueryText, "SELECT") > 1 Then // @query-part-1
				IndexOf = 0;
				For Each QueryString In QueryAsArray Do
					If StrStartsWith(TrimAll(QueryString), "SELECT") Then // @query-part-1
						If InsertionPosition = Undefined Then
							InsertionPosition = IndexOf + 1;
						Else
							Break;
						EndIf;
					ElsIf StrStartsWith(TrimAll(QueryString), "INTO") Then
						InsertionPosition = Undefined;
					EndIf;
					IndexOf = IndexOf + 1;
				EndDo;
			Else
				InsertionPosition = 1;
			EndIf;
			QueryAsArray.Insert(InsertionPosition, FieldToAdd);
			DynamicListPropertiesStructure.QueryText = StrConcat(QueryAsArray, Chars.LF);
			Common.SetDynamicListProperties(FormTable, DynamicListPropertiesStructure);
		EndIf;
		
		IndicationColumnParameters = New Structure;
		
		AccountingAuditInternal.OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, MainTable);
		AccountingAuditOverridable.OnDetermineIndicatiomColumnParameters(IndicationColumnParameters, MainTable);
		
		ErrorIndicatorColumn = Form.Items.Add(ColumnName, Type("FormField"), FormTable);
		ErrorIndicatorColumn.Type                = FormFieldType.PictureField;
		ErrorIndicatorColumn.DataPath        = StringFunctionsClientServer.SubstituteParametersToString("%1.%2", ListName, ColumnName);
		ErrorIndicatorColumn.TitleLocation = IndicationColumnParameters.TitleLocation;
		ErrorIndicatorColumn.HeaderPicture      = GlobalSettings.IssuesIndicatorPicture;
		ErrorIndicatorColumn.ValuesPicture   = ValuesPicture;
		ErrorIndicatorColumn.Title          = NStr("en = 'Error indicator';");
		
		ListColumns = FormTable.ChildItems;
		If ListColumns.Count() > 0 Then
			If IndicationColumnParameters.OutputLast Then
				Form.Items.Move(ErrorIndicatorColumn, FormTable);
			Else
				Form.Items.Move(ErrorIndicatorColumn, FormTable, ListColumns.Get(0));
			EndIf;
		EndIf;
		
		CurrentAction1 = FormTable.GetAction("Selection");
		If Not ValueIsFilled(CurrentAction1) Then
			FormTable.SetAction("Selection", "Attachable_Selection");
		EndIf;
		
	EndDo;
	
EndProcedure

// In the form of a list, it displays a column with a picture signaling the presence of problems with objects in the rows. 
// Called from the event of receiving the specified list form server.
//
// Parameters:
//   Settings              - DataCompositionSettings -  contains a copy of the full dynamic list settings.
//   Rows                 - DynamicListRows -  the collection contains the data and formatting of all the rows
//                            received in the list, except for the grouping rows.
//   KeyFieldName       - String -  "Link" or the specified name of the column containing the object reference.
//   AdditionalProperties - Structure
//                          - Undefined - 
//                            
//
Procedure OnGetDataAtServer(Settings, Rows, KeyFieldName = "Ref", AdditionalProperties = Undefined) Export
	
	ProcedureName = "AccountingAudit.OnGetDataAtServer";
	CommonClientServer.CheckParameter(ProcedureName, "Settings", Settings, Type("DataCompositionSettings"));
	CommonClientServer.CheckParameter(ProcedureName, "Rows", Rows, Type("DynamicListRows"));
	CommonClientServer.CheckParameter(ProcedureName, "KeyFieldName", KeyFieldName, Type("String"));
	If AdditionalProperties <> Undefined Then
		CommonClientServer.CheckParameter(ProcedureName, "AdditionalProperties", AdditionalProperties, Type("Structure"));
	EndIf;
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	ComposerAdditionalProperties = Settings.AdditionalProperties;
	If ComposerAdditionalProperties.Property("IndicatorColumn") Then
		
		IndicatorColumn = Settings.AdditionalProperties.IndicatorColumn;
		
		If KeyFieldName = "Ref" Then
			RowsKeys = Rows.GetKeys();
			KeyRef = True;
		Else
			StartKeys = Rows.GetKeys();
			KeyRef     = Common.IsReference(Type(StartKeys[0]));
			RowsKeys     = New Array;
			For Each StartKey In StartKeys Do
				RowsKeys.Add(StartKey[KeyFieldName]);
			EndDo;
		EndIf;
		
		ObjectsWithIssues = AccountingAuditInternal.ObjectsWithIssues(RowsKeys, True);
		
		For Each Composite In RowsKeys Do
			
			If KeyRef Then
				AccountingAuditInternal.FillPictureIndex(Rows, Rows[Composite], Composite, IndicatorColumn, ObjectsWithIssues);
			Else
				For Each ListLine In Rows Do
					If ListLine.Key[KeyFieldName] = Composite Then
						AccountingAuditInternal.FillPictureIndex(Rows, ListLine.Value, Composite, IndicatorColumn, ObjectsWithIssues);
					EndIf;
				EndDo;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// In the form of an object, it displays a group with a picture and an inscription signaling the presence of problems with this object. 
// Called from the event belonging to the server of the object form.
//
// Parameters:
//   Form         - ClientApplicationForm -  object form.
//   CurrentObject - DocumentObject -  the object to be read.
//                 - CatalogObject
//                 - ExchangePlanObject
//                 - ChartOfCharacteristicTypesObject
//                 - ChartOfAccountsObject
//                 - ChartOfCalculationTypesObject
//                 - TaskObject
//
Procedure OnReadAtServer(Form, CurrentObject) Export
	
	ProcedureName = "AccountingAudit.OnReadAtServer";
	CommonClientServer.CheckParameter(ProcedureName, "Form", Form, Type("ClientApplicationForm"));
	CommonClientServer.CheckParameter(ProcedureName, "CurrentObject", CurrentObject, 
		AccountingAuditInternalCached.TypeDetailsAllObjects());
	
	If Not SubsystemAvailable() Then
		Return;
	EndIf;
	
	Settings = AccountingAuditInternal.GlobalSettings();
	Settings.Insert("IssuesCount", 0);
	Settings.Insert("IssueText", "");
	Settings.Insert("IssueSeverity", Undefined);
	Settings.Insert("LastCheckDate", Undefined);
	Settings.Insert("DetailedKind", False);
	
	ObjectReference             = CurrentObject.Ref;
	ManagedFormItems   = Form.Items;
	Settings.IssuesCount = IssuesCountByObject(ObjectReference);
	NamesUniqueKey       = Common.CheckSumString(ObjectReference.Metadata().FullName()
		+ GetPathSeparator() + Form.FormName);
		
	GroupDecoration = ManagedFormItems.Find("ErrorIndicatorGroup_" + NamesUniqueKey);
	
	IndicationGroupParameters = New Structure;
	AccountingAuditInternal.OnDetermineIndicationGroupParameters(IndicationGroupParameters, TypeOf(ObjectReference));
	AccountingAuditOverridable.OnDetermineIndicationGroupParameters(IndicationGroupParameters, TypeOf(ObjectReference));
	
	If Settings.IssuesCount = 0 Then
		If GroupDecoration <> Undefined Then
			ManagedFormItems.Delete(GroupDecoration);
		EndIf;
		Return;
	EndIf;
	Settings.DetailedKind = IndicationGroupParameters.DetailedKind And Settings.IssuesCount = 1;
	If Settings.DetailedKind Then
		FillPropertyValues(Settings, AccountingAuditInternal.ObjectIssueInfo(ObjectReference));
	EndIf;
	
	Settings.LastCheckDate = AccountingAuditInternal.LastObjectCheck(ObjectReference);
	If GroupDecoration <> Undefined Then
		
		LabelDecoration = ManagedFormItems.Find("LabelDecoration_" + NamesUniqueKey);
		If LabelDecoration <> Undefined Then
			LabelDecoration.Title = AccountingAuditInternal.GenerateCommonStringIndicator(Form, ObjectReference, Settings);
		EndIf;
		
	Else
		
		ErrorIndicatorGroup = AccountingAuditInternal.PlaceErrorIndicatorGroup(Form, NamesUniqueKey,
			IndicationGroupParameters.GroupParentName, IndicationGroupParameters.OutputAtBottom);
		
		MainRowIndicator = AccountingAuditInternal.GenerateCommonStringIndicator(Form, ObjectReference, Settings);
		
		AccountingAuditInternal.FillErrorIndicatorGroup(Form, ErrorIndicatorGroup, NamesUniqueKey,
			MainRowIndicator, Settings);
		
	EndIf;
	
EndProcedure

// Starts a background check of the passed object.
// Only those checks are performed for which errors were previously found and for which
// the property Supports Selective verification is set to True.
// 
// Parameters:
//   CurrentObject - DocumentObject -  <Data Object View>An object.<Metadata objectName>.
//                 - CatalogObject
//                 - ExchangePlanObject
//                 - ChartOfCharacteristicTypesObject
//                 - ChartOfAccountsObject
//                 - ChartOfCalculationTypesObject
//                 - TaskObject
//
Procedure AfterWriteAtServer(CurrentObject) Export
	Query = New Query;
	Query.Text =
		"SELECT DISTINCT
		|	AccountingCheckResults.CheckRule AS CheckRule
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.ObjectWithIssue = &ObjectWithIssue";
	Query.SetParameter("ObjectWithIssue", CurrentObject.Ref);
	
	SetPrivilegedMode(True);
	Result = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Checks = Result.UnloadColumn("CheckRule");
	If Checks.Count() = 0 Then
		Return;
	EndIf;
	
	TimeConsumingOperations.ExecuteProcedure(, "AccountingAuditInternal.CheckObject", CurrentObject.Ref, Checks);
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Returns True if there are rights to view accounting issues.
//
// Returns:
//   Boolean
//
Function SubsystemAvailable() Export
	
	Return AccountingAuditInternal.SubsystemAvailable();
	
EndFunction

// Returns the types of validation based on the passed parameters.
//
// Parameters:
//   ChecksKind                - String
//                              - Array of String 
//                              - CatalogRef.ChecksKinds - 
//                                
//   SearchByExactMap - Boolean -  adjusts accuracy capabilities. If True, then the search is
//                                based on the passed properties for equality, the remaining properties must be equal
//                                Undefined (the tabular part of the additional properties should be empty).
//                                If False, then the values of the other properties can be arbitrary, the main
//                                thing is that the corresponding properties are equal to the properties of the structure. By default, True.
//
// Returns:
//   Array -  
//            
//
Function ChecksKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.ChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	Return AccountingAuditInternal.ChecksKinds(ChecksKind, SearchByExactMap);
	
EndFunction

// Returns an existing or creates a new element of the reference list of types of checks 
// for registration or selection of accounting results.
//
// Parameters:
//     CheckExecutionParameters - String -  string identifier of the type of check (Property 1)
//                                 - Structure - 
//     SearchOnly - Boolean -  if True and the type of check with the specified parameters does not exist, 
//                   an empty link is returned; if False, an element is created and a link to it is returned.
//
// Returns:
//   CatalogRef.ChecksKinds - 
//       
//      
//
// Example:
//   Type of verification = Control of accounting.Type of checks ("System checks");
//
Function CheckKind(Val CheckExecutionParameters, Val SearchOnly = False) Export
	
	AllowedTypes = New Array;
	AllowedTypes.Add(Type("String"));
	AllowedTypes.Add(Type("Structure"));
	CommonClientServer.CheckParameter("AccountingAudit.CheckKind",
		"CheckExecutionParameters", CheckExecutionParameters, AllowedTypes);
	If TypeOf(CheckExecutionParameters) = Type("Structure") Then
		CheckCheckExecutionParameter(CheckExecutionParameters, "AccountingAudit.CheckKind");
	EndIf;
	CommonClientServer.CheckParameter("AccountingAudit.CheckKind", "SearchOnly", SearchOnly, Type("Boolean"));
	
	Return AccountingAuditInternal.CheckKind(CheckExecutionParameters, SearchOnly);
	
EndFunction

// Forcibly updates the composition of accounting checks when metadata
// or other settings are changed.
//
Procedure UpdateAccountingChecksParameters() Export
	
	If Not Common.DataSeparationEnabled() Then
		AccountingAuditInternal.UpdateAccountingChecksParameters();
	EndIf;
	
	If AccountingAuditInternal.HasChangesOfAccountingChecksParameters() Then
		AccountingAuditInternal.UpdateAuxiliaryRegisterDataByConfigurationChanges();
	EndIf;
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds -  link to the type of check.
//                              - String - 
//                              - Array of String - 
//   SearchByExactMap - Boolean -  adjusts accuracy capabilities. If True, then the search is
//                                based on the passed properties for equality, the remaining properties must be equal
//                                Undefined (the tabular part of the additional properties should be empty).
//                                If False, then the values of the other properties can be arbitrary, the main
//                                thing is that the corresponding properties are equal to the properties of the structure. By default, True.
//
// Returns:
//   ValueTable:
//     * ObjectWithIssue         - AnyRef -  a reference to the "Source" object of the problems.
//     * CheckRule          - CatalogRef.AccountingCheckRules -  a link to the completed check.
//     * IssueSummary        - String -  string-clarification of the found problem.
//     * IssueSeverity         - EnumRef.AccountingIssueSeverity -  The importance of the accounting problem
//                                  is "Information", "Warning", "Error" and "Useful Advice".
//     * EmployeeResponsible            - CatalogRef.Users -  filled in if it is possible
//                                  to identify the responsible person in the problem object.
//     * AdditionalInformation - ValueStorage -  a service property with additional
//                                  information related to the identified problem.
//     * Detected                 - Date -  server identification time of the problem.
//
// Example:
//   1) Result = Detailed informationspecifications ("System Checks");
//   2) Type Check = New Array;
//      View check.Add("Closing the month");
//      View check.Add(Company);
//      View check.Add(months of closure);
//      Result = Detailed Informationview Check(View Check);
//
Function DetailedInformationOnCheckKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.DetailedInformationOnChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	DetailedInformation = New ValueTable;
	ChecksKindsArray = New Array;
	
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKindsArray.Add(ChecksKind);
	Else
		ChecksKindsArray = AccountingAuditInternal.ChecksKinds(ChecksKind, SearchByExactMap);
	EndIf;
	
	If ChecksKindsArray.Count() = 0 Then
		Return DetailedInformation;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
	|	AccountingCheckResults.IssueSeverity AS IssueSeverity,
	|	AccountingCheckResults.CheckRule AS CheckRule,
	|	AccountingCheckResults.CheckKind AS CheckKind
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckKind IN (&ChecksKindsArray)");
	
	Query.SetParameter("ChecksKindsArray", ChecksKindsArray);
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		DetailedInformation = Result.Unload();
	EndIf;
	
	Return DetailedInformation;
	
EndFunction

// Deprecated.
// 
//
// Parameters:
//   ChecksKind                - CatalogRef.ChecksKinds -  link to the type of check.
//                              - String - 
//                              - Array of String - 
//   SearchByExactMap - Boolean -  adjusts accuracy capabilities. If True, then the search is
//                                based on the passed properties for equality, the remaining properties must be equal
//                                Undefined (the tabular part of the additional properties should be empty).
//                                If False, then the values of the other properties can be arbitrary, the main
//                                thing is that the corresponding properties are equal to the properties of the structure. By default, True.
//
// Returns:
//  Structure:
//    * Count - Number -  the total number of problems found.
//    * HasErrors - Boolean -  a sign of whether there are errors among the problems found (with the importance "Error").
//
// Example:
//   1) Result = Summary of informationspecifications ("System checks");
//   2) Type Check = New Array;
//      View check.Add("Closing the month");
//      View check.Add(Company);
//      View check.Add(months of closure);
//      Result = Summary Informationview Check(View Check);
//
Function SummaryInformationOnCheckKinds(ChecksKind, SearchByExactMap = True) Export
	
	ProcedureName = "AccountingAudit.SummaryInformationOnChecksKinds";
	CommonClientServer.CheckParameter(ProcedureName, "ChecksKind", ChecksKind, AccountingAuditInternal.TypeDetailsCheckKind());
	CommonClientServer.CheckParameter(ProcedureName, "SearchByExactMap", SearchByExactMap, Type("Boolean"));
	
	SummaryInformation = New Structure;
	SummaryInformation.Insert("Count", 0);
	SummaryInformation.Insert("HasErrors", False);
	
	ChecksKindsArray = New Array;
	If TypeOf(ChecksKind) = Type("CatalogRef.ChecksKinds") Then
		ChecksKindsArray.Add(ChecksKind);
	Else
		ChecksKindsArray = AccountingAuditInternal.ChecksKinds(ChecksKind, SearchByExactMap);
		If ChecksKindsArray.Count() = 0 Then
			Return SummaryInformation;
		EndIf;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	COUNT(*) AS Count,
	|	ISNULL(MAX(CASE
	|				WHEN AccountingCheckResults.IssueSeverity = VALUE(Enum.AccountingIssueSeverity.Error)
	|					THEN TRUE
	|				ELSE FALSE
	|			END), FALSE) AS HasErrors
	|FROM
	|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
	|WHERE
	|	NOT AccountingCheckResults.IgnoreIssue
	|	AND AccountingCheckResults.CheckKind IN (&ChecksKindsArray)");
	
	Query.SetParameter("ChecksKindsArray", ChecksKindsArray);
	Result = Query.Execute().Select();
	Result.Next();
	
	FillPropertyValues(SummaryInformation, Result);
	
	Return SummaryInformation;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

Function ObjectsWithIssues(CheckRule, Offset = Undefined, Batch = 1000) Export
	
	Query = New Query;
	QueryText = "SELECT TOP 1000
		|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
		|	AccountingCheckResults.CheckRule AS CheckRule,
		|	AccountingCheckResults.CheckKind AS CheckKind,
		|	AccountingCheckResults.UniqueKey AS UniqueKey
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckRule = &CheckRule
		|	AND NOT AccountingCheckResults.IgnoreIssue
		|	AND AccountingCheckResults.ObjectWithIssue > &ObjectWithIssue
		|
		|ORDER BY
		|	AccountingCheckResults.ObjectWithIssue";
	
	If Batch = 1000 Then
		QueryText = StrReplace(QueryText, "1000", Format(Batch, "NG=0"));
	EndIf;
	Query.Text = QueryText;
	
	If Offset = Undefined Then
		Offset = "";
	EndIf;
	
	Query.SetParameter("CheckRule",  CheckRule);
	Query.SetParameter("ObjectWithIssue", Offset);
	
	Return Query.Execute().Unload();
	
EndFunction

Function ObjectsWithIssuesByCheckKind(CheckKind, Offset = Undefined, Batch = 1000) Export
	
	Query = New Query;
	QueryText = "SELECT TOP 1000
		|	AccountingCheckResults.ObjectWithIssue AS ObjectWithIssue,
		|	AccountingCheckResults.CheckRule AS CheckRule,
		|	AccountingCheckResults.CheckKind AS CheckKind,
		|	AccountingCheckResults.UniqueKey AS UniqueKey
		|FROM
		|	InformationRegister.AccountingCheckResults AS AccountingCheckResults
		|WHERE
		|	AccountingCheckResults.CheckKind = &CheckKind
		|	AND NOT AccountingCheckResults.IgnoreIssue
		|	AND AccountingCheckResults.ObjectWithIssue > &ObjectWithIssue
		|
		|ORDER BY
		|	AccountingCheckResults.ObjectWithIssue";
	
	If Batch = 1000 Then
		QueryText = StrReplace(QueryText, "1000", Format(Batch, "NG=0"));
	EndIf;
	Query.Text = QueryText;
	
	If Offset = Undefined Then
		Offset = "";
	EndIf;
	
	Query.SetParameter("CheckKind",      CheckKind);
	Query.SetParameter("ObjectWithIssue", Offset);
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure ClearResultByCheckKind(ObjectWithIssue, CheckKind) Export
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("InformationRegister.AccountingCheckResults");
	DataLockItem.SetValue("ObjectWithIssue", ObjectWithIssue);
	DataLockItem.SetValue("CheckKind",      CheckKind);
	
	BeginTransaction();
	
	Try
		
		DataLock.Lock();
		
		Set = InformationRegisters.AccountingCheckResults.CreateRecordSet();
		Set.Filter.ObjectWithIssue.Set(ObjectWithIssue);
		Set.Filter.CheckKind.Set(CheckKind);
		Set.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure ClearCheckResult(ObjectWithIssue, CheckRule) Export
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		DataLockItem = DataLock.Add("InformationRegister.AccountingCheckResults");
		DataLockItem.SetValue("ObjectWithIssue", ObjectWithIssue);
		DataLockItem.SetValue("CheckRule", CheckRule);
		DataLock.Lock();
		
		Set = InformationRegisters.AccountingCheckResults.CreateRecordSet();
		Set.Filter.ObjectWithIssue.Set(ObjectWithIssue);
		Set.Filter.CheckRule.Set(CheckRule);
		Set.Clear();
		Set.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

Procedure ClearResultOnCheck(Validation) Export
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("InformationRegister.AccountingCheckResults");
	DataLockItem.SetValue("CheckRule", Validation);
	
	BeginTransaction();
	
	Try
		DataLock.Lock();
		
		Set = InformationRegisters.AccountingCheckResults.CreateRecordSet();
		Set.Filter.CheckRule.Set(Validation);
		Set.Filter.IgnoreIssue.Set(False);
		Set.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(EventLogEvent(), EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckCheckExecutionParameters(CheckExecutionParameters, NameOfAProcedureOrAFunction)
	
	If TypeOf(CheckExecutionParameters) = Type("Structure") Then
		ExecutionParameters = New Array;
		ExecutionParameters.Add(CheckExecutionParameters);
		CheckExecutionParameters = ExecutionParameters;
	EndIf;
	
	CommonClientServer.CheckParameter(NameOfAProcedureOrAFunction, "CheckExecutionParameters",
		CheckExecutionParameters, Type("Array"));
	
	For Each CheckParameter1 In CheckExecutionParameters Do
		CheckCheckExecutionParameter(CheckParameter1, NameOfAProcedureOrAFunction);
	EndDo;

EndProcedure

Procedure CheckCheckExecutionParameter(CheckParameter1, NameOfAProcedureOrAFunction)
	
	CommonClientServer.CheckParameter(NameOfAProcedureOrAFunction, "CheckExecutionParameters.Item",
		CheckParameter1, Type("Structure"));
	For Each CurrentParameter In CheckParameter1 Do
		CommonClientServer.CheckParameter(NameOfAProcedureOrAFunction,
		CurrentParameter.Key, CurrentParameter.Value, AccountingAuditInternal.ExpectedPropertiesTypesOfChecksKinds());
	EndDo;

EndProcedure

Function EventLogEvent()
	
	Return NStr("en = 'Data integrity';", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion


