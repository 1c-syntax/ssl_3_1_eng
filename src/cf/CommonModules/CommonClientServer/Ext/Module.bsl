///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region UserNotification

// 

// Adds a new user error to the error list for further sending using
// the report error to User () procedure.
// It is intended for accumulating a list of errors and then processing this list before displaying
// it to the user. The resulting list of errors can, for example, be sorted by importance, cleared of duplicates,
// and also output to the user in a different form than the report to User method outputs, for example, in a table document.
//
// Parameters:
//  Errors - Undefined -  create a new list of errors.
//         - Structure:
//            * ErrorList - Array of Structure:
//             ** ErrorField - String
//             ** SingleErrorText - String
//             ** ErrorsGroup1 - Arbitrary
//             ** LineNumber - Number
//             ** SeveralErrorsText - String
//            * ErrorGroups - Map
//         
//  ErrorField - String -  the value that is set in the field property of the message object to the User.
//           For auto-substitution, the line number must contain "%1".
//           For Example, " Object.INN " or " Object.Users[%1].User".
//  SingleErrorText - String -  error text for the case when there is only one error Group in the collection,
//           for example, NSTR ("ru = 'The user is not selected.'").
//  ErrorsGroup1 - Arbitrary -  used to select either text for a single error
//           or text for multiple errors, such as the name " Object.Users".
//           If the value is not filled in, then the text for one error is used.
//  LineNumber - Number -  a value from 0 ... that specifies the line number to be inserted
//           in the error Field string and in the text for multiple Errors (string Number + 1 is substituted).
//  SeveralErrorsText - String -  error text for the case when several errors were added with the same
//           error Group property, for example, NSTR ("ru = 'The user in line %1 is not selected.'").
//  RowIndex - Undefined -  matches the value of the string Number parameter.
//           Number - a value from 0 ... that defines the line number to be inserted
//           in the Error field string.
//
Procedure AddUserError(
		Errors,
		ErrorField,
		SingleErrorText,
		ErrorsGroup1 = Undefined,
		LineNumber = 0,
		SeveralErrorsText = "",
		RowIndex = Undefined) Export
	
	If Errors = Undefined Then
		Errors = New Structure;
		Errors.Insert("ErrorList", New Array);
		Errors.Insert("ErrorGroups", New Map);
	EndIf;
	
	If Not ValueIsFilled(ErrorsGroup1) Then
		// 
	Else
		If Errors.ErrorGroups[ErrorsGroup1] = Undefined Then
			// 
			Errors.ErrorGroups.Insert(ErrorsGroup1, False);
		Else
			// 
			Errors.ErrorGroups.Insert(ErrorsGroup1, True);
		EndIf;
	EndIf;
	
	Error = New Structure;
	Error.Insert("ErrorField", ErrorField);
	Error.Insert("SingleErrorText", SingleErrorText);
	Error.Insert("ErrorsGroup1", ErrorsGroup1);
	Error.Insert("LineNumber", LineNumber);
	Error.Insert("SeveralErrorsText", SeveralErrorsText);
	Error.Insert("RowIndex", RowIndex);
	
	Errors.ErrorList.Add(Error);
	
EndProcedure

// 

// 
// 
// 
//
// Parameters:
//  Errors - See AddUserError.Errors
//  Cancel - Boolean -  set to True if errors were reported.
//
Procedure ReportErrorsToUser(Errors, Cancel = False) Export
	
	If Errors = Undefined Then
		Return;
	EndIf;
	Cancel = True;
	
	For Each Error In Errors.ErrorList Do
		
		If Error.RowIndex = Undefined Then
			RowIndex = Error.LineNumber;
		Else
			RowIndex = Error.RowIndex;
		EndIf;
		
		If Errors.ErrorGroups[Error.ErrorsGroup1] <> True Then
			Message = CommonInternalClientServer.UserMessage(
				Error.SingleErrorText,
				Undefined,
				StrReplace(Error.ErrorField, "%1", Format(RowIndex, "NZ=0; NG=")));
		Else
			Message = CommonInternalClientServer.UserMessage(
				StrReplace(Error.SeveralErrorsText, "%1", Format(Error.LineNumber + 1, "NZ=0; NG=")),
				Undefined,
				StrReplace(Error.ErrorField, "%1", Format(RowIndex, "NZ=0; NG=")));
		EndIf;
		Message.Message();
		
	EndDo;
	
EndProcedure

// Generates the text of errors in filling in fields and lists.
//
// Parameters:
//  FieldKind - String -  it can take the following values: Field, Column, List.
//  MessageKind - String -  it can take the following values: Filling In, Correctness.
//  FieldName - String -  field name.
//  LineNumber - String
//              - Number - 
//  ListName - String -  list name.
//  MessageText - String -  detailed explanation of the filling error.
//
// Returns:
//   String - 
//
Function FillingErrorText(
		FieldKind = "Field",
		MessageKind = "FillType",
		FieldName = "",
		LineNumber = "",
		ListName = "",
		MessageText = "") Export
	
	If Upper(FieldKind) = "FIELD" Then
		If Upper(MessageKind) = "FILLTYPE" Then
			Template =
				NStr("en = 'Field ""%1"" cannot be empty.';");
		ElsIf Upper(MessageKind) = "CORRECTNESS" Then
			Template =
				NStr("en = 'Invalid value in field ""%1"".
				           |%4';");
		EndIf;
	ElsIf Upper(FieldKind) = "COLUMN" Then
		If Upper(MessageKind) = "FILLTYPE" Then
			Template = NStr("en = 'Column ""%1"" in line #%2, list ""%3"" cannot be empty.';");
		ElsIf Upper(MessageKind) = "CORRECTNESS" Then
			Template = 
				NStr("en = 'Column ""%1"" in line #%2, list ""%3"" contains invalid value.
				           |%4';");
		EndIf;
	ElsIf Upper(FieldKind) = "LIST" Then
		If Upper(MessageKind) = "FILLTYPE" Then
			Template = NStr("en = 'The list ""%3"" is blank.';");
		ElsIf Upper(MessageKind) = "CORRECTNESS" Then
			Template =
				NStr("en = 'The list ""%3"" contains invalid data.
				           |%4';");
		EndIf;
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		FieldName,
		LineNumber,
		ListName,
		MessageText);
	
EndFunction

// Generates a path string lines that will be loaded and the column Markusica 
// table part Kataboliceski to issue messages in a form.
// For sharing with the report to User procedure
// (for passing a Field or path to The data parameters). 
//
// Parameters:
//  TabularSectionName - String -  name of the table part.
//  LineNumber - Number -  line number of the table part.
//  AttributeName - String - 
//
// Returns:
//  String - 
//
Function PathToTabularSection(
		Val TabularSectionName,
		Val LineNumber, 
		Val AttributeName) Export
	
	Return TabularSectionName + "[" + Format(LineNumber - 1, "NZ=0; NG=0") + "]." + AttributeName;
	
EndFunction

#EndRegion

#Region CurrentEnvironment

////////////////////////////////////////////////////////////////////////////////
// 

// For file mode, returns the full name of the folder where the database is located.
// If the client-server mode is used, an empty string is returned.
//
// Returns:
//  String - 
//
Function FileInfobaseDirectory() Export
	
	ConnectionParameters = StringFunctionsClientServer.ParametersFromString(InfoBaseConnectionString());
	
	If ConnectionParameters.Property("File") Then
		Return ConnectionParameters.File;
	EndIf;
	
	Return "";
	
EndFunction

// 
//
// Parameters:
//  ValueOf1CEnterpriseType - Undefined - 
//                                         
//                        - PlatformType - 
// Returns:
//  String - 
//
Function NameOfThePlatformType(Val ValueOf1CEnterpriseType = Undefined) Export
	
	SystemInfo = New SystemInfo;
	If TypeOf(ValueOf1CEnterpriseType) <> Type("PlatformType") Then
		ValueOf1CEnterpriseType = SystemInfo.PlatformType;
	EndIf;
	
	NamesOf1CEnterpriseTypes = New Array;
	NamesOf1CEnterpriseTypes.Add("Linux_x86");
	NamesOf1CEnterpriseTypes.Add("Linux_x86_64");
	
	NamesOf1CEnterpriseTypes.Add("MacOS_x86");
	NamesOf1CEnterpriseTypes.Add("MacOS_x86_64");
	
	NamesOf1CEnterpriseTypes.Add("Windows_x86");
	NamesOf1CEnterpriseTypes.Add("Windows_x86_64");
	
#If Not MobileClient Then
	If CompareVersions(SystemInfo.AppVersion, "8.3.22.1923") >= 0 Then
		NamesOf1CEnterpriseTypes.Add("Linux_ARM64");
		NamesOf1CEnterpriseTypes.Add("Linux_E2K");
	EndIf;
#EndIf
	
	If CompareVersions(SystemInfo.AppVersion, "8.3.23.0") >= 0 Then
		NamesOf1CEnterpriseTypes.Add("Android_ARM");
		NamesOf1CEnterpriseTypes.Add("Android_ARM_64");
		NamesOf1CEnterpriseTypes.Add("Android_x86");
		NamesOf1CEnterpriseTypes.Add("Android_x86_64");
		
		NamesOf1CEnterpriseTypes.Add("iOS_ARM");
		NamesOf1CEnterpriseTypes.Add("iOS_ARM_64");
		
		NamesOf1CEnterpriseTypes.Add("WinRT_ARM");
		NamesOf1CEnterpriseTypes.Add("WinRT_x86");
		NamesOf1CEnterpriseTypes.Add("WinRT_x86_64");
	EndIf;
	
	For Each NameOfThePlatformType In NamesOf1CEnterpriseTypes Do
		If ValueOf1CEnterpriseType = PlatformType[NameOfThePlatformType] Then
			Return NameOfThePlatformType;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

#EndRegion

#Region Data

// Throws an exception with the Message text if the Condition is not True.
// Used for self-diagnosis of code.
//
// Parameters:
//   Condition - Boolean -  if not True, an exception is thrown.
//   Message - String -  message text. If omitted, the exception is called with the default message.
//   CheckContext - String -  for example, the name of the procedure or function that is being checked.
//
Procedure Validate(Val Condition, Val Message = "", Val CheckContext = "") Export
	
	If Condition <> True Then
		
		If IsBlankString(Message) Then
			ExceptionText = NStr("en = 'Invalid operation.';"); // Assertion failed
		Else
			ExceptionText = Message;
		EndIf;
		
		If Not IsBlankString(CheckContext) Then
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = '%1 in %2';"), ExceptionText, CheckContext);
		EndIf;
		
		Raise ExceptionText;
		
	EndIf;
	
EndProcedure

// Throws an exception if the value type of the parameter ParameterName of the function or procedure of Impliedwarranties
// differs from the expected.
// For quick diagnostics of parameter types passed to procedures and functions in the program interface.
//
// Due to the implementation feature, the type Descriptor always includes the <Undefined>type.
// if strict type checking is required, use a 
// specific type, array, or type match in the expected Types parameter.
//
// Parameters:
//   NameOfAProcedureOrAFunction - String -  name of the procedure or function whose parameter is being checked.
//   ParameterName - String -  name of the procedure or function parameter to check.
//   ParameterValue - Arbitrary -  the actual value of the parameter.
//   ExpectedTypes - TypeDescription
//                 - Type
//                 - Array
//                 - FixedArray
//                 - Map
//                 - FixedMap - 
//       
//   PropertiesTypesToExpect - Structure -  if the expected type is a structure, 
//       you can specify the types of its properties in this parameter.
//   ExpectedValues - Array, String - 
//
Procedure CheckParameter(Val NameOfAProcedureOrAFunction, Val ParameterName, Val ParameterValue, 
	Val ExpectedTypes, Val PropertiesTypesToExpect = Undefined, Val ExpectedValues = Undefined) Export
	
	Context = "CommonClientServer.CheckParameter";
	Validate(TypeOf(NameOfAProcedureOrAFunction) = Type("String"), 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter.';"), "NameOfAProcedureOrAFunction"), 
		Context);
	Validate(TypeOf(ParameterName) = Type("String"), 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter.';"), "ParameterName"), 
			Context);
	
	IsCorrectType = ExpectedTypeValue(ParameterValue, ExpectedTypes);
	Validate(IsCorrectType <> Undefined, 
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter.';"), "ExpectedTypes"),
		Context);
		
	If ParameterValue = Undefined Then
		PresentationOfParameterValue = "Undefined";
	ElsIf TypeOf(ParameterValue) = Type("BinaryData") And ParameterValue.Size() = 0 Then
		PresentationOfParameterValue = "";
	Else
		PresentationOfParameterValue = String(ParameterValue);
	EndIf;
	
	Validate(IsCorrectType,
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2.
			           |Expected value: %3, passed value: %4 (type: %5).';"),
			ParameterName, NameOfAProcedureOrAFunction, TypesPresentation(ExpectedTypes), 
			PresentationOfParameterValue,
		TypeOf(ParameterValue)));
	
	If TypeOf(ParameterValue) = Type("Structure") And PropertiesTypesToExpect <> Undefined Then
		
		Validate(TypeOf(PropertiesTypesToExpect) = Type("Structure"), 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of the %1 parameter.';"), "NameOfAProcedureOrAFunction"),
			Context);
		
		For Each Property In PropertiesTypesToExpect Do
			
			ExpectedPropertyName = Property.Key;
			ExpectedPropertyType = Property.Value;
			PropertyValue = Undefined;
			
			Validate(ParameterValue.Property(ExpectedPropertyName, PropertyValue), 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Invalid value of parameter %1 (Structure) in %2.
					           |Expected value: %3 (type: %4).';"), 
					ParameterName, NameOfAProcedureOrAFunction, ExpectedPropertyName, ExpectedPropertyType));
			
			IsCorrectType = ExpectedTypeValue(PropertyValue, ExpectedPropertyType);
			Validate(IsCorrectType, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Invalid value of property %1 in parameter %2 (Structure) in %3.
					           |Expected value: %4; passed value: %5 (type: %6).';"), 
					ExpectedPropertyName, ParameterName,	NameOfAProcedureOrAFunction,
					TypesPresentation(ExpectedTypes), 
					?(PropertyValue <> Undefined, PropertyValue, NStr("en = 'Undefined';")),
				TypeOf(PropertyValue)));
			
		EndDo;
	EndIf;
	
	If ExpectedValues <> Undefined Then
		If TypeOf(ExpectedValues) = Type("String") Then
			ExpectedValues = StrSplit(ExpectedValues, ",");
		EndIf; 
		Validate(ExpectedValues.Find(ParameterValue) <> Undefined,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of the %1 parameter in %2.
				           |Expected value: %3.
				           |Passed value: %4 (type: %5).';"),
				ParameterName, NameOfAProcedureOrAFunction, StrConcat(ExpectedValues, ","), 
				PresentationOfParameterValue, TypeOf(ParameterValue)));
	EndIf;
	
EndProcedure

// Supplements the receiver value table with data from the source value table.
// The types of table Values, tree Values, and table Parts are not available on the client.
//
// Parameters:
//  SourceTable1 - ValueTable
//                  - ValueTree
//                  - TabularSection
//                  - FormDataCollection - 
//                    
//  DestinationTable - ValueTable
//                  - ValueTree
//                  - TabularSection
//                  - FormDataCollection - 
//                    
//
Procedure SupplementTable(SourceTable1, DestinationTable) Export
	
	For Each SourceTableRow In SourceTable1 Do
		
		FillPropertyValues(DestinationTable.Add(), SourceTableRow);
		
	EndDo;
	
EndProcedure

// Complements the table of values with values from the array Array.
//
// Parameters:
//  Table - ValueTable -  table to fill in with values from the array;
//  Array  - Array -  array of values to fill in the table;
//  FieldName - String -  name of the value table field to load values from the array into.
// 
Procedure SupplementTableFromArray(Table, Array, FieldName) Export

	For Each Value In Array Do
		
		Table.Add()[FieldName] = Value;
		
	EndDo;
	
EndProcedure

// Complements the array array Receiver with values from the array array Source.
//
// Parameters:
//  DestinationArray - Array -  array to add values to.
//  SourceArray1 - Array -  array of values to fill in.
//  UniqueValuesOnly - Boolean -  if true, only unique values will be included in the array.
//
Procedure SupplementArray(DestinationArray, SourceArray1, UniqueValuesOnly = False) Export
	
	If UniqueValuesOnly Then
		
		UniqueValues = New Map;
		
		For Each Value In DestinationArray Do
			UniqueValues.Insert(Value, True);
		EndDo;
		
		For Each Value In SourceArray1 Do
			If UniqueValues[Value] = Undefined Then
				DestinationArray.Add(Value);
				UniqueValues.Insert(Value, True);
			EndIf;
		EndDo;
		
	Else
		
		For Each Value In SourceArray1 Do
			DestinationArray.Add(Value);
		EndDo;
		
	EndIf;
	
EndProcedure

// Complements the structure with values from another structure.
//
// Parameters:
//   Receiver - Structure -  a collection to add new values to.
//   Source - Structure -  a collection from which the Key and Value pairs to fill will be read.
//   Replace - Boolean
//            - Undefined - :
//                             
//                             
//                             
//
Procedure SupplementStructure(Receiver, Source, Replace = Undefined) Export
	
	For Each Item In Source Do
		If Replace <> True And Receiver.Property(Item.Key) Then
			If Replace = False Then
				Continue;
			Else
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The source and destination have identical keys: ""%1"".';"), 
					Item.Key);
			EndIf
		EndIf;
		Receiver.Insert(Item.Key, Item.Value);
	EndDo;
	
EndProcedure

// Complements the match with values from another match.
//
// Parameters:
//   Receiver - Map -  a collection to add new values to.
//   Source - Map of KeyAndValue -  a collection from which the Key and Value pairs to fill will be read.
//   Replace - Boolean
//            - Undefined - :
//                             
//                             
//                             
//
Procedure SupplementMap(Receiver, Source, Replace = Undefined) Export
	
	For Each Item In Source Do
		If Replace <> True And Receiver[Item.Key] <> Undefined Then
			If Replace = False Then
				Continue;
			Else
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The source and destination have identical keys: ""%1"".';"), Item.Key);
			EndIf
		EndIf;
		Receiver.Insert(Item.Key, Item.Value);
	EndDo;
	
EndProcedure

// 
//  
// 
// 
// Parameters:
//  DestinationList - ValueList
//  SourceList - ValueList
//  ShouldSkipValuesOfOtherTypes - Boolean -  
//                                   
//                                  
//  AddNewItems - Boolean, Undefined - 
//                                          
// 
// Returns:
//  Structure:
//    * Total     - Number - 
//    * Added2 - Number - 
//    * Updated3 - Number -  
//                          
//    * Skipped3 - Number - 
//
Function SupplementList(Val DestinationList, Val SourceList, Val ShouldSkipValuesOfOtherTypes = Undefined, 
	Val AddNewItems = True) Export
	
	Result = New Structure;
	Result.Insert("Total", 0);
	Result.Insert("Added2", 0);
	Result.Insert("Updated3", 0);
	Result.Insert("Skipped3", 0);
	
	If DestinationList = Undefined Or SourceList = Undefined Then
		Return Result;
	EndIf;
	
	ReplaceExistingItems = True;
	ReplacePresentation = ReplaceExistingItems And AddNewItems;
	
	If ShouldSkipValuesOfOtherTypes = Undefined Then
		ShouldSkipValuesOfOtherTypes = (DestinationList.ValueType <> SourceList.ValueType);
	EndIf;
	If ShouldSkipValuesOfOtherTypes Then
		DestinationTypesDetails = DestinationList.ValueType;
	EndIf;
	For Each SourceItem In SourceList Do
		Result.Total = Result.Total + 1;
		Value = SourceItem.Value;
		If ShouldSkipValuesOfOtherTypes And Not DestinationTypesDetails.ContainsType(TypeOf(Value)) Then
			Result.Skipped3 = Result.Skipped3 + 1;
			Continue;
		EndIf;
		DestinationItem = DestinationList.FindByValue(Value);
		If DestinationItem = Undefined Then
			If AddNewItems Then
				Result.Added2 = Result.Added2 + 1;
				FillPropertyValues(DestinationList.Add(), SourceItem);
			Else
				Result.Skipped3 = Result.Skipped3 + 1;
			EndIf;
		Else
			If ReplaceExistingItems Then
				Result.Updated3 = Result.Updated3 + 1;
				FillPropertyValues(DestinationItem, SourceItem, , ?(ReplacePresentation, "", "Presentation"));
			Else
				Result.Skipped3 = Result.Skipped3 + 1;
			EndIf;
		EndIf;
	EndDo;
	Return Result;
EndFunction

// Checks whether an arbitrary object has a prop or property without accessing metadata.
//
// Parameters:
//  Object       - Arbitrary -  the object to check for the presence of a prop or property;
//  AttributeName - String       -  name of the item or property.
//
// Returns:
//  Boolean - 
//
Function HasAttributeOrObjectProperty(Object, AttributeName) Export
	
	UniqueKey   = New UUID;
	AttributeStructure = New Structure(AttributeName, UniqueKey);
	FillPropertyValues(AttributeStructure, Object);
	
	Return AttributeStructure[AttributeName] <> UniqueKey;
	
EndFunction

// Deletes all occurrences of the passed value from the array.
//
// Parameters:
//  Array - Array -  array to delete the value from;
//  Value - Arbitrary -  the value to delete from the array.
// 
Procedure DeleteAllValueOccurrencesFromArray(Array, Value) Export
	
	CollectionItemsCount = Array.Count();
	
	For ReverseIndex = 1 To CollectionItemsCount Do
		
		IndexOf = CollectionItemsCount - ReverseIndex;
		
		If Array[IndexOf] = Value Then
			
			Array.Delete(IndexOf);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes all occurrences of values of the specified type.
//
// Parameters:
//  Array - Array -  the array from which to remove values;
//  Type - Type -  type of values to be deleted from the array.
// 
Procedure DeleteAllTypeOccurrencesFromArray(Array, Type) Export
	
	CollectionItemsCount = Array.Count();
	
	For ReverseIndex = 1 To CollectionItemsCount Do
		
		IndexOf = CollectionItemsCount - ReverseIndex;
		
		If TypeOf(Array[IndexOf]) = Type Then
			
			Array.Delete(IndexOf);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Deletes a single value from the array.
//
// Parameters:
//  Array - Array -  array to delete the value from;
//  Value - Array -  the value to delete from the array.
// 
Procedure DeleteValueFromArray(Array, Value) Export
	
	IndexOf = Array.Find(Value);
	If IndexOf <> Undefined Then
		Array.Delete(IndexOf);
	EndIf;
	
EndProcedure

// Returns a copy of the original array with unique values.
//
// Parameters:
//  Array - Array -  an array of arbitrary values.
//
// Returns:
//  Array - 
//
Function CollapseArray(Val Array) Export
	Result = New Array;
	SupplementArray(Result, Array, True);
	Return Result;
EndFunction

// Returns the difference between arrays. The difference between two arrays is an array containing
// all elements of the first array that do not exist in the second array.
//
// Parameters:
//  Array - Array -  array of elements to subtract from;
//  SubtractionArray - Array -  array of elements to be subtracted.
// 
// Returns:
//  Array - 
//
// Example:
//	
//	
//	
//	
//
Function ArraysDifference(Val Array, Val SubtractionArray) Export
	
	Result = New Array;
	For Each Item In Array Do
		If SubtractionArray.Find(Item) = Undefined Then
			Result.Add(Item);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Compares elements of lists of values or arrays by value.
//
// Parameters:
//  List1 - Array
//          - ValueList - 
//  List2 - Array
//          - ValueList - 
//  ShouldCompareValuesCount - Boolean - :
//                                          
//                                           
//                                          
//
// Returns:
//  Boolean - 
//
Function ValueListsAreEqual(List1, List2, ShouldCompareValuesCount = False) Export
	
	If ShouldCompareValuesCount Then
		Count1 = List1.Count();
		Count2 = List2.Count();
		If Count1 <> Count2 Then
			Return False;
		EndIf;
	EndIf;
	
	Map1 = CollectionIntoMap(List1, ShouldCompareValuesCount);
	Map2 = CollectionIntoMap(List2, ShouldCompareValuesCount);
	
	ListsAreEqual = True;
	If ShouldCompareValuesCount Then
		For Each ListItem1 In Map1 Do
			If Map2[ListItem1.Key] <> ListItem1.Value Then
				ListsAreEqual = False;
				Break;
			EndIf;
		EndDo;
	Else
		For Each ListItem1 In Map1 Do
			If Map2[ListItem1.Key] = Undefined Then
				ListsAreEqual = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Not ListsAreEqual Then
		Return ListsAreEqual;
	EndIf;
	
	If ShouldCompareValuesCount Then
		For Each ListItem2 In Map2 Do
			If Map1[ListItem2.Key] <> ListItem2.Value Then
				ListsAreEqual = False;
				Break;
			EndIf;
		EndDo;
	Else
		For Each ListItem2 In Map2 Do
			If Map1[ListItem2.Key] = Undefined Then
				ListsAreEqual = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return ListsAreEqual;
	
EndFunction

// Creates an array and puts the passed value in it.
//
// Parameters:
//  Value - Arbitrary -  any value.
//
// Returns:
//  Array - 
//
Function ValueInArray(Val Value) Export
	
	Result = New Array;
	Result.Add(Value);
	Return Result;
	
EndFunction

// Gets a string that contains the keys of the structure, separated by a separator character.
//
// Parameters:
//  Structure - Structure -  a structure whose keys are converted to a string.
//  Separator - String -  a separator that is inserted in the string between the structure keys.
//
// Returns:
//  String - 
//
Function StructureKeysToString(Structure, Separator = ",") Export
	
	Result = "";
	
	For Each Item In Structure Do
		SeparatorChar = ?(IsBlankString(Result), "", Separator);
		Result = Result + SeparatorChar + Item.Key;
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the value of the structure property.
//
// Parameters:
//   Structure - Structure
//             - FixedStructure - 
//   Var_Key - String -  the property name of the structure for which you want to read the value.
//   DefaultValue - Arbitrary -  returned when the structure does not have a value for the specified
//                                        key.
//       For speed, it is recommended to pass only fast calculated values (for example, primitive types),
//       and initialize heavier values after checking the received value (only if
//       required).
//
// Returns:
//   Arbitrary - 
//
Function StructureProperty(Structure, Var_Key, DefaultValue = Undefined) Export
	
	If Structure = Undefined Then
		Return DefaultValue;
	EndIf;
	
	Result = DefaultValue;
	If Structure.Property(Var_Key, Result) Then
		Return Result;
	Else
		Return DefaultValue;
	EndIf;
	
EndFunction

// Returns an empty unique ID.
//
// Returns:
//  UUID - 00000000-0000-0000-0000-000000000000
//
Function BlankUUID() Export
	
	Return New UUID("00000000-0000-0000-0000-000000000000");
	
EndFunction

#EndRegion

#Region ConfigurationsVersioning

// Gets the configuration version number without the build number.
//
// Parameters:
//  Version - String -  configuration version in the format PP. PP. ZZ. SS,
//                    where SS is the build number to be deleted.
// 
// Returns:
//  String - 
//
Function ConfigurationVersionWithoutBuildNumber(Val Version) Export
	
	Array = StrSplit(Version, ".");
	
	If Array.Count() < 3 Then
		Return Version;
	EndIf;
	
	Result = "[Edition].[Subedition].[Release]";
	Result = StrReplace(Result, "[Edition]",    Array[0]);
	Result = StrReplace(Result, "[Subedition]", Array[1]);
	Result = StrReplace(Result, "[Release]",       Array[2]);
	
	Return Result;
EndFunction

// Compare two version strings.
//
// Parameters:
//  VersionString1  - String -  version number in the format PP. {P|PP}. ZZ. SS.
//  VersionString2  - String -  the second version number to compare.
//
// Returns:
//   Number   - 
//
Function CompareVersions(Val VersionString1, Val VersionString2) Export
	
	String1 = ?(IsBlankString(VersionString1), "0.0.0.0", VersionString1);
	String2 = ?(IsBlankString(VersionString2), "0.0.0.0", VersionString2);
	Version1 = StrSplit(String1, ".");
	If Version1.Count() <> 4 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid %1 parameter format: %2';"), "VersionString1", VersionString1);
	EndIf;
	Version2 = StrSplit(String2, ".");
	If Version2.Count() <> 4 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
	    	NStr("en = 'Invalid %1 parameter format: %2';"), "VersionString2", VersionString2);
	EndIf;
	
	Result = 0;
	For Digit = 0 To 3 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Compare two version strings.
//
// Parameters:
//  VersionString1  - String -  version number in the format PP. {P|PP}. ZZ.
//  VersionString2  - String -  the second version number to compare.
//
// Returns:
//   Number   - 
//
Function CompareVersionsWithoutBuildNumber(Val VersionString1, Val VersionString2) Export
	
	String1 = ?(IsBlankString(VersionString1), "0.0.0", VersionString1);
	String2 = ?(IsBlankString(VersionString2), "0.0.0", VersionString2);
	Version1 = StrSplit(String1, ".");
	If Version1.Count() <> 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid %1 parameter format: %2';"), "VersionString1", VersionString1);
	EndIf;
	Version2 = StrSplit(String2, ".");
	If Version2.Count() <> 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
	    	NStr("en = 'Invalid %1 parameter format: %2';"), "VersionString2", VersionString2);
	EndIf;
	
	Result = 0;
	For Digit = 0 To 2 Do
		Result = Number(Version1[Digit]) - Number(Version2[Digit]);
		If Result <> 0 Then
			Return Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

#EndRegion

#Region Forms

////////////////////////////////////////////////////////////////////////////////
// 
//

// Gets the value of the form's props.
//
// Parameters:
//  Form - ClientApplicationForm -  shape.
//  AttributePath2 - String -  the path to the data of the form's props, for example: "Object.Monthly calculation".
//
// Returns:
//  Arbitrary -  the requisite forms.
//
Function GetFormAttributeByPath(Form, AttributePath2) Export
	
	NamesArray = StrSplit(AttributePath2, ".");
	
	Object        = Form;
	LastField = NamesArray[NamesArray.Count()-1];
	
	For Cnt = 0 To NamesArray.Count()-2 Do
		Object = Object[NamesArray[Cnt]]
	EndDo;
	
	Return Object[LastField];
	
EndFunction

// Sets the value of the form's details.
// Parameters:
//  Form - ClientApplicationForm -  form - the owner of the props.
//  AttributePath2 - String -  the path to the data, for example: "Object.Monthly calculation".
//  Value - Arbitrary -  set value.
//  UnfilledOnly - Boolean -  allows you not to set the value of the props,
//                                  if it already has a value set.
//
Procedure SetFormAttributeByPath(Form, AttributePath2, Value, UnfilledOnly = False) Export
	
	NamesArray = StrSplit(AttributePath2, ".");
	
	Object        = Form;
	LastField = NamesArray[NamesArray.Count()-1];
	
	For Cnt = 0 To NamesArray.Count()-2 Do
		Object = Object[NamesArray[Cnt]]
	EndDo;
	If Not UnfilledOnly Or Not ValueIsFilled(Object[LastField]) Then
		Object[LastField] = Value;
	EndIf;
	
EndProcedure

// Searches for a selection item in the collection by the specified view.
//
// Parameters:
//  ItemsCollection - DataCompositionFilterItemCollection -  a container with selection elements and groups,
//                                                                  such as a List.Selection.Elements or group in the selection.
//  Presentation - String -  representation of group.
// 
// Returns:
//  DataCompositionFilterItem - 
//
Function FindFilterItemByPresentation(ItemsCollection, Presentation) Export
	
	ReturnValue = Undefined;
	
	For Each FilterElement In ItemsCollection Do
		If FilterElement.Presentation = Presentation Then
			ReturnValue = FilterElement;
			Break;
		EndIf;
	EndDo;
	
	Return ReturnValue
	
EndFunction

// Sets the property property Of the form element named element Name to the value Value.
// It is used in cases when the form element may not be on the form because the user does not have rights
// to the object, object details, or command.
//
// Parameters:
//  FormItems - FormAllItems
//                - FormItems - 
//  TagName   - String       - 
//  PropertyName   - String       -  name of the form element property to set.
//  Value      - Arbitrary -  new value of the element.
// 
Procedure SetFormItemProperty(FormItems, TagName, PropertyName, Value) Export
	
	FormItem = FormItems.Find(TagName);
	If FormItem <> Undefined And FormItem[PropertyName] <> Value Then
		FormItem[PropertyName] = Value;
	EndIf;
	
EndProcedure 

// Returns the value of the form element property Name_name with the name of the element Name.
// It is used in cases when the form element may not be on the form because the user does not have rights
// to the object, object details, or command.
//
// Parameters:
//  FormItems - FormAllItems
//                - FormItems - 
//  TagName   - String       - 
//  PropertyName   - String       -  name of the form element property.
// 
// Returns:
//   Arbitrary - 
// 
Function FormItemPropertyValue(FormItems, TagName, PropertyName) Export
	
	FormItem = FormItems.Find(TagName);
	Return ?(FormItem <> Undefined, FormItem[PropertyName], Undefined);
	
EndFunction 

// Gets an image to display on the page with the comment, depending
// on the presence of text in the comment.
//
// Parameters:
//  Comment  - String -  text of the comment.
//
// Returns:
//  Picture - 
//
Function CommentPicture(Comment) Export

	If Not IsBlankString(Comment) Then
		Picture = PictureLib.Comment;
	Else
		Picture = New Picture;
	EndIf;
	
	Return Picture;
	
EndFunction

#EndRegion

#Region DynamicList

////////////////////////////////////////////////////////////////////////////////
// 
//

// Find a selection element or group by the specified field name or view.
//
// Parameters:
//  SearchArea - DataCompositionFilter
//                - DataCompositionFilterItemGroup    -  a container with selection items and groups,
//                                                             such as a List.Selection or group in the selection.
//  FieldName       - String -  name of the layout field (not used for groups).
//  Presentation - String -  view of the layout field.
//
// Returns:
//  Array - 
//
Function FindFilterItemsAndGroups(Val SearchArea,
									Val FieldName = Undefined,
									Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	Return ItemArray;
	
EndFunction

// Add a selection group to the element Collection.
//
// Parameters:
//  ItemsCollection - DataCompositionFilter
//                     - DataCompositionFilterItemGroup    -  a container with selection items and groups,
//                                                                  such as a List.Selection or group in the selection.
//  Presentation      - String -  representation of group.
//  GroupType          - DataCompositionFilterItemsGroupType -  type of group.
//
// Returns:
//  DataCompositionFilterItemGroup - 
//
Function CreateFilterItemGroup(Val ItemsCollection, Presentation, GroupType) Export
	
	If TypeOf(ItemsCollection) = Type("DataCompositionFilterItemGroup")
		Or TypeOf(ItemsCollection) = Type("DataCompositionFilter") Then
		
		ItemsCollection = ItemsCollection.Items;
	EndIf;
	
	FilterItemsGroup = FindFilterItemByPresentation(ItemsCollection, Presentation);
	If FilterItemsGroup = Undefined Then
		FilterItemsGroup = ItemsCollection.Add(Type("DataCompositionFilterItemGroup"));
	Else
		FilterItemsGroup.Items.Clear();
	EndIf;
	
	FilterItemsGroup.Presentation    = Presentation;
	FilterItemsGroup.Application       = DataCompositionFilterApplicationType.Items;
	FilterItemsGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterItemsGroup.GroupType        = GroupType;
	FilterItemsGroup.Use    = True;
	
	Return FilterItemsGroup;
	
EndFunction

// Add a layout element to the layout element container.
//
// Parameters:
//  AreaToAddTo - DataCompositionFilter
//                    - DataCompositionFilterItemGroup -  a container with selection elements and groups,
//                                                              such as a List.Selection or group in the selection.
//  FieldName                 - String -  name of the data layout field (always filled in).
//  Var_ComparisonType            - DataCompositionComparisonType -  type of comparison.
//  RightValue          - Arbitrary -  compare value.
//  Presentation           - String -  representation of the data layout element.
//  Use           - Boolean -  using the element.
//  ViewMode        - DataCompositionSettingsItemViewMode -  display mode.
//  UserSettingID - String - see the selection of the submitted data.The
//                                                    identifier of the user setting in the syntax assistant.
// Returns:
//  DataCompositionFilterItem - 
//
Function AddCompositionItem(AreaToAddTo,
									Val FieldName,
									Val Var_ComparisonType,
									Val RightValue = Undefined,
									Val Presentation  = Undefined,
									Val Use  = Undefined,
									Val ViewMode = Undefined,
									Val UserSettingID = Undefined) Export
	
	Item = AreaToAddTo.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue = New DataCompositionField(FieldName);
	Item.ComparisonType = Var_ComparisonType;
	
	If ViewMode = Undefined Then
		Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	Else
		Item.ViewMode = ViewMode;
	EndIf;
	
	If RightValue <> Undefined Then
		Item.RightValue = RightValue;
	EndIf;
	
	If Presentation <> Undefined Then
		Item.Presentation = Presentation;
	EndIf;
	
	If Use <> Undefined Then
		Item.Use = Use;
	EndIf;
	
	// 
	// 
	// 
	If UserSettingID <> Undefined Then
		Item.UserSettingID = UserSettingID;
	ElsIf Item.ViewMode <> DataCompositionSettingsItemViewMode.Inaccessible Then
		Item.UserSettingID = FieldName;
	EndIf;
	
	Return Item;
	
EndFunction

// Change the selection element with the specified field name or view.
//
// Parameters:
//  SearchArea - DataCompositionFilter
//                - DataCompositionFilterItemGroup -  a container with selection items and groups,
//                                                          such as a List.Selection or group in the selection.
//  FieldName                 - String -  name of the data layout field (always filled in).
//  Presentation           - String -  representation of the data layout element.
//  RightValue          - Arbitrary -  compare value.
//  Var_ComparisonType            - DataCompositionComparisonType -  type of comparison.
//  Use           - Boolean -  using the element.
//  ViewMode        - DataCompositionSettingsItemViewMode -  display mode.
//  UserSettingID - String - see the selection of the submitted data.The
//                                                    identifier of the user setting in the syntax assistant.
//
// Returns:
//  Number - 
//
Function ChangeFilterItems(SearchArea,
								Val FieldName = Undefined,
								Val Presentation = Undefined,
								Val RightValue = Undefined,
								Val Var_ComparisonType = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined,
								Val UserSettingID = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If FieldName <> Undefined Then
			Item.LeftValue = New DataCompositionField(FieldName);
		EndIf;
		If Presentation <> Undefined Then
			Item.Presentation = Presentation;
		EndIf;
		If Use <> Undefined Then
			Item.Use = Use;
		EndIf;
		If Var_ComparisonType <> Undefined Then
			Item.ComparisonType = Var_ComparisonType;
		EndIf;
		If RightValue <> Undefined Then
			Item.RightValue = RightValue;
		EndIf;
		If ViewMode <> Undefined Then
			Item.ViewMode = ViewMode;
		EndIf;
		If UserSettingID <> Undefined Then
			Item.UserSettingID = UserSettingID;
		EndIf;
	EndDo;
	
	Return ItemArray.Count();
	
EndFunction

// Delete selection items with the specified field name or view.
//
// Parameters:
//  AreaToDelete - DataCompositionFilterItemCollection -  a container with selection elements and groups,
//                                                               such as a List.Selection or group in the selection..
//  FieldName         - String -  name of the layout field (not used for groups).
//  Presentation   - String -  view of the layout field.
//
Procedure DeleteFilterItems(Val AreaToDelete, Val FieldName = Undefined, Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array; // Array of DataCompositionFilterItem, DataCompositionFilterItemGroup
	
	FindRecursively(AreaToDelete.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If Item.Parent = Undefined Then
			AreaToDelete.Items.Delete(Item);
		Else
			Item.Parent.Items.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

// Add or replace an existing selection element.
//
// Parameters:
//  WhereToAdd - DataCompositionFilter
//                          - DataCompositionFilterItemGroup -  a container with selection elements and groups,
//                                     such as a List.Selection or group in the selection.
//  FieldName                 - String -  name of the data layout field (always filled in).
//  RightValue          - Arbitrary -  compare value.
//  Var_ComparisonType            - DataCompositionComparisonType -  type of comparison.
//  Presentation           - String -  representation of the data layout element.
//  Use           - Boolean -  using the element.
//  ViewMode        - DataCompositionSettingsItemViewMode -  display mode.
//  UserSettingID - String - see the selection of the submitted data.The
//                                                    identifier of the user setting in the syntax assistant.
//
Procedure SetFilterItem(WhereToAdd,
								Val FieldName,
								Val RightValue = Undefined,
								Val Var_ComparisonType = Undefined,
								Val Presentation = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined,
								Val UserSettingID = Undefined) Export
	
	ModifiedCount = ChangeFilterItems(WhereToAdd, FieldName, Presentation,
		RightValue, Var_ComparisonType, Use, ViewMode, UserSettingID);
	
	If ModifiedCount = 0 Then
		If Var_ComparisonType = Undefined Then
			If TypeOf(RightValue) = Type("Array")
				Or TypeOf(RightValue) = Type("FixedArray")
				Or TypeOf(RightValue) = Type("ValueList") Then
				Var_ComparisonType = DataCompositionComparisonType.InList;
			Else
				Var_ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		EndIf;
		If ViewMode = Undefined Then
			ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		AddCompositionItem(WhereToAdd, FieldName, Var_ComparisonType,
			RightValue, Presentation, Use, ViewMode, UserSettingID);
	EndIf;
	
EndProcedure

// Add or replace an existing selection element in the dynamic list.
//
// Parameters:
//   DynamicList - DynamicList -  the list where you want to set the selection.
//   FieldName            - String -  the field on which you want to set the selection.
//   RightValue     - Arbitrary -  the value of the selection.
//       Optional. The default value is Undefined.
//       Attention! If the value is Undefined, the value will not be changed.
//   Var_ComparisonType  - DataCompositionComparisonType -  selection condition.
//   Presentation - String -  representation of the data layout element.
//       Optional. The default value is Undefined.
//       If specified, only the use flag with the specified view is displayed (the value is not displayed).
//       To clear it (so that the value is output again), pass an empty string.
//   Use - Boolean -  check box for using this selection.
//       Optional. Default value: Undefined.
//   ViewMode - DataCompositionSettingsItemViewMode - 
//                                                                          :
//        
//        
//        
//   UserSettingID - String -  unique ID of this selection.
//       Used for communication with user settings.
//
Procedure SetDynamicListFilterItem(DynamicList, FieldName,
	RightValue = Undefined,
	Var_ComparisonType = Undefined,
	Presentation = Undefined,
	Use = Undefined,
	ViewMode = Undefined,
	UserSettingID = Undefined) Export
	
	If ViewMode = Undefined Then
		ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	If ViewMode = DataCompositionSettingsItemViewMode.Inaccessible Then
		DynamicListFilter = DynamicList.SettingsComposer.FixedSettings.Filter;
	Else
		DynamicListFilter = DynamicList.SettingsComposer.Settings.Filter;
	EndIf;
	
	SetFilterItem(
		DynamicListFilter,
		FieldName,
		RightValue,
		Var_ComparisonType,
		Presentation,
		Use,
		ViewMode,
		UserSettingID);
	
EndProcedure

// Delete a dynamic list selection group item.
//
// Parameters:
//  DynamicList - DynamicList -  details of the form to set the selection for.
//  FieldName         - String -  name of the layout field (not used for groups).
//  Presentation   - String -  view of the layout field.
//
Procedure DeleteDynamicListFilterGroupItems(DynamicList, FieldName = Undefined, Presentation = Undefined) Export
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.FixedSettings.Filter,
		FieldName,
		Presentation);
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.Settings.Filter,
		FieldName,
		Presentation);
	
EndProcedure

// To install or update the value of the parameter ParameterName dynamic list.
//
// Parameters:
//  List          - DynamicList -  the requisite forms for which you want to set the parameter.
//  ParameterName    - String             -  name of the dynamic list parameter.
//  Value        - Arbitrary        -  new parameter value.
//  Use   - Boolean             -  indicates whether the parameter is being used.
//
Procedure SetDynamicListParameter(List, ParameterName, Value, Use = True) Export
	
	DataCompositionParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	If DataCompositionParameterValue <> Undefined Then
		If Use And DataCompositionParameterValue.Value <> Value Then
			DataCompositionParameterValue.Value = Value;
		EndIf;
		If DataCompositionParameterValue.Use <> Use Then
			DataCompositionParameterValue.Use = Use;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FilesOperations

////////////////////////////////////////////////////////////////////////////////
// 
//

// Adds a trailing delimiter character to the passed directory path, if it is missing.
//
// Parameters:
//  DirectoryPath - String -  directory path.
//  Delete1CEnterprise - PlatformType -  this parameter is deprecated and is no longer used.
//
// Returns:
//  String
//
// Example:
//  Result = Dobasefinalization("Svi directory"); // returns "Svi directory\".
//  Result = Dobasefinalization("Svi directory\"); // returns "Svi directory\".
//  Result = add an end path Separator ("%APPDATA%"); / / returns " %APPDATA%\".
//
Function AddLastPathSeparator(Val DirectoryPath, Val Delete1CEnterprise = Undefined) Export
	If IsBlankString(DirectoryPath) Then
		Return DirectoryPath;
	EndIf;
	
	CharToAdd = GetPathSeparator();
	
	If StrEndsWith(DirectoryPath, CharToAdd) Then
		Return DirectoryPath;
	Else 
		Return DirectoryPath + CharToAdd;
	EndIf;
EndFunction

// Composes the full file name from the directory name and file name.
//
// Parameters:
//  DirectoryName  - String -  path to the file directory on disk.
//  FileName     - String -  file name, without a directory name.
//
// Returns:
//   String
//
Function GetFullFileName(Val DirectoryName, Val FileName) Export

	If Not IsBlankString(FileName) Then
		
		Slash = "";
		If (Right(DirectoryName, 1) <> "\") And (Right(DirectoryName, 1) <> "/") Then
			Slash = ?(StrFind(DirectoryName, "\") = 0, "/", "\");
		EndIf;
		
		Return DirectoryName + Slash + FileName;
		
	Else
		
		Return DirectoryName;
		
	EndIf;

EndFunction

// Decomposes the full file name into its components.
//
// Parameters:
//  FullFileName - String -  full path to the file or directory.
//  IsDirectory - Boolean -  indicates that the folder name was passed.
//
// Returns:
//   Structure - :
//     
//     
//     
//     
//     
// 
// Example:
//  FullFile name = "c:\temp\test.txt";
//  Partial File Name = Decompose FullFile Name(FullFile Name);
//  
//  As a result, the field structure will be filled in as follows:
//    FullName: "c:\temp\test.txt",
//    Path: "c:\temp\",
//    Name: "test.txt",
//    Extension:". txt",
//    Extension name: "test".
//
Function ParseFullFileName(Val FullFileName, IsDirectory = False) Export
	
	FileNameStructure = New Structure("FullName,Path,Name,Extension,BaseName");
	FillPropertyValues(FileNameStructure, New File(FullFileName));
	
	If FileNameStructure.Path = GetPathSeparator() Then
		FileNameStructure.Path = "";
	EndIf;
	
	Return FileNameStructure;
	
EndFunction

// 
//
// Parameters:
//  String - String -  original string.
//
// Returns:
//  Array of String
//
Function ParseStringByDotsAndSlashes(Val String) Export
	
	Var CurrentPosition;
	
	Particles = New Array;
	
	StartPosition = 1;
	
	For CurrentPosition = 1 To StrLen(String) Do
		CurrentChar = Mid(String, CurrentPosition, 1);
		If CurrentChar = "." Or CurrentChar = "/" Or CurrentChar = "\" Then
			CurrentFragment = Mid(String, StartPosition, CurrentPosition - StartPosition);
			StartPosition = CurrentPosition + 1;
			Particles.Add(CurrentFragment);
		EndIf;
	EndDo;
	
	If StartPosition <> CurrentPosition Then
		CurrentFragment = Mid(String, StartPosition, CurrentPosition - StartPosition);
		Particles.Add(CurrentFragment);
	EndIf;
	
	Return Particles;
	
EndFunction

// Selects the file extension (the set of characters after the last dot) from the file name.
//
// Parameters:
//  FileName - String -  file name with or without a directory name.
//
// Returns:
//   String
//
Function GetFileNameExtension(Val FileName) Export
	
	FileExtention = "";
	RowsArray = StrSplit(FileName, ".", False);
	If RowsArray.Count() > 1 Then
		FileExtention = RowsArray[RowsArray.Count() - 1];
	EndIf;
	Return FileExtention;
	
EndFunction

// Converts the file extension to lowercase without a dot.
//
// Parameters:
//  Extension - String -  extension for conversion.
//
// Returns:
//  String
//
Function ExtensionWithoutPoint(Val Extension) Export
	
	Extension = Lower(TrimAll(Extension));
	
	If Mid(Extension, 1, 1) = "." Then
		Extension = Mid(Extension, 2);
	EndIf;
	
	Return Extension;
	
EndFunction

// Returns the name of the file with the extension.
// If the extension is empty, then the point is not added.
//
// Parameters:
//  BaseName - String -  file name without extension.
//  Extension       - String -  expansion.
//
// Returns:
//  String
//
Function GetNameWithExtension(BaseName, Extension) Export
	
	If IsBlankString(Extension) Then
		Return BaseName;
	EndIf;
	
	Return BaseName + "." + Extension;
	
EndFunction

// Returns a string of invalid characters.
// According to http://en.wikipedia.org/wiki/Filename -in the "Reserved characters and words" section.
// 
// Returns:
//   String
//
Function GetProhibitedCharsInFileName() Export

	InvalidChars = """/\[]:;|=?*<>";
	InvalidChars = InvalidChars + Chars.Tab + Chars.LF;
	Return InvalidChars;

EndFunction

// Checks for invalid characters in the file name.
//
// Parameters:
//  FileName  - String -  file name.
//
// Returns:
//   Array of String  - 
//                       
//
Function FindProhibitedCharsInFileName(FileName) Export

	InvalidChars = GetProhibitedCharsInFileName();
	
	FoundProhibitedCharsArray = New Array;
	
	For CharPosition = 1 To StrLen(InvalidChars) Do
		CharToCheck = Mid(InvalidChars,CharPosition,1);
		If StrFind(FileName,CharToCheck) <> 0 Then
			FoundProhibitedCharsArray.Add(CharToCheck);
		EndIf;
	EndDo;
	
	Return FoundProhibitedCharsArray;

EndFunction

// Replaces invalid characters in the file name.
//
// Parameters:
//  FileName     - String -  the original file name.
//  WhatReplaceWith  - String -  string to replace invalid characters with.
//
// Returns:
//   String
//
Function ReplaceProhibitedCharsInFileName(Val FileName, WhatReplaceWith = " ") Export
	
	Return TrimAll(StrConcat(StrSplit(FileName, GetProhibitedCharsInFileName(), True), WhatReplaceWith));

EndFunction

#EndRegion

#Region EmailAddressesOperations

////////////////////////////////////////////////////////////////////////////////
// 
//

// Parses the string with email addresses. When parsing, it checks the correctness of addresses.
//
// Parameters:
//  AddressesList - String - :
//                           
//
// Returns:
//  Array of Structure:
//   * Alias      - String -  representation of the addressee.
//   * Address          - String - 
//                               
//                               
//   * ErrorDescription - String - 
//
Function EmailsFromString(Val AddressesList) Export
	
	Result = New Array;
	BracketChars = "()[]";
	AddressesList = StrConcat(StrSplit(AddressesList, BracketChars + " ", False), " ");
	AddressesList = StrReplace(AddressesList, ">", ">;");
	
	For Each Email In StrSplit(AddressesList, ";", False) Do
		PresentationParts = New Array;
		For Each AddressWithAView In StrSplit(TrimAll(Email), ",", False) Do
			If Not ValueIsFilled(AddressWithAView) Then
				PresentationParts.Add(AddressWithAView);
				Continue;
			EndIf;
			
			StringParts1 = StrSplit(TrimR(AddressWithAView), " ", True);
			Address = TrimAll(StringParts1[StringParts1.UBound()]);
			Alias = "";
			ErrorDescription = "";
			
			If StrFind(Address, "@") Or StrFind(Address, "<") Or StrFind(Address, ">") Then
				Address = StrConcat(StrSplit(Address, "<>", False), "");
				If EmailAddressMeetsRequirements(Address) Then
					StringParts1.Delete(StringParts1.UBound());
				Else
					ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"en = 'Invalid email address: %1.';"), Address);
					Address = "";
				EndIf;
				
				Alias = TrimAll(StrConcat(PresentationParts, ",") + StrConcat(StringParts1, " "));
				PresentationParts.Clear();
				AddressStructure1 = New Structure("Alias, Address, ErrorDescription", Alias, Address, ErrorDescription);
				Result.Add(AddressStructure1);
			Else
				PresentationParts.Add(AddressWithAView);
			EndIf;
		EndDo;
		
		Alias = StrConcat(PresentationParts, ",");
		If ValueIsFilled(Alias) Then
			Address = "";
			ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"en = 'Invalid email address: %1.';"), Alias);
			AddressStructure1 = New Structure("Alias, Address, ErrorDescription", Alias, Address, ErrorDescription);
			Result.Add(AddressStructure1);
		EndIf;
	EndDo;
		
	Return Result;
	
EndFunction

// Checks the email address for compliance with RFC 5321, RFC 5322,
// and RFC 5335, RFC 5336, and RFC 3696.
// In addition, the function restricts the use of special characters.
// 
// Parameters:
//  Address - String -  verified email.
//  AllowLocalAddresses - Boolean -  do not issue an error if the domain zone is missing from the address.
//
// Returns:
//  Boolean - 
//
Function EmailAddressMeetsRequirements(Val Address, AllowLocalAddresses = False) Export
	
	// 
	Letters = "abcdefghijklmnopqrstuvwxyz";
	Digits = "0123456789";
	SpecialChars = ".@_-:+";
	
	// 
	If StrOccurrenceCount(Address, "@") <> 1 Then
		Return False;
	EndIf;
	
	// 
	If StrOccurrenceCount(Address, ":") > 1 Then
		Return False;
	EndIf;
	
	// 
	If StrFind(Address, "..") > 0 Then
		Return False;
	EndIf;
	
	// 
	Address = Lower(Address);
	
	// 
	If Not StringContainsAllowedCharsOnly(Address, Letters + Digits + SpecialChars) Then
		Return False;
	EndIf;
	
	// 
	Position = StrFind(Address,"@");
	LocalName = Left(Address, Position - 1);
	Domain = Mid(Address, Position + 1);
	
	// 
	If IsBlankString(LocalName)
	 	Or IsBlankString(Domain)
		Or StrLen(LocalName) > 64
		Or StrLen(Domain) > 255 Then
		
		Return False;
	EndIf;
	
	// 
	If HasCharsLeftRight(LocalName, ".") Or HasCharsLeftRight(Domain, SpecialChars) Then
		Return False;
	EndIf;
	
	// 
	If Not AllowLocalAddresses And StrFind(Domain,".") = 0 Then
		Return False;
	EndIf;
	
	// 
	If StrFind(Domain,"_") > 0 Then
		Return False;
	EndIf;
	
	// 
	If StrFind(Domain,":") > 0 Then
		Return False;
	EndIf;
	
	// 
	If StrFind(Domain,"+") > 0 Then
		Return False;
	EndIf;
	
	// 
	Zone = Domain;
	Position = StrFind(Zone,".");
	While Position > 0 Do
		Zone = Mid(Zone, Position + 1);
		Position = StrFind(Zone,".");
	EndDo;
	
	// 
	Return AllowLocalAddresses Or StrLen(Zone) >= 2 And StringContainsAllowedCharsOnly(Zone,Letters);
	
EndFunction

// 
//
// 
//  
// 
//  
//
// Parameters:
//  Addresses - String -  the correct string with the email addresses.
//  RaiseException1 - Boolean - 
//
// Returns:
//  Array of Structure:
//   * Address - String -  recipient's e-mail address.
//   * Presentation - String -  recipient's name.
//
Function ParseStringWithEmailAddresses(Val Addresses, RaiseException1 = True) Export
	
	Result = New Array;
	ErrorsDetails = New Array;
	SMSMessageRecipients = EmailsFromString(Addresses);
	
	For Each Addressee In SMSMessageRecipients Do
		If ValueIsFilled(Addressee.ErrorDescription) Then
			ErrorsDetails.Add(Addressee.ErrorDescription);
		EndIf;
		
		Result.Add(New Structure("Address, Presentation", Addressee.Address, Addressee.Alias));
	EndDo;
	
	If RaiseException1 And ValueIsFilled(ErrorsDetails) Then
		ErrorText = StrConcat(ErrorsDetails, Chars.LF);
		Raise ErrorText;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ExternalConnection

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the name of the COM class for working with 1C:Windows 8 via COM connection.
//
// Returns:
//  String
//
Function COMConnectorName() Export
	
	SystemData = New SystemInfo;
	VersionSubstrings = StrSplit(SystemData.AppVersion, ".");
	Return "v" + VersionSubstrings[0] + VersionSubstrings[1] + ".COMConnector";
	
EndFunction

// 
// 
// 
// Returns:
//  Structure:
//    * InfobaseOperatingMode - Number - 
//    * InfobaseDirectory - String - 
//    * NameOf1CEnterpriseServer - String - 
//    * NameOfInfobaseOn1CEnterpriseServer - String -  
//    * OperatingSystemAuthentication - Boolean - 
//                                          
//    * UserName - String - 
//    * UserPassword - String - 
//
Function ParametersStructureForExternalConnection() Export
	
	Result = New Structure;
	Result.Insert("InfobaseOperatingMode", 0);
	Result.Insert("InfobaseDirectory", "");
	Result.Insert("NameOf1CEnterpriseServer", "");
	Result.Insert("NameOfInfobaseOn1CEnterpriseServer", "");
	Result.Insert("OperatingSystemAuthentication", False);
	Result.Insert("UserName", "");
	Result.Insert("UserPassword", "");
	
	Return Result;
	
EndFunction

// Retrieves connection parameters from the connection string with the information base
// and passes the parameters to the structure for setting up an external connection.
//
// Parameters:
//  ConnectionString - String -  the connection string is.
// 
// Returns:
//   See ParametersStructureForExternalConnection
//
Function GetConnectionParametersFromInfobaseConnectionString(Val ConnectionString) Export
	
	Result = ParametersStructureForExternalConnection();
	
	Parameters = StringFunctionsClientServer.ParametersFromString(ConnectionString);
	
	Parameters.Property("File", Result.InfobaseDirectory);
	Parameters.Property("Srvr", Result.NameOf1CEnterpriseServer);
	Parameters.Property("Ref",  Result.NameOfInfobaseOn1CEnterpriseServer);
	
	Result.InfobaseOperatingMode = ?(Parameters.Property("File"), 0, 1);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Math

////////////////////////////////////////////////////////////////////////////////
// 

// Performs a proportional distribution of the amount according
// to the specified distribution coefficients.
//
// Parameters:
//  AmountToDistribute - Number  -  the amount to distribute, if the amount is 0, it is returned Undefined;
//                                 If you pass in a negative calculation in the module after inversion of the signs of the result.
//  Coefficients        - Array -  distribution coefficients must be positive or negative at the same time
//  Accuracy            - Number  -  rounding precision in the distribution. Optional.
//
// Returns:
//  Array - 
//           
//           
//           
//           
//
// Example:
//
//	
//	
//	
//	
//	
//
Function DistributeAmountInProportionToCoefficients(Val AmountToDistribute, Val Coefficients, Val Accuracy = 2) Export
	
	AbsoluteCoefficients = New Array(New FixedArray(Coefficients)); // 
	
	// 
	If Not ValueIsFilled(AmountToDistribute) Then 
		Return Undefined;
	EndIf;
	
	If AbsoluteCoefficients.Count() = 0 Then 
		// 
		// 
		Return Undefined;
	EndIf;
	
	MaxCoefficientIndex = 0;
	MaxCoefficient = 0;
	CoefficientsSum = 0;
	NegativeCoefficients = (AbsoluteCoefficients[0] < 0);
	
	For IndexOf = 0 To AbsoluteCoefficients.Count() - 1 Do
		ZoomRatio = AbsoluteCoefficients[IndexOf];
		
		If NegativeCoefficients And ZoomRatio > 0 Then 
			// 
			// 
			Return Undefined;
		EndIf;
		
		If ZoomRatio < 0 Then 
			// 
			ZoomRatio = -ZoomRatio; // 
			AbsoluteCoefficients[IndexOf] = ZoomRatio; // 
		EndIf;
		
		If MaxCoefficient < ZoomRatio Then
			MaxCoefficient = ZoomRatio;
			MaxCoefficientIndex = IndexOf;
		EndIf;
		
		CoefficientsSum = CoefficientsSum + ZoomRatio;
	EndDo;
	
	If CoefficientsSum = 0 Then
		// 
		// 
		Return Undefined;
	EndIf;
	
	Result = New Array(AbsoluteCoefficients.Count());
	
	Invert = (AmountToDistribute < 0);
	If Invert Then 
		// 
		// 
		AmountToDistribute = -AmountToDistribute; // 
	EndIf;
	
	DistributedAmount = 0;
	
	For IndexOf = 0 To AbsoluteCoefficients.Count() - 1 Do
		Result[IndexOf] = Round(AmountToDistribute * AbsoluteCoefficients[IndexOf] / CoefficientsSum, Accuracy, 1);
		DistributedAmount = DistributedAmount + Result[IndexOf];
	EndDo;
	
	CombinedInaccuracy = AmountToDistribute - DistributedAmount;
	
	If CombinedInaccuracy > 0 Then 
		
		// 
		If Not DistributedAmount = AmountToDistribute Then
			Result[MaxCoefficientIndex] = Result[MaxCoefficientIndex] + CombinedInaccuracy;
		EndIf;
		
	ElsIf CombinedInaccuracy < 0 Then 
		
		// 
		InaccuracyValue = 1 / Pow(10, Accuracy);
		InaccuracyItemCount = -CombinedInaccuracy / InaccuracyValue;
		
		For Cnt = 1 To InaccuracyItemCount Do 
			MaxCoefficient = MaxValueInArray(AbsoluteCoefficients);
			IndexOf = AbsoluteCoefficients.Find(MaxCoefficient);
			Result[IndexOf] = Result[IndexOf] - InaccuracyValue;
			AbsoluteCoefficients[IndexOf] = 0;
		EndDo;
		
	Else 
		// 
	EndIf;
	
	If Invert Then 
		For IndexOf = 0 To AbsoluteCoefficients.Count() - 1 Do
			Result[IndexOf] = -Result[IndexOf];
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region XMLSerialization

// Replaces invalid characters in the XML string with the specified characters.
//
// Parameters:
//   Text - String -  the row in which you want to replace invalid characters.
//   ReplacementChar - String -  string to replace an invalid character with in the XML string.
// 
// Returns:
//    String
//
Function ReplaceProhibitedXMLChars(Val Text, ReplacementChar = " ") Export
	
#If Not WebClient Then
	StartPosition = 1;
	Position = XMLStringProcessing.FindDisallowedXMLCharacters(Text, StartPosition);
	While Position > 0 Do
		InvalidChar = Mid(Text, Position, 1);
		Text = StrReplace(Text, InvalidChar, ReplacementChar);
		StartPosition = Position + StrLen(ReplacementChar);
		If StartPosition > StrLen(Text) Then
			Break;
		EndIf;
		Position = XMLStringProcessing.FindDisallowedXMLCharacters(Text, StartPosition);
	EndDo;
	
	Return Text;
#Else
	// 
	// 
	Total = "";
	StringLength = StrLen(Text);
	
	For CharacterNumber = 1 To StringLength Do
		Char = Mid(Text, CharacterNumber, 1);
		CharCode = CharCode(Char);
		
		If CharCode < 9
		 Or CharCode > 10    And CharCode < 13
		 Or CharCode > 13    And CharCode < 32
		 Or CharCode > 55295 And CharCode < 57344 Then
			
			Char = ReplacementChar;
		EndIf;
		Total = Total + Char;
	EndDo;
	
	Return Total;
#EndIf
	
EndFunction

// Deletes invalid characters in the XML string.
//
// Parameters:
//  Text - String -  a string where you want to delete invalid characters.
// 
// Returns:
//  String
//
Function DeleteDisallowedXMLCharacters(Val Text) Export
	
	Return ReplaceProhibitedXMLChars(Text, "");
	
EndFunction

#EndRegion

#Region SpreadsheetDocument

// 
//
// Parameters:
//  SpreadsheetDocumentField - FormField -  a field in the form with the view
//                            of the field of the document that you want to set the state for.
//  State               - String - 
//
Procedure SetSpreadsheetDocumentFieldState(SpreadsheetDocumentField, State = "DontUse") Export
	
	If TypeOf(SpreadsheetDocumentField) = Type("FormField") 
		And SpreadsheetDocumentField.Type = FormFieldType.SpreadsheetDocumentField Then
		StatePresentation = SpreadsheetDocumentField.StatePresentation;
		If Upper(State) = "DONTUSE" Then
			StatePresentation.Visible                      = False;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.DontUse;
			StatePresentation.Picture                       = New Picture;
			StatePresentation.Text                          = "";
		ElsIf Upper(State) = "IRRELEVANCE" Then
			StatePresentation.Visible                      = True;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
			StatePresentation.Picture                       = New Picture;
			StatePresentation.Text                          = NStr("en = 'To run the report, click ""Generate"".';");
		ElsIf Upper(State) = "REPORTGENERATION" Then  
			StatePresentation.Visible                      = True;
			StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
			StatePresentation.Picture                       = PictureLib.TimeConsumingOperation48;
			StatePresentation.Text                          = NStr("en = 'Generating report…';");
		Else
			CheckParameter(
				"CommonClientServer.SetSpreadsheetDocumentFieldState", "State", State, 
				Type("String"),, "DontUse,Irrelevance,ReportGeneration");
		EndIf;
	Else
		CheckParameter(
			"CommonClientServer.SetSpreadsheetDocumentFieldState", "SpreadsheetDocumentField", 
			SpreadsheetDocumentField, Type("FormField"));
		Validate(SpreadsheetDocumentField.Type = FormFieldType.SpreadsheetDocumentField,
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of the %1 parameter in %2.
				           |Expected value: %3, passed value: %4 (type: %5).';"),
				"SpreadsheetDocumentField", "CommonClientServer.SetSpreadsheetDocumentFieldState", 
				"FormFieldType.SpreadsheetDocumentField", SpreadsheetDocumentField.Type, TypeOf(SpreadsheetDocumentField.Type)));	
	EndIf;
	
EndProcedure

// Calculates the values of numeric cells in a table document.
//
// Parameters:
//  SpreadsheetDocument - SpreadsheetDocument -  the document whose numerical values are calculated.
//  SpreadsheetDocumentField - FormField
//                          - SpreadsheetDocumentField - 
//                            
//  CalculationParameters - Undefined
//                   - See CellsIndicatorsCalculationParameters
//
// Returns:
//   Structure:
//       * Count         - Number -  the number of selected cells.
//       * NumericCellsCount - Number -  number of numeric cells.
//       * Sum      - Number -  the sum of the selected cells with numbers.
//       * Mean    - Number -  the sum of the selected cells with numbers.
//       * Minimum    - Number -  the sum of the selected cells with numbers.
//       * Maximum   - Number -  maximum of selected cells with numbers.
//
Function CalculationCellsIndicators(Val SpreadsheetDocument, Val SpreadsheetDocumentField, CalculationParameters = Undefined) Export 
	
	If CalculationParameters = Undefined Then 
		CalculationParameters = CellsIndicatorsCalculationParameters(SpreadsheetDocumentField);
	EndIf;
	
	If CalculationParameters.CalculateAtServer Then 
		Return StandardSubsystemsServerCall.CalculationCellsIndicators(
			SpreadsheetDocument, CalculationParameters.SelectedAreas);
	EndIf;
	
	Return CommonInternalClientServer.CalculationCellsIndicators(
		SpreadsheetDocument, CalculationParameters.SelectedAreas);
	
EndFunction

// Generates a description of the selected areas of the table document.
//
// Parameters:
//  SpreadsheetDocumentField - FormField
//                          - SpreadsheetDocumentField - 
//                            
//
// Returns: 
//   Structure:
//     * SelectedAreas - Array - :
//         * Top  - Number -  line number of the upper border of the area.
//         * Bottom   - Number -  line number of the lower border of the area.
//         * Left  - Number -  column number of the upper border of the area.
//         * Right - Number -  column number of the lower border of the area.
//         * AreaType - SpreadsheetDocumentCellAreaType -  Columns, Rectangle, Rows, Table.
//     * CalculateAtServer - Boolean -  indicates that the calculation should be performed on the server if
//                                      the number of selected cells is more than or equal to 1000,
//                                      or the number of selected areas is more than or equal to 100,
//                                      or the entire field of the tabular document is selected.
//                                      In such cases, the calculation of indicators on the client is very expensive. 
//
Function CellsIndicatorsCalculationParameters(SpreadsheetDocumentField) Export 
	
	IndicatorsCalculationParameters = New Structure;
	IndicatorsCalculationParameters.Insert("SelectedAreas", New Array);
	IndicatorsCalculationParameters.Insert("CalculateAtServer", False);
	
	SelectedAreas = IndicatorsCalculationParameters.SelectedAreas;
	SelectedDocumentAreas = SpreadsheetDocumentField.GetSelectedAreas();
	
	NumberOfSelectedCells = 0;
	
	For Each SelectedArea1 In SelectedDocumentAreas Do
		
		If TypeOf(SelectedArea1) <> Type("SpreadsheetDocumentRange") Then
			Continue;
		EndIf;
		
		AreaBoundaries = New Structure("Top, Bottom, Left, Right, AreaType");
		FillPropertyValues(AreaBoundaries, SelectedArea1);
		SelectedAreas.Add(AreaBoundaries);
		
		NumberOfSelectedCells = NumberOfSelectedCells
			+ (SelectedArea1.Right - SelectedArea1.Left + 1)
			* (SelectedArea1.Bottom - SelectedArea1.Top + 1);
		
	EndDo;
	
	SelectedAll = False;
	
	If SelectedAreas.Count() = 1 Then 
		
		SelectedArea1 = SelectedAreas[0];
		SelectedAll = Not Boolean(
			SelectedArea1.Top
			+ SelectedArea1.Bottom
			+ SelectedArea1.Left
			+ SelectedArea1.Right);
		
	EndIf;
	
	IndicatorsCalculationParameters.CalculateAtServer = (SelectedAll
		Or SelectedAreas.Count() >= 100
		Or NumberOfSelectedCells >= 1000);
	
	Return IndicatorsCalculationParameters;
	
EndFunction

#EndRegion

#Region ScheduledJobs

// Converts the schedule of an ad Task to a structure.
//
// Parameters:
//  Schedule - JobSchedule -  original schedule.
// 
// Returns:
//  Structure:
//    * CompletionTime          - Date
//    * EndTime               - Date
//    * BeginTime              - Date
//    * EndDate                - Date
//    * StartDate               - Date
//    * DayInMonth              - Date
//    * WeekDayInMonth        - Number
//    * WeekDays                - Number
//    * CompletionInterval       - Number
//    * Months                   - Array of Number
//    * RepeatPause             - Number
//    * WeeksPeriod             - Number
//    * RepeatPeriodInDay - Number
//    * DaysRepeatPeriod        - Number
//    * DetailedDailySchedules   - Array of See ScheduleToStructure 
//
Function ScheduleToStructure(Val Schedule) Export
	
	ScheduleValue = Schedule;
	If ScheduleValue = Undefined Then
		ScheduleValue = New JobSchedule();
	EndIf;
	FieldList = "CompletionTime,EndTime,BeginTime,EndDate,BeginDate,DayInMonth,WeekDayInMonth,"
		+ "WeekDays,CompletionInterval,Months,RepeatPause,WeeksPeriod,RepeatPeriodInDay,DaysRepeatPeriod";
	Result = New Structure(FieldList);
	FillPropertyValues(Result, ScheduleValue, FieldList);
	DetailedDailySchedules = New Array;
	For Each DailySchedule In Schedule.DetailedDailySchedules Do
		DetailedDailySchedules.Add(ScheduleToStructure(DailySchedule));
	EndDo;
	Result.Insert("DetailedDailySchedules", DetailedDailySchedules);
	Return Result;
	
EndFunction

// Converts the structure to a timesheet of an ad task.
//
// Parameters:
//  ScheduleStructure1 - Structure -  schedule as a structure.
// 
// Returns:
//  JobSchedule -  schedule.
//
Function StructureToSchedule(Val ScheduleStructure1) Export
	
	If ScheduleStructure1 = Undefined Then
		Return New JobSchedule();
	EndIf;
	FieldList = "CompletionTime,EndTime,BeginTime,EndDate,BeginDate,DayInMonth,WeekDayInMonth,"
		+ "WeekDays,CompletionInterval,Months,RepeatPause,WeeksPeriod,RepeatPeriodInDay,DaysRepeatPeriod";
	Result = New JobSchedule;
	FillPropertyValues(Result, ScheduleStructure1, FieldList);
	DetailedDailySchedules = New Array;
	For Each Schedule In ScheduleStructure1.DetailedDailySchedules Do
		DetailedDailySchedules.Add(StructureToSchedule(Schedule));
	EndDo;
	Result.DetailedDailySchedules = DetailedDailySchedules;  
	Return Result;
	
EndFunction

// Compares two schedules with each other.
//
// Parameters:
//  Schedule1 - JobSchedule -  first schedule.
//  Schedule2 - JobSchedule -  second schedule.
//
// Returns:
//  Boolean - 
//
Function SchedulesAreIdentical(Val Schedule1, Val Schedule2) Export
	
	Return String(Schedule1) = String(Schedule2);
	
EndFunction

#EndRegion

#Region Internet

// Parses the URI string into its component parts and returns it as a structure.
// Based on RFC 3986.
//
// Parameters:
//  URIString1 - String - :
//                       
//
// Returns:
//  Structure - :
//   * Schema         - String -  schema from the URI.
//   * Login         - String -  the username from the URI.
//   * Password        - String -  password from the URI.
//   * ServerName    - String -  part <host>:<port> from the URI.
//   * Host          - String -  the host from the URI.
//   * Port          - String -  the port from the URI.
//   * PathAtServer - String -  the <path>part?<characteristic>#<anchor> from the URI.
//
Function URIStructure(Val URIString1) Export
	
	URIString1 = TrimAll(URIString1);
	
	// Schema
	Schema = "";
	Position = StrFind(URIString1, "://");
	If Position > 0 Then
		Schema = Lower(Left(URIString1, Position - 1));
		URIString1 = Mid(URIString1, Position + 3);
	EndIf;
	
	// 
	ConnectionString = URIString1;
	PathAtServer = "";
	Position = StrFind(ConnectionString, "/");
	If Position > 0 Then
		PathAtServer = Mid(ConnectionString, Position + 1);
		ConnectionString = Left(ConnectionString, Position - 1);
	EndIf;
	
	// 
	AuthorizationString = "";
	ServerName = ConnectionString;
	Position = StrFind(ConnectionString, "@", SearchDirection.FromEnd);
	If Position > 0 Then
		AuthorizationString = Left(ConnectionString, Position - 1);
		ServerName = Mid(ConnectionString, Position + 1);
	EndIf;
	
	// 
	Login = AuthorizationString;
	Password = "";
	Position = StrFind(AuthorizationString, ":");
	If Position > 0 Then
		Login = Left(AuthorizationString, Position - 1);
		Password = Mid(AuthorizationString, Position + 1);
	EndIf;
	
	// 
	Host = ServerName;
	Port = "";
	Position = StrFind(ServerName, ":");
	If Position > 0 Then
		Host = Left(ServerName, Position - 1);
		Port = Mid(ServerName, Position + 1);
		If Not StringFunctionsClientServer.OnlyNumbersInString(Port) Then
			Port = "";
		EndIf;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Schema", Schema);
	Result.Insert("Login", Login);
	Result.Insert("Password", Password);
	Result.Insert("ServerName", ServerName);
	Result.Insert("Host", Host);
	Result.Insert("Port", ?(IsBlankString(Port), Undefined, Number(Port)));
	Result.Insert("PathAtServer", PathAtServer);
	
	Return Result;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  ClientCertificate - FileClientCertificate
//                    - WindowsClientCertificate
//                    - Undefined - 
//  CertificationAuthorityCertificates - FileCertificationAuthorityCertificates
//                                   - WindowsCertificationAuthorityCertificates
//                                   - LinuxCertificationAuthorityCertificates
//                                   - OSCertificationAuthorityCertificates
//                                   - Undefined -  
//  ConnectType - String, Undefined - 
//  
// Returns:
//  OpenSSLSecureConnection,
//  CryptoProSecureConnection
//
Function NewSecureConnection(Val ClientCertificate = Undefined, Val CertificationAuthorityCertificates = Undefined, Val ConnectType = Undefined) Export

	If ValueIsFilled(ConnectType) Then
		ExpectedValues = New Array;
		ExpectedValues.Add("OpenSSL");
		ExpectedValues.Add("CryptoPro");
		CheckParameter("CommonClientServer.NewSecureConnection", "ConnectType", ConnectType, Type("String"),, ExpectedValues);
	EndIf;
	
#If WebClient Or MobileClient Then
	
	If ConnectType = "CryptoPro" Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Web client does not support secured %1 connection.';"),
				NStr("en = 'CryptoPro';"));
	EndIf;
	
	Return New OpenSSLSecureConnection; // 
#Else
	If CertificationAuthorityCertificates = Undefined Then
		VersionsOf1CEnterpriseForCertificateUsage = "8.3.22.2470; 8.3.23.2122; 8.3.24.1446";
	
		SystemInfo = New SystemInfo;
		VersionCurrentNumber = ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
		ShouldUseCertificatesFromCAs = CompareVersionsWithoutBuildNumber(VersionCurrentNumber, "8.3.21") > 0;
		
		If ShouldUseCertificatesFromCAs Then
			If CompareVersionsWithoutBuildNumber(VersionCurrentNumber, "8.3.25") < 0 Then
				For Each BuildNumber In StrSplit(VersionsOf1CEnterpriseForCertificateUsage, "; ", False) Do
					If StrStartsWith(BuildNumber, VersionCurrentNumber + ".") Then
						ShouldUseCertificatesFromCAs = 
							CompareVersions(SystemInfo.AppVersion, BuildNumber) >= 0;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If ShouldUseCertificatesFromCAs Then
				CertificationAuthorityCertificates = New OSCertificationAuthorityCertificates();
			EndIf;
		EndIf;
	EndIf;
	
	If ConnectType = "CryptoPro" Then
		SystemInfo = New SystemInfo;
		If CompareVersions(SystemInfo.AppVersion, "8.3.24.0") >= 0 Then
			CryptoProSecureConnection = Undefined;
			// 
			Execute("CryptoProSecureConnection = New CryptoProSecureConnection(ClientCertificate, CertificationAuthorityCertificates)");
			// 
			Return CryptoProSecureConnection;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'To establish a secure %1 connection, 1C:Enterprise version must be 8.3.24 or later. The current version is %2.';"),
				NStr("en = 'CryptoPro';"), SystemInfo.AppVersion);
		EndIf;
	EndIf;
	
	Return New OpenSSLSecureConnection(ClientCertificate, CertificationAuthorityCertificates);
#EndIf
	
EndFunction

#EndRegion

#Region DeviceParameters

// Returns a string representation of the device type used.
//
// Returns:
//   String - 
//
Function DeviceType() Export
	
	DisplayInformation = DeviceDisplayParameters();
	
	DPI    = DisplayInformation.DPI; // 
	Height = DisplayInformation.Height;
	Width = DisplayInformation.Width;
	
	DisplaySize = Sqrt((Height/DPI*Height/DPI)+(Width/DPI*Width/DPI));
	If DisplaySize > 16 Then
		Return "PersonalComputer";
	ElsIf DisplaySize >= ?(DPI > 310, 7.85, 9) Then
		Return "Tablet";
	ElsIf DisplaySize >= 4.9 Then
		Return "Phablet";
	Else
		Return "Phone";
	EndIf;
	
EndFunction

// Returns the screen parameters of the device being used.
//
// Returns:
//   Structure:
//     * Width  - Number -  screen width in pixels.
//     * Height  - Number -  screen height in pixels.
//     * DPI     - Number -  pixel density of the screen.
//     * Portrait - Boolean -  if the screen is in portrait orientation, then True, otherwise False.
//
Function DeviceDisplayParameters() Export
	
	DisplayParameters1 = New Structure;
	DisplayInformation = GetClientDisplaysInformation();
	
	Width = DisplayInformation[0].Width;
	Height = DisplayInformation[0].Height;
	
	DisplayParameters1.Insert("Width",  Width);
	DisplayParameters1.Insert("Height",  Height);
	DisplayParameters1.Insert("DPI",     DisplayInformation[0].DPI);
	DisplayParameters1.Insert("Portrait", Height > Width);
	
	Return DisplayParameters1;
	
EndFunction

#EndRegion

#Region CheckingTheValueType

// Returns a flag indicating that the passed value is, or is not, a number.
//
// Parameters:
//  ValueToCheck - String -  the value that is checked to match the number.
//
// Returns:
//   Boolean - 
//
Function IsNumber(Val ValueToCheck) Export 
	
	If ValueToCheck = "0" Then
		Return True;
	EndIf;
	
	NumberDetails = New TypeDescription("Number");
	
	Return NumberDetails.AdjustValue(ValueToCheck) <> 0;
	
EndFunction

#EndRegion

#Region CastingAValue

// Returns a string value to the date.
//
// Parameters:
//  Value - String -  a string value that is cast to a date.
//
// Returns:
//   Date - 
//
Function StringToDate(Val Value) Export 
	
	DateEmpty = Date(1, 1, 1);
	
	If Not ValueIsFilled(Value) Then 
		Return DateEmpty;
	EndIf;
	
	DateDetails = New TypeDescription("Date");
	Date = DateDetails.AdjustValue(Value);
	
	If TypeOf(Date) = Type("Date")
		And ValueIsFilled(Date) Then 
		
		Return Date;
	EndIf;
	
	#Region PreparingDateParts
	
	CharsCount = StrLen(Value);
	
	If CharsCount > 25 Then 
		Return DateEmpty;
	EndIf;
	
	PartsOfTheValue = New Array;
	PartOfTheValue = "";
	
	For CharacterNumber = 1 To CharsCount Do 
		
		Char = Mid(Value, CharacterNumber, 1);
		
		If IsNumber(Char) Then 
			
			PartOfTheValue = PartOfTheValue + Char;
			
		Else
			
			If Not IsBlankString(PartOfTheValue) Then 
				PartsOfTheValue.Add(PartOfTheValue);
			EndIf;
			
			PartOfTheValue = "";
			
		EndIf;
		
		If CharacterNumber = CharsCount
			And Not IsBlankString(PartOfTheValue) Then 
			
			PartsOfTheValue.Add(PartOfTheValue);
		EndIf;
		
	EndDo;
	
	If PartsOfTheValue.Count() < 3 Then 
		Return DateEmpty;
	EndIf;
	
	If PartsOfTheValue.Count() < 4 Then 
		PartsOfTheValue.Add("00");
	EndIf;
	
	If PartsOfTheValue.Count() < 5 Then 
		PartsOfTheValue.Add("00");
	EndIf;
	
	If PartsOfTheValue.Count() < 6 Then 
		PartsOfTheValue.Add("00");
	EndIf;
	
	#EndRegion
	
	// 
	NormalizedValue = PartsOfTheValue[2] + PartsOfTheValue[1] + PartsOfTheValue[0]
		+ PartsOfTheValue[3] + PartsOfTheValue[4] + PartsOfTheValue[5];
	
	Date = DateDetails.AdjustValue(NormalizedValue);
	
	If TypeOf(Date) = Type("Date")
		And ValueIsFilled(Date) Then 
		
		Return Date;
	EndIf;
	
	// 
	NormalizedValue = PartsOfTheValue[2] + PartsOfTheValue[0] + PartsOfTheValue[1]
		+ PartsOfTheValue[3] + PartsOfTheValue[4] + PartsOfTheValue[5];
	
	Date = DateDetails.AdjustValue(NormalizedValue);
	
	If TypeOf(Date) = Type("Date")
		And ValueIsFilled(Date) Then 
		
		Return Date;
	EndIf;
	
	Return DateEmpty;
	
EndFunction

#EndRegion

#Region ConvertDateForHTTP

// 
// See https://www.w3.org/Protocols/rfc2616/rfc2616
// 
// Parameters:
//  Date - Date
// 
// Returns:
//  String
//
// Example:
//  
//
Function HTTPDate(Val Date) Export
	
	WeekDays = StrSplit("Mon,Tue,Wed,Thu,Fri,Sat,Sun", ",");
	Months = StrSplit("Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec", ",");
	
	DateTemplate = "[WeekDay], [Day] [Month] [Year] [Hour]:[Minute]:[Second] GMT"; // 
	
	DateParameters = New Structure;
	DateParameters.Insert("WeekDay", WeekDays[WeekDay(Date)-1]);
	DateParameters.Insert("Day", Format(Day(Date), "ND=2; NLZ="));
	DateParameters.Insert("Month", Months[Month(Date)-1]);
	DateParameters.Insert("Year", Format(Year(Date), "ND=4; NLZ=; NG=0"));
	DateParameters.Insert("Hour", Format(Hour(Date), "ND=2; NZ=00; NLZ="));
	DateParameters.Insert("Minute", Format(Minute(Date), "ND=2; NZ=00; NLZ="));
	DateParameters.Insert("Second", Format(Second(Date), "ND=2; NZ=00; NLZ="));
	
	HTTPDate = StringFunctionsClientServer.InsertParametersIntoString(DateTemplate, DateParameters);
	
	Return HTTPDate;
	
EndFunction

// 
// See https://www.w3.org/Protocols/rfc2616/rfc2616
// 
// Parameters:
//  HTTPDateAsString - String
// 
// Returns:
//  Date
//
// Example:
//  
//
Function RFC1123Date(HTTPDateAsString) Export

	MonthsNames = "janfebmaraprmayjunjulaugsepoctnovdec";
	// rfc1123-date = wkday "," SP date1 SP time SP "GMT".
	FirstSpacePosition = StrFind(HTTPDateAsString, " ");
	SubstringDate = Mid(HTTPDateAsString,FirstSpacePosition + 1);
	SubstringTime = Mid(SubstringDate, 13);
	SubstringDate = Left(SubstringDate, 11);
	FirstSpacePosition = StrFind(SubstringTime, " ");
	SubstringTime = Left(SubstringTime,FirstSpacePosition - 1);
	// date1 = 2DIGIT SP month SP 4DIGIT.
	SubstringDay = Left(SubstringDate, 2);
	SubstringMonth = Format(Int(StrFind(MonthsNames,Lower(Mid(SubstringDate,4,3))) / 3)+1, "ND=2; NZ=00; NLZ=");
	SubstringYear = Mid(SubstringDate, 8);
	// time = 2DIGIT ":" 2DIGIT ":" 2DIGIT.
	SubstringHour = Left(SubstringTime, 2);
	SubstringMinute = Mid(SubstringTime, 4, 2);
	SubstringSecond = Right(SubstringTime, 2);
	
	Return Date(SubstringYear + SubstringMonth + SubstringDay + SubstringHour + SubstringMinute + SubstringSecond);
	
EndFunction

#EndRegion

#Region Other

// Removes one element of the conditional design, if it is a list of values.
// 
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance -  conditional design of a form element;
//  UserSettingID - String -  configuration ID;
//  Value - Arbitrary -    the value that you want to delete from the list of registration.
//
Procedure RemoveValueListConditionalAppearance(ConditionalAppearance, Val UserSettingID, 
	Val Value) Export
	
	For Each ConditionalAppearanceItem In ConditionalAppearance.Items Do
		If ConditionalAppearanceItem.UserSettingID = UserSettingID Then
			If ConditionalAppearanceItem.Filter.Items.Count() = 0 Then
				Return;
			EndIf;
			ItemFilterList = ConditionalAppearanceItem.Filter.Items[0];
			If ItemFilterList.RightValue = Undefined Then
				Return;
			EndIf;
			ListItem = ItemFilterList.RightValue.FindByValue(Value);
			If ListItem <> Undefined Then
				ItemFilterList.RightValue.Delete(ListItem);
			EndIf;
			Return;
		EndIf;
	EndDo;
	
EndProcedure

// Gets an array of values from the selected items in the list of values.
//
// Parameters:
//  List - ValueList -  a list of values from which an array of values will be formed;
// 
// Returns:
//  Array - 
//
Function MarkedItems(List) Export
	
	// 
	Array = New Array;
	
	For Each Item In List Do
		
		If Item.Check Then
			
			Array.Add(Item.Value);
			
		EndIf;
		
	EndDo;
	
	Return Array;
EndFunction

// Gets the ID (Getidentifier () method) of the value tree row for the specified value
// of the tree row field.
// Used for positioning the cursor in hierarchical lists.
//
// Parameters:
//  FieldName - String -  name of the column in the value tree that is being searched.
//  RowID - Number -  the ID of the value tree string obtained as a result of the search.
//  TreeItemsCollection - FormDataTreeItemCollection -  the collection to search in.
//  Composite - Arbitrary -  the field value you are looking for.
//  StopSearch - Boolean -  indicates that the search has stopped.
// 
Procedure GetTreeRowIDByFieldValue(FieldName, RowID, TreeItemsCollection, Composite, StopSearch) Export
	
	For Each TreeRow In TreeItemsCollection Do
		
		If StopSearch Then
			Return;
		EndIf;
		
		If TreeRow[FieldName] = Composite Then
			
			RowID = TreeRow.GetID();
			
			StopSearch = True;
			
			Return;
			
		EndIf;
		
		ItemsCollection = TreeRow.GetItems();
		
		If ItemsCollection.Count() > 0 Then
			
			GetTreeRowIDByFieldValue(FieldName, RowID, ItemsCollection, Composite, StopSearch);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
//
// Parameters:
//  Array - Array -  array of elements to subtract from;
//  SubtractionArray - Array -  array of elements to be subtracted.
// 
// Returns:
//  Array - 
//
Function ReduceArray(Array, SubtractionArray) Export
	
	Return ArraysDifference(Array, SubtractionArray);
	
EndFunction

// 

// Deprecated.
//  
// 
//
// Parameters:
//  MessageToUserText - String -  message text.
//  DataKey                 - AnyRef -  the object or key of the database record that this message refers to.
//  Field                       - String - 
//  DataPath                - String -  data path (the path to the requisite shape).
//  Cancel                      - Boolean -  the output parameter is always set to True.
//
// Example:
//
//  1. to display a message in the field of the managed form associated with the object's details:
//  General Assignationclientserver.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Politikunterricht",
//   "Object");
//
//  Alternative use case in the form of an object:
//  General purpose Clientserver.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Object.Politikunterricht");
//
//  2. to display a message next to the field of the managed form associated with the form's details:
//  General purpose Clientserver.Inform the user(
//   NSTR ("ru = 'Error message.'"), ,
//   "Markwesterby");
//
//  3. To display the message associated with the object information database:
//  ObservableCollection.Inform the user(
//   NSTR ("ru = 'Error message.'"), Object Of The Information Base, "Responsible",, Refusal);
//
//  4. to display the message by reference to the object of the information database:
//  General purpose Clientserver.Inform the user(
//   NSTR ("ru = 'Error message.'") The Link, ,,,, Failure);
//
//  Cases of incorrect use:
//   1. Passing the key Data and path Data parameters simultaneously.
//   2. Passing a different type of value in the key Data parameter.
//   3. Installation without field installation (and/or datapath).
//
Procedure MessageToUser(
		Val MessageToUserText,
		Val DataKey = Undefined,
		Val Field = "",
		Val DataPath = "",
		Cancel = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	IsObject = False;
	
#If Not ThinClient And Not WebClient And Not MobileClient Then
	If DataKey <> Undefined
	   And XMLTypeOf(DataKey) <> Undefined Then
		ValueTypeAsString = XMLTypeOf(DataKey).TypeName;
		IsObject = StrFind(ValueTypeAsString, "Object.") > 0;
	EndIf;
#EndIf
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If Not IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
		
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// Deprecated.
//  
//  
// 
//
// Parameters:
//  Source - Structure
//           - Map
//           - Array
//           - ValueList
//           - ValueTable -  
//             
//
// Returns:
//  Structure, Map, Array, ValueList, ValueTable - 
//
Function CopyRecursive(Source) Export
	
	Var Receiver;
	
	SourceType = TypeOf(Source);
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If SourceType = Type("ValueTable") Then
		Return Source.Copy();
	EndIf;
#EndIf	
	If SourceType = Type("Structure") Then
		Receiver = CopyStructure(Source);
	ElsIf SourceType = Type("Map") Then
		Receiver = CopyMap(Source);
	ElsIf SourceType = Type("Array") Then
		Receiver = CopyArray(Source);
	ElsIf SourceType = Type("ValueList") Then
		Receiver = CopyValueList(Source);
	Else
		Receiver = Source;
	EndIf;
	
	Return Receiver;
	
EndFunction

// Deprecated.
//  
// 
// 
//
// Parameters:
//  SourceStructure - Structure -  the structure to copy.
// 
// Returns:
//  Structure - 
//
Function CopyStructure(SourceStructure) Export
	
	ResultingStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultingStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultingStructure;
	
EndFunction

// Deprecated.
// 
// 
// 
//
// Parameters:
//  SourceMap - Map -  the match to get a copy of.
// 
// Returns:
//  Map - 
//
Function CopyMap(SourceMap) Export
	
	ResultingMap = New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultingMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultingMap;

EndFunction

// Deprecated.
// 
// 
// 
//
// Parameters:
//  SourceArray1 - Array -  array to get a copy of.
// 
// Returns:
//  Array - 
//
Function CopyArray(SourceArray1) Export
	
	ResultingArray = New Array;
	
	For Each Item In SourceArray1 Do
		ResultingArray.Add(CopyRecursive(Item));
	EndDo;
	
	Return ResultingArray;
	
EndFunction

// Deprecated.
// 
// 
// 
//
// Parameters:
//  SourceList - ValueList -  list of values to get a copy of.
// 
// Returns:
//  ValueList - 
//
Function CopyValueList(SourceList) Export
	
	ResultingList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultingList.Add(
			CopyRecursive(ListItem.Value), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultingList;
	
EndFunction

// Deprecated.
// 
// 
// 
//
// Parameters:
//  SourceCollection - See SupplementTable.SourceTable1
//  DestinationCollection - See SupplementTable.DestinationTable
// 
Procedure FillPropertyCollection(SourceCollection, DestinationCollection) Export
	
	For Each Item In SourceCollection Do
		FillPropertyValues(DestinationCollection.Add(), Item);
	EndDo;
	
EndProcedure

// Deprecated. 
// 
// 
// 
// 
// Parameters:
//  Parameters - Structure - 
//                          
//                          :
//
//    * InfobaseOperatingMode             - Number -  version of the information base: 0 - file; 1-
//                                                            client-server;
//    * InfobaseDirectory                   - String -  directory of the information base for the file mode of operation;
//    * NameOf1CEnterpriseServer                     - String -  server1c name:Companies;
//    * NameOfInfobaseOn1CEnterpriseServer - String -  name of the information base on server1c:Companies;
//    * OperatingSystemAuthentication           - Boolean -  indicates whether the operating system is authenticated when creating
//                                                             an external connection to the database;
//    * UserName                             - String -  name of the database user;
//    * UserPassword                          - String -  password of the database user.
// 
//  ErrorMessageString - String -  if an error occurs during the external connection setup process,
//                                     a detailed description of the error is placed in this parameter.
//  AddInAttachmentError - Boolean -  (return parameter) is set to True if there was an error during connection.
//
// Returns:
//  COMObject, Undefined - 
//    
//
Function EstablishExternalConnection(Parameters, ErrorMessageString = "", AddInAttachmentError = False) Export
	Result = EstablishExternalConnectionWithInfobase(Parameters);
	AddInAttachmentError = Result.AddInAttachmentError;
	ErrorMessageString     = Result.DetailedErrorDetails;
	
	Return Result.Join;
EndFunction

// Deprecated. 
//  
// 
// 
// 
// Parameters:
//  Parameters - Structure - 
//                          
//                          :
//
//   * InfobaseOperatingMode             - Number  -  version of the information base: 0 - file; 1-
//                                                            client-server;
//   * InfobaseDirectory                   - String -  directory of the information base for the file mode of operation;
//   * NameOf1CEnterpriseServer                     - String -  server1c name:Companies;
//   * NameOfInfobaseOn1CEnterpriseServer - String -  name of the information base on server1c:Companies;
//   * OperatingSystemAuthentication           - Boolean -  indicates whether the operating system is authenticated when creating
//                                                            an external connection to the database;
//   * UserName                             - String -  name of the database user;
//   * UserPassword                          - String -  password of the database user.
// 
// Returns:
//  Structure:
//    * Join                  - COMObject
//                                  - Undefined - 
//                                    
//    * BriefErrorDetails       - String -  short description of the error;
//    * DetailedErrorDetails     - String -  detailed description of the error;
//    * AddInAttachmentError - Boolean -  COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(Parameters) Export
	
	Result = New Structure;
	Result.Insert("Join");
	Result.Insert("BriefErrorDetails", "");
	Result.Insert("DetailedErrorDetails", "");
	Result.Insert("AddInAttachmentError", False);
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		ConnectionNotAvailable = Common.IsLinuxServer();
		BriefErrorDetails = NStr("en = 'Servers on Linux do not support direct infobase connections.';");
	#Else
		ConnectionNotAvailable = IsLinuxClient() Or IsOSXClient() Or IsMobileClient();
		BriefErrorDetails = NStr("en = 'Only Windows clients support direct infobase connections.';");
	#EndIf
	
	If ConnectionNotAvailable Then
		Result.Join = Undefined;
		Result.BriefErrorDetails = BriefErrorDetails;
		Result.DetailedErrorDetails = BriefErrorDetails;
		Return Result;
	EndIf;
	
	#If Not MobileClient Then
		Try
			COMConnector = New COMObject(COMConnectorName()); // "V83.COMConnector"
		Except
			Information = ErrorInfo();
			ErrorMessageString = NStr("en = 'Failed to connect to another app: %1';");
			
			Result.AddInAttachmentError = True;
			Result.DetailedErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, ErrorProcessing.DetailErrorDescription(Information));
			Result.BriefErrorDetails = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, ErrorProcessing.BriefErrorDescription(Information));
			
			Return Result;
		EndTry;
	
		FileRunMode = Parameters.InfobaseOperatingMode = 0;
		
		// 
		FillingCheckError = False;
		If FileRunMode Then
			
			If IsBlankString(Parameters.InfobaseDirectory) Then
				ErrorMessageString = NStr("en = 'The infobase directory location is not specified.';");
				FillingCheckError = True;
			EndIf;
			
		Else
			
			If IsBlankString(Parameters.NameOf1CEnterpriseServer) Or IsBlankString(Parameters.NameOfInfobaseOn1CEnterpriseServer) Then
				ErrorMessageString = NStr("en = 'Required connection parameters are not specified: server name and infobase name.';");
				FillingCheckError = True;
			EndIf;
			
		EndIf;
		
		If FillingCheckError Then
			
			Result.DetailedErrorDetails = ErrorMessageString;
			Result.BriefErrorDetails   = ErrorMessageString;
			Return Result;
			
		EndIf;
		
		// 
		ConnectionStringPattern = "[InfobaseString][AuthenticationString]";
		
		If FileRunMode Then
			InfobaseString = "File = ""&InfobaseDirectory""";
			InfobaseString = StrReplace(InfobaseString, "&InfobaseDirectory", Parameters.InfobaseDirectory);
		Else
			InfobaseString = "Srvr = ""&NameOf1CEnterpriseServer""; Ref = ""&NameOfInfobaseOn1CEnterpriseServer""";
			InfobaseString = StrReplace(InfobaseString, "&NameOf1CEnterpriseServer",                     Parameters.NameOf1CEnterpriseServer);
			InfobaseString = StrReplace(InfobaseString, "&NameOfInfobaseOn1CEnterpriseServer", Parameters.NameOfInfobaseOn1CEnterpriseServer);
		EndIf;
		
		If Parameters.OperatingSystemAuthentication Then
			AuthenticationString = "";
		Else
			
			If StrFind(Parameters.UserName, """") Then
				Parameters.UserName = StrReplace(Parameters.UserName, """", """""");
			EndIf;
			
			If StrFind(Parameters.UserPassword, """") Then
				Parameters.UserPassword = StrReplace(Parameters.UserPassword, """", """""");
			EndIf;
			
			AuthenticationString = "; Usr = ""&UserName""; Pwd = ""&UserPassword""";
			AuthenticationString = StrReplace(AuthenticationString, "&UserName",    Parameters.UserName);
			AuthenticationString = StrReplace(AuthenticationString, "&UserPassword", Parameters.UserPassword);
		EndIf;
		
		ConnectionString = StrReplace(ConnectionStringPattern, "[InfobaseString]", InfobaseString);
		ConnectionString = StrReplace(ConnectionString, "[AuthenticationString]", AuthenticationString);
		
		Try
			Result.Join = COMConnector.Connect(ConnectionString);
		Except
			Information = ErrorInfo();
			ErrorMessageString = NStr("en = 'Failed to connect to another app: %1';");
			
			Result.AddInAttachmentError = True;
			Result.DetailedErrorDetails     = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, ErrorProcessing.DetailErrorDescription(Information));
			Result.BriefErrorDetails       = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, ErrorProcessing.BriefErrorDescription(Information));
		EndTry;
	#EndIf
	
	Return Result;
	
EndFunction

// Deprecated. 
// 
// 
// 
//
// Returns:
//  Boolean - 
//
Function ClientConnectedOverWebServer() Export
	
#If Server Or ThickClientOrdinaryApplication Then
	SetPrivilegedMode(True);
	
	InfoBaseConnectionString = StandardSubsystemsServer.ClientParametersAtServer().Get("InfoBaseConnectionString");
	
	If InfoBaseConnectionString = Undefined Then
		Return False; // 
	EndIf;
#Else
	InfoBaseConnectionString = InfoBaseConnectionString();
#EndIf
	
	Return StrFind(Upper(InfoBaseConnectionString), "WS=") = 1;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//  Boolean - 
//
Function IsWindowsClient() Export
	
#If Server Or ThickClientOrdinaryApplication Then
	SetPrivilegedMode(True);
	
	IsWindowsClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsWindowsClient");
	
	If IsWindowsClient = Undefined Then
		Return False; // 
	EndIf;
#Else
	SystemInfo = New SystemInfo;
	
	IsWindowsClient = SystemInfo.PlatformType = PlatformType.Windows_x86
	             Or SystemInfo.PlatformType = PlatformType.Windows_x86_64;
#EndIf
	
	Return IsWindowsClient;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//  Boolean - 
//
Function IsOSXClient() Export
	
#If Server Or ThickClientOrdinaryApplication Then
	SetPrivilegedMode(True);
	
	IsMacOSClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsMacOSClient");
	
	If IsMacOSClient = Undefined Then
		Return False; // 
	EndIf;
#Else
	SystemInfo = New SystemInfo;
	
	IsMacOSClient = SystemInfo.PlatformType = PlatformType.MacOS_x86
	             Or SystemInfo.PlatformType = PlatformType.MacOS_x86_64;
#EndIf
	
	Return IsMacOSClient;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//  Boolean - 
//
Function IsLinuxClient() Export
	
#If Server Or ThickClientOrdinaryApplication Then
	SetPrivilegedMode(True);
	
	IsLinuxClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsLinuxClient");
	
	If IsLinuxClient = Undefined Then
		Return False; // 
	EndIf;
#Else
	SystemInfo = New SystemInfo;
	
	IsLinuxClient = SystemInfo.PlatformType = PlatformType.Linux_x86
		Or SystemInfo.PlatformType = PlatformType.Linux_x86_64;
#EndIf

#If Not MobileClient Then
	SystemInfo = New SystemInfo;
	IsLinuxClient = IsLinuxClient
		Or CompareVersions(SystemInfo.AppVersion, "8.3.22.1923") >= 0
		And (SystemInfo.PlatformType = PlatformType["Linux_ARM64"]
		Or SystemInfo.PlatformType = PlatformType["Linux_E2K"]);
#EndIf
	
	Return IsLinuxClient;
	
EndFunction

// Deprecated. 
// 
// 
//
// Returns:
//  Boolean - 
//
Function IsWebClient() Export
	
#If WebClient Then
	Return True;
#ElsIf Server Or ThickClientOrdinaryApplication Then
	SetPrivilegedMode(True);
	
	IsWebClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsWebClient");
	
	If IsWebClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsWebClient;
#Else
	Return False;
#EndIf
	
EndFunction

// Deprecated.
// 
// 
//
// Returns:
//  Boolean - 
//
Function IsMacOSWebClient() Export
	
#If WebClient Then
	Return CommonClient.IsMacOSClient();
#ElsIf Server Or ThickClientOrdinaryApplication Then
	Return IsOSXClient() And IsWebClient();
#Else
	Return False;
#EndIf
	
EndFunction

// Deprecated. 
// 
// 
//
// Returns:
//  Boolean - 
//
Function IsMobileClient() Export
	
#If MobileClient Then
	Return True;
#ElsIf Server Or ThickClientOrdinaryApplication Then
	SetPrivilegedMode(True);
	
	IsMobileClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsMobileClient");
	
	If IsMobileClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsMobileClient;
#Else
	Return False;
#EndIf
	
EndFunction

// Deprecated. 
//  
// 
//
// Returns:
//  Number - 
//  
//
Function RAMAvailableForClientApplication() Export
	
#If Server Or ThickClientOrdinaryApplication Or  ExternalConnection Then
	AvailableMemorySize = StandardSubsystemsServer.ClientParametersAtServer().Get("RAM");
#Else
	SystemInfo = New  SystemInfo;
	AvailableMemorySize = Round(SystemInfo.RAM / 1024,  1);
#EndIf
	
	Return AvailableMemorySize;
	
EndFunction

// Deprecated.
// 
//
// Returns:
//  Boolean - 
//
Function DebugMode() Export
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	ApplicationStartupParameter = StandardSubsystemsServer.ClientParametersAtServer(False).Get("LaunchParameter");
#Else
	ApplicationStartupParameter = LaunchParameter;
#EndIf
	
	Return StrFind(ApplicationStartupParameter, "DebugMode") > 0;
EndFunction

// Deprecated.
// 
//
// Returns:
//  String - 
//
Function DefaultLanguageCode() Export

	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		Return Common.DefaultLanguageCode();
	#Else
		Return CommonClient.DefaultLanguageCode();
	#EndIf

EndFunction

// Deprecated. 
//  
// 
//
// Parameters:
//  LocalDate - Date -  date in the session's time zone.
// 
// Returns:
//   String - 
//
Function LocalDatePresentationWithOffset(LocalDate) Export
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		Offset = StandardTimeOffset(SessionTimeZone());
	#Else
		Offset = StandardSubsystemsClient.ClientParameter("StandardTimeOffset");
	#EndIf
	OffsetPresentation = "Z";
	If Offset > 0 Then
		OffsetPresentation = "+";
	ElsIf Offset < 0 Then
		OffsetPresentation = "-";
		Offset = -Offset;
	EndIf;
	If Offset <> 0 Then
		OffsetPresentation = OffsetPresentation + Format('00010101' + Offset, "DF=HH:mm");
	EndIf;
	
	Return Format(LocalDate, "DF=yyyy-MM-ddTHH:mm:ss; DE=0001-01-01T00:00:00") + OffsetPresentation;
EndFunction

// Deprecated. 
//  
// 
// 
//   
//   
//   
//   
// 
// 
//
// Parameters:
//   FullPredefinedItemName - String - 
//     
//     :
//       
//       
//       
//
// Returns: 
//   AnyRef - 
//   
//
Function PredefinedItem(FullPredefinedItemName) Export
	
	// 
	//   
	//  
	//  
	
	If StrEndsWith(Upper(FullPredefinedItemName), ".EMPTYREF")
		Or StrStartsWith(Upper(FullPredefinedItemName), "ENUM.")
		Or StrStartsWith(Upper(FullPredefinedItemName), "BUSINESSPROCESS.") Then
		
		Return PredefinedValue(FullPredefinedItemName);
	EndIf;
	
	// 
	FullNameParts1 = StrSplit(FullPredefinedItemName, ".");
	If FullNameParts1.Count() <> 3 Then 
		Raise CommonInternalClientServer.PredefinedValueNotFoundErrorText(
			FullPredefinedItemName);
	EndIf;
	
	FullMetadataObjectName = Upper(FullNameParts1[0] + "." + FullNameParts1[1]);
	PredefinedItemName = FullNameParts1[2];
	
	// 
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	PredefinedValues = StandardSubsystemsCached.RefsByPredefinedItemsNames(FullMetadataObjectName);
#Else
	PredefinedValues = StandardSubsystemsClientCached.RefsByPredefinedItemsNames(FullMetadataObjectName);
#EndIf

	// 
	If PredefinedValues = Undefined Then 
		Raise CommonInternalClientServer.PredefinedValueNotFoundErrorText(
			FullPredefinedItemName);
	EndIf;

	// 
	Result = PredefinedValues.Get(PredefinedItemName);
	
	// 
	If Result = Undefined Then 
		Raise CommonInternalClientServer.PredefinedValueNotFoundErrorText(
			FullPredefinedItemName);
	EndIf;
	
	// 
	If Result = Null Then 
		Return Undefined;
	EndIf;
	
	Return Result;
	
EndFunction

// Deprecated. 
// 
// 
//
// Returns:
//  Structure:
//   * CurrentDirectory              - String -  sets the current folder of the application to launch.
//   * WaitForCompletion         - Boolean -  wait for the running application to finish before continuing.
//   * GetOutputStream         - Boolean -  the result sent to the stdout stream,
//                                            if wait for Completion is not specified, is ignored.
//   * GetErrorStream         - Boolean -  errors sent to the stderr stream,
//                                            if wait for Completion is not specified, are ignored.
//   * ExecuteWithFullRights - Boolean - :
//                                            
//                                            
//                                            
//                                            
//   * Encoding                   - String -  the encoding code that is set before the batch operation is performed.
//                                            In Linux and macOS it is ignored.
//
Function ApplicationStartupParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("CurrentDirectory", "");
	Parameters.Insert("WaitForCompletion", False);
	Parameters.Insert("GetOutputStream", False);
	Parameters.Insert("GetErrorStream", False);
	Parameters.Insert("ExecuteWithFullRights", False);
	Parameters.Insert("Encoding", "");
	
	Return Parameters;
	
EndFunction

// Deprecated.
// 
//  
//
// Parameters:
//  StartupCommand - String
//                 - Array - 
//      
//      
//  ApplicationStartupParameters - See ApplicationStartupParameters
//
// Returns:
//  Structure - :
//      
//      
//      
//
// Example:
//	General purpose clientserver.Run the program ("calc");
//	
//	Program Start Parameters = General Purpose Clientserver.Parameterizedproperty();
//	Program startup parametres.Fulfill The Highest Rights = True;
//	General purpose clientserver.Run The Program("C:\Program Files\1cv8\common\1cestart.exe", 
//		Parameterizedproperty);
//	
//	Program Start Parameters = General Purpose Clientserver.Parameterizedproperty();
//	Program startup parametres.Wait For Completion = True;
//	The Result = ObservableCollection.Run the program ("ping 127.0.0.1-n 5", program startup Parametersreferences);
//
Function StartApplication(Val StartupCommand, ApplicationStartupParameters = Undefined) Export 
	
#If WebClient Or MobileClient Then
	Raise NStr("en = 'Cannot run app in the web client.';");
#Else
	
	CommandString = CommonInternalClientServer.SafeCommandString(StartupCommand);
	
	If ApplicationStartupParameters = Undefined Then 
		ApplicationStartupParameters = ApplicationStartupParameters();
	EndIf;
	
	CurrentDirectory              = ApplicationStartupParameters.CurrentDirectory;
	WaitForCompletion         = ApplicationStartupParameters.WaitForCompletion;
	GetOutputStream         = ApplicationStartupParameters.GetOutputStream;
	GetErrorStream         = ApplicationStartupParameters.GetErrorStream;
	ExecuteWithFullRights = ApplicationStartupParameters.ExecuteWithFullRights;
	Encoding                   = ApplicationStartupParameters.Encoding;
	
	If ExecuteWithFullRights Then 
#If ExternalConnection Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Invalid value of the %1 parameter.
			|Elevating system privileges from an external connection is not supported.';"),
			"ApplicationStartupParameters.ExecuteWithFullRights");
#EndIf
		
#If Server Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter.
			|Elevating system privileges is not supported on the server.';"),
			"ApplicationStartupParameters.ExecuteWithFullRights");
#EndIf
		
	EndIf;
	
	SystemInfo = New SystemInfo();
	If (SystemInfo.PlatformType = PlatformType.Windows_x86) 
		Or (SystemInfo.PlatformType = PlatformType.Windows_x86_64) Then
	
		If Not IsBlankString(Encoding) Then
			CommandString = "chcp " + Encoding + " | " + CommandString;
		EndIf;
	
	EndIf;
	
	If WaitForCompletion Then 
		
		If GetOutputStream Then 
			OutputStreamFile = GetTempFileName("stdout.tmp");
			CommandString = CommandString + " > """ + OutputStreamFile + """";
		EndIf;
		
		If GetErrorStream Then 
			ErrorStreamFile = GetTempFileName("stderr.tmp");
			CommandString = CommandString + " 2>""" + ErrorStreamFile + """";
		EndIf;
		
	EndIf;
	
	ReturnCode = Undefined;
	
	If (SystemInfo.PlatformType = PlatformType.Windows_x86)
		Or (SystemInfo.PlatformType = PlatformType.Windows_x86_64) Then
		
		// 
		If Not IsBlankString(CurrentDirectory) Then 
			CommandString = "cd /D """ + CurrentDirectory + """ && " + CommandString;
		EndIf;
		
		// 
		CommandString = "cmd /S /C "" " + CommandString + " """;
		
#If Server Then
		
		If Common.FileInfobase() Then
			// 
			Shell = New COMObject("Wscript.Shell");
			ReturnCode = Shell.Run(CommandString, 0, WaitForCompletion);
			Shell = Undefined;
		Else 
			RunApp(CommandString,, WaitForCompletion, ReturnCode);
		EndIf;
		
#Else
		
		If ExecuteWithFullRights Then
			
			If WaitForCompletion Then
				Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
					"en = 'Cannot set the following parameters simultaneously:
					| - %1 and
					| - %2
					|Processes started by administrator
					|cannot be monitored on behalf of user in this operating system.';"),
					"ApplicationStartupParameters.WaitForCompletion",
					"ApplicationStartupParameters.ExecuteWithFullRights");
			EndIf;
			
			Shell = New COMObject("Shell.Application");
			// 
			Shell.ShellExecute("cmd", "/c """ + CommandString + """",, "runas", 0);
			Shell = Undefined;
			
		Else 
			Shell = New COMObject("Wscript.Shell");
			ReturnCode = Shell.Run(CommandString, 0, WaitForCompletion);
			Shell = Undefined;
		EndIf;
#EndIf
		
	ElsIf (SystemInfo.PlatformType = PlatformType.Linux_x86) 
		Or (SystemInfo.PlatformType = PlatformType.Linux_x86_64)
		Or CompareVersions(SystemInfo.AppVersion, "8.3.22.1923") >= 0
			And (SystemInfo.PlatformType = PlatformType["Linux_ARM64"]
			Or SystemInfo.PlatformType = PlatformType["Linux_E2K"]) Then
		
		If ExecuteWithFullRights Then
			
			CommandTemplate = "pkexec env DISPLAY=[DISPLAY] XAUTHORITY=[XAUTHORITY] [CommandString]";
			
			TemplateParameters = New Structure;
			TemplateParameters.Insert("CommandString", CommandString);
			
			SubprogramStartupParameters = ApplicationStartupParameters();
			SubprogramStartupParameters.WaitForCompletion = True;
			SubprogramStartupParameters.GetOutputStream = True;
			
			Result = StartApplication("echo $DISPLAY", SubprogramStartupParameters);
			TemplateParameters.Insert("DISPLAY", Result.OutputStream);
			
			Result = StartApplication("echo $XAUTHORITY", SubprogramStartupParameters);
			TemplateParameters.Insert("XAUTHORITY", Result.OutputStream);
			
			CommandString = StringFunctionsClientServer.InsertParametersIntoString(CommandTemplate, TemplateParameters);
			WaitForCompletion = True;
			
		EndIf;
		
		RunApp(CommandString, CurrentDirectory, WaitForCompletion, ReturnCode);
		
	Else
		
		// 
		// 
		RunApp(CommandString, CurrentDirectory, WaitForCompletion, ReturnCode);
		
	EndIf;
	
	// 
	If ReturnCode = Undefined Then 
		ReturnCode = 0;
	EndIf;
	
	OutputStream = "";
	ErrorStream = "";
	
	If WaitForCompletion Then 
		
		If GetOutputStream Then
			
			FileInfo3 = New File(OutputStreamFile);
			If FileInfo3.Exists() Then 
				OutputStreamReader = New TextReader(OutputStreamFile, StandardStreamEncoding()); 
				OutputStream = OutputStreamReader.Read();
				OutputStreamReader.Close();
				DeleteTempFile(OutputStreamFile);
			EndIf;
			
			If OutputStream = Undefined Then 
				OutputStream = "";
			EndIf;
			
		EndIf;
		
		If GetErrorStream Then 
			
			FileInfo3 = New File(ErrorStreamFile);
			If FileInfo3.Exists() Then 
				ErrorStreamReader = New TextReader(ErrorStreamFile, StandardStreamEncoding());
				ErrorStream = ErrorStreamReader.Read();
				ErrorStreamReader.Close();
				DeleteTempFile(ErrorStreamFile);
			EndIf;
			
			If ErrorStream = Undefined Then 
				ErrorStream = "";
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("ReturnCode", ReturnCode);
	Result.Insert("OutputStream", OutputStream);
	Result.Insert("ErrorStream", ErrorStream);
	
	Return Result;
	
#EndIf
	
EndFunction

// Deprecated.
// 
// 
// 
//
// Parameters:
//  URL - String -  url of the resource to diagnose.
//
// Returns:
//  Structure - :
//      
//      
//
// Example:
//	
//	
//	
//	
//	
//
Function ConnectionDiagnostics(URL) Export
	
#If WebClient Then
	Raise NStr("en = 'The connection diagnostics are unavailable in the web client.';");
#Else
	
	LongDesc = New Array;
	LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Accessing URL: %1.';"), 
		URL));
	LongDesc.Add(DiagnosticsLocationPresentation());
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.DataSeparationEnabled() Then
		LongDesc.Add(
			NStr("en = 'Please contact the administrator.';"));
		
		ErrorDescription = StrConcat(LongDesc, Chars.LF);
		
		Result = New Structure;
		Result.Insert("ErrorDescription", ErrorDescription);
		Result.Insert("DiagnosticsLog", "");
		
		Return Result;
	EndIf;
#EndIf
	
	Log = New Array;
	Log.Add(
		NStr("en = 'Diagnostics log:
		           |Server availability test.
		           |See the error description in the next log record.';"));
	Log.Add();
	
	ProxyConnection = False;
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownloadClientServer = 
			Common.CommonModule("GetFilesFromInternetClientServer");
		ProxySettingsState = ModuleNetworkDownloadClientServer.ProxySettingsState();
		
		ProxyConnection = ProxySettingsState.ProxyConnection;
		
		Log.Add(ProxySettingsState.Presentation);
	EndIf;
#Else
	If CommonClient.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownloadClientServer = 
			CommonClient.CommonModule("GetFilesFromInternetClientServer");
		ProxySettingsState = ModuleNetworkDownloadClientServer.ProxySettingsState();
		
		ProxyConnection = ProxySettingsState.ProxyConnection;
		
		Log.Add(ProxySettingsState.Presentation);
	EndIf;
#EndIf
	
	If ProxyConnection Then 
		
		LongDesc.Add(
			NStr("en = 'Connection diagnostics are not performed because a proxy server is configured.
			           |Please contact the administrator.';"));
		
	Else 
		
		RefStructure = URIStructure(URL);
		ResourceServerAddress = RefStructure.Host;
		VerificationServerAddress = "google.com";
		
		ResourceAvailabilityResult = CheckServerAvailability(ResourceServerAddress);
		
		Log.Add();
		Log.Add("1) " + ResourceAvailabilityResult.DiagnosticsLog);
		
		If ResourceAvailabilityResult.Available Then 
			
			LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Attempted to access a resource that does not exist on server %1,
				           |or some issues occurred on the remote server.';"),
				ResourceServerAddress));
			
		Else 
			
			VerificationResult = CheckServerAvailability(VerificationServerAddress);
			Log.Add("2) " + VerificationResult.DiagnosticsLog);
			
			If Not VerificationResult.Available Then
				
				LongDesc.Add(
					NStr("en = 'No Internet access. Possible reasons:
					           |- Computer is not connected to the Internet.
					           | - Internet provider issues.
					           |- Access blocked by firewall, antivirus, or another software.';"));
				
			Else 
				
				LongDesc.Add(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Server %1 is currently unavailable. Possible reasons:
					           |- Internet provider issues.
					           |- Access blocked by firewall, antivirus, or other software.
					           |- Server is disabled or undergoing maintenance.';"),
					ResourceServerAddress));
				
				TraceLog = ServerRouteTraceLog(ResourceServerAddress);
				Log.Add("3) " + TraceLog);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	ErrorDescription = StrConcat(LongDesc, Chars.LF);
	
	Log.Insert(0);
	Log.Insert(0, ErrorDescription);
	
	DiagnosticsLog = StrConcat(Log, Chars.LF);
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	WriteLogEvent(
		NStr("en = 'Connection diagnostics';", DefaultLanguageCode()),
		EventLogLevel.Error,,, DiagnosticsLog);
#Else
	EventLogClient.AddMessageForEventLog(
		NStr("en = 'Connection diagnostics';", DefaultLanguageCode()),
		"Error", DiagnosticsLog,, True);
#EndIf
	
	Result = New Structure;
	Result.Insert("ErrorDescription", ErrorDescription);
	Result.Insert("DiagnosticsLog", DiagnosticsLog);
	
	Return Result;
	
#EndIf
	
EndFunction

// 

#EndRegion

#EndRegion

#Region Internal

// 
// 
//
// Parameters:
//  ErrorInfo - ErrorInfo - 
//  Title          - String - 
//
//  ErrorAtClient - Boolean - 
//      
//      
//      
//      
//      
//
// Returns:
//  Structure:
//   * Text - String - 
//   * Category - ErrorCategory - 
//               - Undefined - 
//                   
//
Function ExceptionClarification(ErrorInfo, Title = "", ErrorAtClient = False) Export
	
	Category = ErrorProcessing.ErrorCategoryForUser(ErrorInfo);
	If Category = ErrorCategory.OtherError Then
		Category = ErrorCategory.ConfigurationError;
	ElsIf Category = ErrorCategory.ExceptionRaisedFromScript Then
		Category = Undefined;
	EndIf;
	
	If Not ErrorAtClient Then
		If Category = ErrorCategory.LocalFileAccessError
		 Or Category = ErrorCategory.PrinterError Then
			Category = ErrorCategory.ConfigurationError;
		EndIf;
	EndIf;
	
	ErrorText = "";
	CurrentReason = ErrorInfo;
	LongDesc = "";
	While CurrentReason <> Undefined Do
		If CurrentReason.IsErrorOfCategory(
				ErrorCategory.ExceptionRaisedFromScript, False) Then
			LongDesc = CurrentReason.Description;
			Break;
		EndIf;
		CurrentReason = CurrentReason.Cause;
	EndDo;
	If Not ValueIsFilled(LongDesc) Then
		LongDesc = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	EndIf;
	If ValueIsFilled(Title) Then
		ErrorText = Title + Chars.LF + LongDesc;
	Else
		ErrorText = LongDesc;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Text", ReplaceProhibitedXMLChars(ErrorText));
	Result.Insert("Category", Category);
	
	Return Result;
	
EndFunction

// 
//
// Parameters:
//  Value1 - Arbitrary -  any value.
//  Value2 - Arbitrary
//  Value3 - Arbitrary
//  Value4 - Arbitrary
//
// Returns:
//  Array
//  
// Example:
//   
//
Function ArrayOfValues(Val Value1, Val Value2 = Undefined, Val Value3 = Undefined, 
	Val Value4 = Undefined) Export
	
	Result = New Array;
	Result.Add(Value1);
	If Value2 <> Undefined Then
		Result.Add(Value2);
	EndIf;
	If Value3 <> Undefined Then
		Result.Add(Value3);
	EndIf;
	If Value4 <> Undefined Then
		Result.Add(Value4);
	EndIf;
	Return Result;
	
EndFunction

Function NameMeetPropertyNamingRequirements(Name) Export
	Letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"; // 
	Digits = "1234567890"; // @Non-NLS
	
	If Name = "" Or StrFind(Letters + "_", Upper(Left(Name, 1))) = 0 Then
		Return False;
	EndIf;
	
	Return StrSplit(Upper(Name), Letters + Digits + "_", False).Count() = 0;
EndFunction

#EndRegion

#Region Private

#Region Data

#Region ValueListsAreEqual

// 
// 
// Parameters:
//  Collection - 
//  ShouldCompareValuesCount - Boolean
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - Arbitrary - 
//   * Value - Number, Boolean - 
//
Function CollectionIntoMap(Collection, ShouldCompareValuesCount)
	
	CollectionTypeList = TypeOf(Collection) = Type("ValueList");
	Result = New Map;
	If Not ShouldCompareValuesCount Then
		For Each CollectionItem In Collection Do
			If CollectionTypeList Then
				Result.Insert(CollectionItem.Value, True);
			Else
				Result.Insert(CollectionItem, True);
			EndIf;
		EndDo;
	Else
		For Each CollectionItem In Collection Do
			
			If CollectionTypeList Then
				Value = CollectionItem.Value;
			Else
				Value = CollectionItem;
			EndIf;
			
			Count = Result[Value];
			If Count <> Undefined Then
				Count = Count + 1;
			Else	
				Count = 1;
			EndIf;
			
			Result[Value] = Count;
		EndDo;
	EndIf;
	Return Result;
	
EndFunction

#EndRegion

#Region CheckParameter

Function ExpectedTypeValue(Value, ExpectedTypes)
	
	ValueType = TypeOf(Value);
	If TypeOf(ExpectedTypes) = Type("TypeDescription") Then
		Return ExpectedTypes.Types().Find(ValueType) <> Undefined;
	ElsIf TypeOf(ExpectedTypes) = Type("Type") Then
		Return ValueType = ExpectedTypes;
	ElsIf TypeOf(ExpectedTypes) = Type("Array") 
		Or TypeOf(ExpectedTypes) = Type("FixedArray") Then
		Return ExpectedTypes.Find(ValueType) <> Undefined;
	ElsIf TypeOf(ExpectedTypes) = Type("Map") 
		Or TypeOf(ExpectedTypes) = Type("FixedMap") Then
		Return ExpectedTypes.Get(ValueType) <> Undefined;
	EndIf;
	Return Undefined;
	
EndFunction

Function TypesPresentation(ExpectedTypes)
	
	If TypeOf(ExpectedTypes) = Type("Array")
		Or TypeOf(ExpectedTypes) = Type("FixedArray")
		Or TypeOf(ExpectedTypes) = Type("Map")
		Or TypeOf(ExpectedTypes) = Type("FixedMap") Then
		
		Result = "";
		IndexOf = 0;
		For Each Item In ExpectedTypes Do
			
			If TypeOf(ExpectedTypes) = Type("Map")
				Or TypeOf(ExpectedTypes) = Type("FixedMap") Then 
				
				Type = Item.Key;
			Else 
				Type = Item;
			EndIf;
			
			If Not IsBlankString(Result) Then
				Result = Result + ", ";
			EndIf;
			
			Result = Result + TypePresentation(Type);
			IndexOf = IndexOf + 1;
			If IndexOf > 10 Then
				Result = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1,… (total %2 types)';"), 
					Result, 
					ExpectedTypes.Count());
				Break;
			EndIf;
		EndDo;
		
		Return Result;
		
	Else 
		Return TypePresentation(ExpectedTypes);
	EndIf;
	
EndFunction

Function TypePresentation(Type)
	
	If Type = Undefined Then
		
		Return "Undefined";
		
	ElsIf TypeOf(Type) = Type("TypeDescription") Then
		
		TypeAsString = String(Type);
		Return 
			?(StrLen(TypeAsString) > 150, 
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1,… (total %2 types)';"),
					Left(TypeAsString, 150),
					Type.Types().Count()), 
				TypeAsString);
		
	Else
		
		TypeAsString = String(Type);
		Return 
			?(StrLen(TypeAsString) > 150, 
				Left(TypeAsString, 150) + "...", 
				TypeAsString);
		
	EndIf;
	
EndFunction

#EndRegion

#EndRegion

#Region EmailAddressesOperations

#Region EmailAddressMeetsRequirements

Function HasCharsLeftRight(String, CharsToCheck)
	
	For Position = 1 To StrLen(CharsToCheck) Do
		Char = Mid(CharsToCheck, Position, 1);
		CharFound = (Left(String,1) = Char) Or (Right(String,1) = Char);
		If CharFound Then
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction

Function StringContainsAllowedCharsOnly(String, AllowedChars)
	CharactersArray = New Array;
	For Position = 1 To StrLen(AllowedChars) Do
		CharactersArray.Add(Mid(AllowedChars,Position,1));
	EndDo;
	
	For Position = 1 To StrLen(String) Do
		If CharactersArray.Find(Mid(String, Position, 1)) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
EndFunction

#EndRegion

#EndRegion

#Region DynamicList

Procedure FindRecursively(ItemsCollection, ItemArray, SearchMethod, SearchValue)
	
	For Each FilterElement In ItemsCollection Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			
			If SearchMethod = 1 Then
				If FilterElement.LeftValue = SearchValue Then
					ItemArray.Add(FilterElement);
				EndIf;
			ElsIf SearchMethod = 2 Then
				If FilterElement.Presentation = SearchValue Then
					ItemArray.Add(FilterElement);
				EndIf;
			EndIf;
		Else
			
			FindRecursively(FilterElement.Items, ItemArray, SearchMethod, SearchValue);
			
			If SearchMethod = 2 And FilterElement.Presentation = SearchValue Then
				ItemArray.Add(FilterElement);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Math

#Region DistributeAmountInProportionToCoefficients

Function MaxValueInArray(Array)
	
	MaxValue = 0;
	
	For IndexOf = 0 To Array.Count() - 1 Do
		Value = Array[IndexOf];
		
		If MaxValue < Value Then
			MaxValue = Value;
		EndIf;
	EndDo;
	
	Return MaxValue;
	
EndFunction

#EndRegion

#EndRegion

#Region ObsoleteProceduresAndFunctions

// 

#Region StartApplication

#If Not WebClient Then

// Returns the standard output and error stream encoding used in the current OS.
//
// Returns:
//  TextEncoding - 
//
Function StandardStreamEncoding()
	
	SystemInfo = New SystemInfo();
	If (SystemInfo.PlatformType = PlatformType.Windows_x86) 
		Or (SystemInfo.PlatformType = PlatformType.Windows_x86_64) Then
		
		Encoding = TextEncoding.OEM;
	Else
		Encoding = TextEncoding.System;
	EndIf;
	
	Return Encoding;
	
EndFunction

Procedure DeleteTempFile(FullFileName)
	
	If IsBlankString(FullFileName) Then
		Return;
	EndIf;
		
	Try
		DeleteFiles(FullFileName);
	Except
		
		// 
		
#If Server Then
		WriteLogEvent(NStr("en = 'Core';", DefaultLanguageCode()),
			EventLogLevel.Warning,,, 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot delete temporary file:
				           |%1. Reason: %2';"), 
				FullFileName, 
				ErrorProcessing.BriefErrorDescription(ErrorInfo())));
#EndIf
		
		// 
		
	EndTry;
	
EndProcedure

#EndIf

#EndRegion

#Region ConnectionDiagnostics

#If Not WebClient Then

Function DiagnosticsLocationPresentation()
	
	// 
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.DataSeparationEnabled() Then
		Return NStr("en = 'Connecting from a remote 1C:Enterprise server.';");
	Else 
		If Common.FileInfobase() Then
			If ClientConnectedOverWebServer() Then 
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Connecting from a file infobase on web server <%1>.';"), ComputerName());
			Else 
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Connecting from a file infobase on computer <%1>.';"), ComputerName());
			EndIf;
		Else
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Connecting from 1C:Enterprise server <%1>.';"), ComputerName());
		EndIf;
	EndIf;
#Else 
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Connecting from computer <%1> (client).';"), ComputerName());
#EndIf
	
	// 
	
EndFunction

Function CheckServerAvailability(ServerAddress)
	
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	
	SystemInfo = New SystemInfo();
	IsWindows = (SystemInfo.PlatformType = PlatformType.Windows_x86) 
		Or (SystemInfo.PlatformType = PlatformType.Windows_x86_64);
		
	If IsWindows Then
		CommandTemplate = "ping %1 -n 2 -w 500";
	Else
		CommandTemplate = "ping -c 2 -w 500 %1";
	EndIf;
	
	CommandString = StringFunctionsClientServer.SubstituteParametersToString(CommandTemplate, ServerAddress);
	
	Result = StartApplication(CommandString, ApplicationStartupParameters);
	
	// 
	// 
	// 
	AvailabilityLog = Result.OutputStream + Result.ErrorStream;
	
	// 
	
	If IsWindows Then
		UnavailabilityFact = (StrFind(AvailabilityLog, "Preassigned node disabled") > 0) // 
			Or (StrFind(AvailabilityLog, "Destination host unreachable") > 0); // 
		
		NoLosses = (StrFind(AvailabilityLog, "(0% loss)") > 0) // 
			Or (StrFind(AvailabilityLog, "(0% loss)") > 0); // 
	Else 
		UnavailabilityFact = (StrFind(AvailabilityLog, "Destination Host Unreachable") > 0); // 
		NoLosses = (StrFind(AvailabilityLog, "0% packet loss") > 0) // 
	EndIf;
	
	// 
	
	Available = Not UnavailabilityFact And NoLosses;
	
	Log = New Array;
	If Available Then
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Remote server %1 is available:';"), 
			ServerAddress));
	Else
		Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Remote server %1 is unavailable:';"), 
			ServerAddress));
	EndIf;
	
	Log.Add("> " + CommandString);
	Log.Add(AvailabilityLog);
	
	Return New Structure("Available, DiagnosticsLog", Available, StrConcat(Log, Chars.LF));
	
EndFunction

Function ServerRouteTraceLog(ServerAddress)
	
	ApplicationStartupParameters = ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	ApplicationStartupParameters.GetOutputStream = True;
	ApplicationStartupParameters.GetErrorStream = True;
	
	SystemInfo = New SystemInfo();
	IsWindows = (SystemInfo.PlatformType = PlatformType.Windows_x86) 
		Or (SystemInfo.PlatformType = PlatformType.Windows_x86_64);
	
	If IsWindows Then
		CommandTemplate = "tracert -w 100 -h 15 %1";
	Else 
		// 
		// 
		// 
		CommandTemplate = "traceroute -w 100 -m 100 %1";
	EndIf;
	
	CommandString = StringFunctionsClientServer.SubstituteParametersToString(CommandTemplate, ServerAddress);
	
	Result = StartApplication(CommandString, ApplicationStartupParameters);
	
	Log = New Array;
	Log.Add(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Tracing route to remote server %1:';"), ServerAddress));
	
	Log.Add("> " + CommandString);
	Log.Add(Result.OutputStream);
	Log.Add(Result.ErrorStream);
	
	Return StrConcat(Log, Chars.LF);
	
EndFunction

#EndIf

#EndRegion

// 

#EndRegion

#EndRegion
