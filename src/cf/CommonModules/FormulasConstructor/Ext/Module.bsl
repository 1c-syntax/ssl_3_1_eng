///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Creates a hierarchical list on the form with the specified composition of fields and the search string.
// One or more collections of available data layout fields are used as a field source.
// For fields of the reference type, it is possible to expand to an unlimited number of levels.
// For any field in the list, including fields of simple types, it is possible to supplement and redefine
// the list of child fields.
// 
// Parameters:
//  Form - ClientApplicationForm -  the form in which you want to add a list.
//  Parameters - See ParametersForAddingAListOfFields
//
Procedure AddAListOfFieldsToTheForm(Form, Parameters) Export
	
	FormulasConstructorInternal.AddAListOfFieldsToTheForm(Form, Parameters);
	
EndProcedure

// The constructor of the parameter Parameters of the procedure add a list to the form field.
// 
// Returns:
//  Structure:
//   * LocationOfTheList - FormGroup
//                           - FormTable
//                           - ClientApplicationForm
//   * UseBackgroundSearch - Boolean
//   * NumberOfCharsToAllowSearching - Number   
//   * ListName - String
//   * FieldsCollections - Array of DataCompositionAvailableFields
//   * LocationOfTheSearchString - FormGroup
//                                 - FormTable
//                                 - ClientApplicationForm
//   * HintForEnteringTheSearchString - String
//   * ListHandlers - Structure
//   * IncludeGroupsInTheDataPath - Boolean
//   * IdentifierBrackets - Boolean
//   * ViewBrackets - Boolean
//   * SourcesOfAvailableFields - ValueTable - 
//                                                 :
//     ** DataSource - String -  description of the field in the field tree, can be in the form of a path in the tree, or in the form
//                                  of the name of the metadata object.
//                                  The source can be specified as a template in which the "*" symbol denotes several
//                                  arbitrary characters.
//                                  For example,
//                                  "*.Name" - add a collection of child fields to the fields "Name",
//                                  "Directory.Companies" - add a collection of child fields to all fields
//                                  of the Company type.
//     ** FieldsCollection - DataCompositionAvailableFields -  child fields of the data source.
//     ** Replace       - Boolean -  if True, the list of subordinate fields will be replaced, if False, it will be supplemented.
//   * UseIdentifiersForFormulas - Boolean
//   * PrimarySourceName - String - 
//
Function ParametersForAddingAListOfFields() Export
	
	Return FormulasConstructorInternal.ParametersForAddingAListOfFields();
	
EndFunction

// Constructor of the list of fields for the procedure Add a list of fields to the form.
//
// Returns:
//  ValueTable:
//   * Id - String
//   * Presentation - String
//   * ValueType   - TypeDescription
//   * Picture   - String
//   * Order       - Number
//
Function FieldTable() Export
	
	Return FormulasConstructorInternal.FieldTable();
	
EndFunction

// Constructor of the list of fields for the procedure Add a list of fields to the form.
//
// Returns:
//  ValueTree:
//   * Id - String
//   * Presentation - String
//   * ValueType   - TypeDescription
//   * IconName   - String
//   * Order       - Number
//
Function FieldTree() Export
	
	Return FormulasConstructorInternal.FieldTree();
	
EndFunction

// Constructor of the list of fields for the procedure Add a list of fields to the form.
// Converts the original collection of fields into a collection of available data layout fields.
// 
// Parameters:
//   FieldSource   - See FieldTable
//                    See FieldTree
//                   
//                                             
//                                             
//                   
//   NameOfTheSKDCollection - String -  the name of the collection of fields in the settings builder. The parameter must be used if the
//                              data layout scheme is passed in the Field Source parameter.
//                              The default value is available selection fields. 
//   
//  Returns:
//   DataCompositionAvailableFields
// 
Function FieldsCollection(FieldSource, Val NameOfTheSKDCollection = Undefined) Export
	
	Return FormulasConstructorInternal.FieldsCollection(FieldSource, , NameOfTheSKDCollection);
	
EndFunction

// It is used in case of changing the composition of the fields displayed in the connected list.
// Resets the specified list from the passed collection of fields.
//
// Parameters:
//  Form - ClientApplicationForm
//  FieldsCollections - Array of DataCompositionAvailableFields
//  NameOfTheFieldList - String -  the name of the list on the form in which the fields need to be updated.
//
Procedure UpdateFieldCollections(Form, FieldsCollections, NameOfTheFieldList = "AvailableFields") Export
	
	FormulasConstructorInternal.UpdateFieldCollections(Form, FieldsCollections, NameOfTheFieldList);
	
EndProcedure

// Handler for the event of expanding the connected list on the form.
//
// Parameters:
//  Form - ClientApplicationForm
//  FillParameters - Structure
//
Procedure FillInTheListOfAvailableFields(Form, FillParameters) Export
	
	FormulasConstructorInternal.FillInTheListOfAvailableFields(Form, FillParameters);
	
EndProcedure

// Event handler for changing the text of editing the search field of the connected list.
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure PerformASearchInTheListOfFields(Form) Export
	
	FormulasConstructorInternal.PerformASearchInTheListOfFields(Form);
	
EndProcedure

// 
// 
// Parameters:
//  Form - ClientApplicationForm
//  Parameter - Arbitrary
//  AdditionalParameters - See FormulasConstructorClient.HandlerParameters
//
Procedure FormulaEditorHandler(Form, Parameter, AdditionalParameters) Export
	FormulasConstructorInternal.FormulaEditorHandler(Form, Parameter, AdditionalParameters);
EndProcedure

// Prepares a standard list of operators of the required types.
// 
// Parameters:
//  GroupsOfOperators - String - :
//                   	
//                   
//                   
//                   
// 
// Returns:
//  ValueTree
//
Function ListOfOperators(GroupsOfOperators = Undefined) Export
	
	Return FormulasConstructorInternal.ListOfOperators(GroupsOfOperators);
	
EndFunction

// Generates a representation of the formula in the user's current language.
// Operands and operators in the formula text are replaced by their representations.
//
// Parameters:
//  FormulaParameters - See FormulaEditingOptions
//  
// Returns:
//  String
//
Function FormulaPresentation(FormulaParameters) Export
	
	If Not ValueIsFilled(FormulaParameters.Formula) Then
		Return FormulaParameters.Formula;
	EndIf;
	
	DescriptionOfFieldLists = FormulasConstructorInternal.DescriptionOfFieldLists();
	
	SourcesOfAvailableFields = FormulasConstructorInternal.CollectionOfSourcesOfAvailableFields();
	SourceOfAvailableFields = SourcesOfAvailableFields.Add(); 
	SourceOfAvailableFields.FieldsCollection = FormulasConstructorInternal.FieldsCollection(FormulaParameters.Operands);
	
	DescriptionOfTheFieldList = DescriptionOfFieldLists.Add();
	DescriptionOfTheFieldList.SourcesOfAvailableFields = SourcesOfAvailableFields;
	DescriptionOfTheFieldList.ViewBrackets = True;
	
	SourcesOfAvailableFields = FormulasConstructorInternal.CollectionOfSourcesOfAvailableFields();
	SourceOfAvailableFields = SourcesOfAvailableFields.Add(); 
	SourceOfAvailableFields.FieldsCollection = FormulasConstructorInternal.FieldsCollection(FormulaParameters.Operators);
	
	DescriptionOfTheFieldList = DescriptionOfFieldLists.Add();
	DescriptionOfTheFieldList.SourcesOfAvailableFields = SourcesOfAvailableFields;
	
	Return FormulasConstructorInternal.RepresentationOfTheExpression(FormulaParameters.Formula, DescriptionOfFieldLists);
	
EndFunction

// 
// 
//  (See AddAListOfFieldsToTheForm)
//
// Parameters:
//  Form - ClientApplicationForm
//  Formula - String
//  
// Returns:
//  String
//
Function ViewFormulaByFormData(Form, Formula) Export
	
	Return FormulasConstructorInternal.FormulaPresentation(Form, Formula);
	
EndFunction

// Constructor of the ParameterFormula parameter for the Formula representation function.
// 
// Returns:
//  Structure:
//   * Formula - String
//   * Operands - String - : 
//                          See FieldTable
//                          See FieldTree
//                         
//                                                  
//                                                  
//   * Operators - String - : 
//                          See FieldTable
//                          See FieldTree
//                         
//                                                  
//                                                  
//   * OperandsDCSCollectionName  - String -  the name of the collection of fields in the settings builder. The parameter must
//                                          be used if the data layout scheme is passed in the Operands parameter.
//                                          The default value is available selection fields.
//   * OperatorsDCSCollectionName - String -  the name of the collection of fields in the settings builder. The parameter must
//                                          be used if the data layout scheme is passed in the Operators parameter.
//                                          The default value is available selection fields.
//   * Description - Undefined -  the name is not used for the formula, the corresponding field is not displayed.
//                  - String       - 
//                                   
//   * BracketsOperands - Boolean - 
//
Function FormulaEditingOptions() Export
	
	Return FormulasConstructorClientServer.FormulaEditingOptions();
	
EndFunction

// 
// 
// Parameters:
//  Form - ClientApplicationForm - 
//  FormulaPresentation - String - 
//  
// Returns:
//  String
//
Function TheFormulaFromTheView(Form, FormulaPresentation) Export
	
	Return FormulasConstructorInternal.TheFormulaFromTheView(Form, FormulaPresentation);
	
EndFunction

#EndRegion
