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
// 
//
// Parameters:
//  MessageToUserText - String -  message text.
//  DataKey - Arbitrary - 
//  Field - String - 
//  DataPath - String -  data path (the path to the requisite shape).
//  Cancel - Boolean -  the output parameter is always set to True.
//
// Example:
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
Procedure MessageToUser(Val MessageToUserText, Val DataKey = Undefined,	Val Field = "",
	Val DataPath = "", Cancel = False) Export
	
	IsObject = False;
	
	If DataKey <> Undefined
		And XMLTypeOf(DataKey) <> Undefined Then
		
		ValueTypeAsString = XMLTypeOf(DataKey).TypeName;
		IsObject = StrFind(ValueTypeAsString, "Object.") > 0;
	EndIf;
	
	Message = CommonInternalClientServer.UserMessage(MessageToUserText,
		DataKey, Field, DataPath, Cancel, IsObject);
	
#If Not MobileStandaloneServer Then
	If StandardSubsystemsCached.IsLongRunningOperationSession()
	   And Not TransactionActive() Then
		
		TimeConsumingOperations.SendClientNotification("UserMessage", Message);
	Else
		Message.Message();
	EndIf;
#Else
		Message.Message();
#EndIf
	
EndProcedure

// 

#EndRegion

#If Not MobileStandaloneServer Then

#Region InfobaseData

////////////////////////////////////////////////////////////////////////////////
// 

// Returns a structure containing the details values read from the information base by reference to the object.
// It is recommended to use it instead of accessing the object's details through a dot from the object reference
// to quickly read individual object details from the database.
//
// If you need to read the details regardless of the current user's rights,
// you should use the pre - transition to privileged mode.
//
// Parameters:
//  Ref    - AnyRef -  the object whose details are to be retrieved.
//            - String      - 
//  Attributes - String -  names of details, separated by commas, in the format
//                       of requirements for structure properties.
//                       For Example, "Code, Name, Parent".
//            - Structure
//            - FixedStructure - 
//                       
//                       
//                       
//                       
//                       
//            - Array of String
//            - FixedArray of String - 
//  SelectAllowedItems - Boolean -  if True, the request to the object is executed with the user's rights taken into account;
//                                if there is a restriction at the record level, all the details will be returned with 
//                                the value Undefined. if there are no rights to work with the table, an exception will be thrown;
//                                if False, an exception will occur if there are no rights to the table 
//                                or any of the details.
//  LanguageCode - String -  language code for multilingual props. The default value is the main configuration language.
//
// Returns:
//  Structure - 
//              
//               
//              
//               
//              
//
Function ObjectAttributesValues(Ref, Val Attributes, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	// 
	If TypeOf(Ref) = Type("String") Then
		
		FullNameOfPredefinedItem = Ref;
		
		// 
		// 
		Try
			Ref = PredefinedItem(FullNameOfPredefinedItem);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter, function %2:
				|%3.';"), "Ref", "Common.ObjectAttributesValues", 
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndTry;
		
		// 
		FullNameParts1 = StrSplit(FullNameOfPredefinedItem, ".");
		FullMetadataObjectName = FullNameParts1[0] + "." + FullNameParts1[1];
		
		// 
		// 
		If Ref = Undefined Then 
			ObjectMetadata = MetadataObjectByFullName(FullMetadataObjectName);
			If Not AccessRight("Read", ObjectMetadata) Then 
				Raise(StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Insufficient rights to access table %1.';"), FullMetadataObjectName),
					ErrorCategory.AccessViolation);
			EndIf;
		EndIf;
		
	Else // 
		
		Try
			FullMetadataObjectName = Ref.Metadata().FullName(); 
		Except
			Raise (StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of the %1 parameter, function %2:
					|The value must contain predefined item name or reference.';"), 
				"Ref", "Common.ObjectAttributesValues"),
				ErrorCategory.ConfigurationError);
		EndTry;
		
	EndIf;
	
	// 
	If TypeOf(Attributes) = Type("String") Then
		If IsBlankString(Attributes) Then
			Return New Structure;
		EndIf;
		
		Attributes = StrSplit(Attributes, ",", False);
		For IndexOf = 0 To Attributes.UBound() Do
			Attributes[IndexOf] = TrimAll(Attributes[IndexOf]);
		EndDo;
	EndIf;
	
	MultilingualAttributes = New Map;
	LanguageSuffix = "";
	If ValueIsFilled(LanguageCode) Then
		If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
			LanguageSuffix = ModuleNationalLanguageSupportServer.LanguageSuffix(LanguageCode);
			If ValueIsFilled(LanguageSuffix) Then
				MultilingualAttributes = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(Ref);
			EndIf;
		EndIf;
	EndIf;
	
	// 
	FieldsStructure = New Structure;
	If TypeOf(Attributes) = Type("Structure")
		Or TypeOf(Attributes) = Type("FixedStructure") Then
		
		For Each KeyAndValue In Attributes Do
			FieldsStructure.Insert(KeyAndValue.Key, TrimAll(KeyAndValue.Value));
		EndDo;
		
	ElsIf TypeOf(Attributes) = Type("Array")
		Or TypeOf(Attributes) = Type("FixedArray") Then
		
		For Each Attribute In Attributes Do
			Attribute = TrimAll(Attribute);
			Try
				FieldAlias = StrReplace(Attribute, ".", "");
				FieldsStructure.Insert(FieldAlias, Attribute);
			Except 
				// 
				
				// 
				Result = CheckIfObjectAttributesExist(FullMetadataObjectName, Attributes);
				If Result.Error Then 
					Raise(StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Invalid value of the %1 parameter, function %2: %3.';"),
						"Attributes", "Common.ObjectAttributesValues", Result.ErrorDescription),
						ErrorCategory.ConfigurationError);
				EndIf;
				
				// 
				Raise;
			
			EndTry;
		EndDo;
	Else
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid type of parameter %1 in function %2: %3.';"), 
			"Attributes", "Common.ObjectAttributesValues", String(TypeOf(Attributes))),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	// 
	Result = New Structure;
	
	// 
	FieldQueryText = "";
	For Each KeyAndValue In FieldsStructure Do
		
		FieldName = ?(ValueIsFilled(KeyAndValue.Value),
						KeyAndValue.Value,
						KeyAndValue.Key);
		FieldAlias = KeyAndValue.Key;
		
		If MultilingualAttributes[FieldName] <> Undefined Then
			FieldName = FieldName + LanguageSuffix;
		EndIf;
		
		FieldQueryText = 
			FieldQueryText + ?(IsBlankString(FieldQueryText), "", ",") + "
			|	" + FieldName + " AS " + FieldAlias;
		
		// 
		Result.Insert(FieldAlias);
		
	EndDo;
	
	// 
	// 
	If Ref = Undefined Then 
		Return Result;
	EndIf;
	
	If Type("Structure") = TypeOf(Attributes)
		Or Type("FixedStructure") = TypeOf(Attributes) Then
		Attributes = New Array;
		For Each KeyAndValue In FieldsStructure Do
			FieldName = ?(ValueIsFilled(KeyAndValue.Value),
						KeyAndValue.Value,
						KeyAndValue.Key);
			Attributes.Add(FieldName);
		EndDo;
	EndIf;
	
	BankDetailsViaAPoint = New Array;
	For IndexOf = -Attributes.UBound() To 0 Do
		FieldName = Attributes[-IndexOf];
		If StrFind(FieldName, ".") Then
			BankDetailsViaAPoint.Add(FieldName);
			Attributes.Delete(-IndexOf);
		EndIf;
	EndDo;
	
	If ValueIsFilled(Attributes) Then
		ObjectAttributesValues = ObjectsAttributesValues(CommonClientServer.ValueInArray(Ref), Attributes, SelectAllowedItems, LanguageCode)[Ref];
		If ObjectAttributesValues <> Undefined Then
			For Each KeyAndValue In FieldsStructure Do
				FieldName = ?(ValueIsFilled(KeyAndValue.Value),
							KeyAndValue.Value,
							KeyAndValue.Key);
				If StrFind(FieldName, ".") = 0 And ObjectAttributesValues.Property(FieldName) Then
					Result[KeyAndValue.Key] = ObjectAttributesValues[FieldName];
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(BankDetailsViaAPoint) Then
		Return Result;
	EndIf;
	
	Attributes = BankDetailsViaAPoint;
	
	QueryText = 
		"SELECT ALLOWED
		|&FieldQueryText
		|FROM
		|	&FullMetadataObjectName AS SpecifiedTableAlias
		|WHERE
		|	SpecifiedTableAlias.Ref = &Ref";
	
	If Not SelectAllowedItems Then 
		QueryText = StrReplace(QueryText, "ALLOWED", ""); // @Query-part-1
	EndIf;
	
	QueryText = StrReplace(QueryText, "&FieldQueryText", FieldQueryText);
	QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
	
	// 
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = QueryText;
	
	Try
		Selection = Query.Execute().Select();
	Except
		
		// 
		// 
		// 
		// 
		If Type("Structure") = TypeOf(Attributes)
			Or Type("FixedStructure") = TypeOf(Attributes) Then
			Attributes = New Array;
			For Each KeyAndValue In FieldsStructure Do
				FieldName = ?(ValueIsFilled(KeyAndValue.Value),
							KeyAndValue.Value,
							KeyAndValue.Key);
				Attributes.Add(FieldName);
			EndDo;
		EndIf;
		
		// 
		Result = CheckIfObjectAttributesExist(FullMetadataObjectName, Attributes);
		If Result.Error Then 
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of the %1 parameter, function %2: %3.';"), 
				"Attributes", "Common.ObjectAttributesValues", Result.ErrorDescription),
				ErrorCategory.ConfigurationError);
		EndIf;

		Raise;
		
	EndTry;
	
	// 
	If Selection.Next() Then
		FillPropertyValues(Result, Selection);
	EndIf;
	
	Return Result;
	
EndFunction

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
//  Ref    - AnyRef -  the object whose details are to be retrieved.
//            - String      - 
//  AttributeName       - String -  the name of the bank account to receive.
//                                It is allowed to specify the name of a prop separated by a dot, but the language code parameter for
//                                such a prop will not be taken into account.
//  SelectAllowedItems - Boolean -  if True, the request to the object is executed with the user's rights taken into account;
//                                if there is a limit at the record level, it returns Undefined;
//                                if you don't have permissions to work with the table, an exception will be thrown;
//                                if False, an exception will occur if there are no rights to the table
//                                or any of the details.
//  LanguageCode - String -  language code for multilingual props. The default value is the main configuration language.
//
// Returns:
//  Arbitrary - 
//                  
//                 
//
Function ObjectAttributeValue(Ref, AttributeName, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	If IsBlankString(AttributeName) Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter, function %2:
				|The attribute name cannot be empty.';"), 
			"AttributeName", "Common.ObjectAttributeValue"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	Result = ObjectAttributesValues(Ref, AttributeName, SelectAllowedItems, LanguageCode);
	Return Result[StrReplace(AttributeName, ".", "")];
	
EndFunction 

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
//  References - Array of AnyRef
//         - FixedArray of AnyRef - 
//           
//  Attributes - String -  the names of the details are separated by commas, in the format of requirements for
//                       the structure properties. For Example, "Code, Name, Parent".
//            - Array of String
//            - FixedArray of String - 
//  SelectAllowedItems - Boolean -  if True, the request to objects is executed with the user's rights taken into account;
//                                if an object is excluded from the selection by rights, this object
//                                will also be excluded from the result;
//                                if False, an exception will occur if there are no rights to the table
//                                or any of the details.
//  LanguageCode - String -  language code for multilingual props. The default value is the main configuration language.
//
// Returns:
//  Map of KeyAndValue - :
//   * Key - AnyRef -  object reference;
//   * Value - Structure:
//    ** Key - String -  the name of the props;
//    ** Value - Arbitrary -  the value of the props.
// 
Function ObjectsAttributesValues(References, Val Attributes, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	If TypeOf(Attributes) = Type("Array") Or TypeOf(Attributes) = Type("FixedArray") Then
		Attributes = StrConcat(Attributes, ",");
	EndIf;
	
	If IsBlankString(Attributes) Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter, function %2:
				|The object field must be specified.';"), 
			"Attributes", "Common.ObjectsAttributesValues"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	If StrFind(Attributes, ".") <> 0 Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter, function %2:
				|Dot syntax is not supported.';"), 
			"Attributes", "Common.ObjectsAttributesValues"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	AttributesValues = New Map;
	If References.Count() = 0 Then
		Return AttributesValues;
	EndIf;
	
	If ValueIsFilled(LanguageCode) Then
		LanguageCode = StrSplit(LanguageCode, "_", True)[0];
	EndIf;
	
	AttributesQueryText = Attributes;
	
	If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
		If ValueIsFilled(LanguageCode) Then
			LanguageSuffix = ModuleNationalLanguageSupportServer.LanguageSuffix(LanguageCode);
			If ValueIsFilled(LanguageSuffix) Then
				MultilingualAttributes = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(References[0]);
				AttributesSet = StrSplit(Attributes, ",");
				For Position = 0 To AttributesSet.UBound() Do
					AttributeName = TrimAll(AttributesSet[Position]);
					If MultilingualAttributes[AttributeName] <> Undefined Then
						NameWithSuffix = AttributeName + LanguageSuffix;
						AttributesSet[Position] = NameWithSuffix + " AS " + AttributeName;
					EndIf;
				EndDo;
				AttributesQueryText = StrConcat(AttributesSet, ",");
			EndIf;
		EndIf;
	EndIf;
	
	RefsByTypes = New Map;
	For Each Ref In References Do
		Type = TypeOf(Ref);
		If RefsByTypes[Type] = Undefined Then
			RefsByTypes[Type] = New Array;
		EndIf;
		ItemByType = RefsByTypes[Type]; // Array
		ItemByType.Add(Ref);
	EndDo;
	
	QueriesTexts = New Array;
	QueryOptions = New Structure;
	
	MetadataObjectNames = New Array;
	
	For Each RefsByType In RefsByTypes Do
		Type = RefsByType.Key;
		MetadataObject = Metadata.FindByType(Type);
		If MetadataObject = Undefined Then
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of the %1 parameter, function %2:
					|The array values must be references.';"), 
				"References", "Common.ObjectsAttributesValues"),
				ErrorCategory.ConfigurationError);
		EndIf;
		
		FullMetadataObjectName = MetadataObject.FullName();
		MetadataObjectNames.Add(FullMetadataObjectName);
		
		QueryText =
			"SELECT ALLOWED
			|	Ref,
			|	&Attributes
			|FROM
			|	&FullMetadataObjectName AS SpecifiedTableAlias
			|WHERE
			|	SpecifiedTableAlias.Ref IN (&References)";
		If Not SelectAllowedItems Or QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "ALLOWED", ""); // @Query-part-1
		EndIf;
		QueryText = StrReplace(QueryText, "&Attributes", AttributesQueryText);
		QueryText = StrReplace(QueryText, "&FullMetadataObjectName", FullMetadataObjectName);
		ParameterName = "References" + StrReplace(FullMetadataObjectName, ".", "");
		QueryText = StrReplace(QueryText, "&References", "&" + ParameterName); // @Query-part-1
		QueryOptions.Insert(ParameterName, RefsByType.Value);
		
		If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer  = CommonModule("NationalLanguageSupportServer");
			
			If ValueIsFilled(LanguageCode) And LanguageCode <> DefaultLanguageCode()
				And ModuleNationalLanguageSupportServer.ObjectContainsPMRepresentations(FullMetadataObjectName) Then
				
				MultilingualAttributes = ModuleNationalLanguageSupportServer.MultilingualObjectAttributes(MetadataObject);
				TablesFields = New Array;
				TablesFields.Add("SpecifiedTableAlias.Ref");
				For Each Attribute In StrSplit(Attributes, ",") Do
					If MultilingualAttributes[Attribute] <> Undefined Then
						
						If MultilingualAttributes[Attribute] = True Then
							AttributeField = "ISNULL(PresentationTable." + Attribute + ", """")";
						Else
							LanguageSuffix = ModuleNationalLanguageSupportServer.LanguageSuffix(LanguageCode);
							AttributeField = ?(ValueIsFilled(LanguageSuffix), Attribute + LanguageSuffix, Attribute);
						EndIf;
						
						TablesFields.Add(StringFunctionsClientServer.SubstituteParametersToString("%1 AS %2",
							AttributeField, Attribute));
					Else
						TablesFields.Add(Attribute);
					EndIf;
					
				EndDo;
				
				TablesFields = StrConcat(TablesFields, "," + Chars.LF);
				
				Tables = FullMetadataObjectName + " " + "AS SpecifiedTableAlias" + Chars.LF
					+ "LEFT JOIN" + " " + FullMetadataObjectName + ".Presentations AS PresentationTable" + Chars.LF
					+ "On PresentationTable.Ref = SpecifiedTableAlias.Ref AND PresentationTable.LanguageCode = &LanguageCode";
					
				ParameterName = "References" + StrReplace(FullMetadataObjectName, ".", "");
				Conditions = "SpecifiedTableAlias.Ref IN (&" + ParameterName + ")";
				
				QueryStrings = New Array;
				QueryStrings.Add("SELECT" + ?(SelectAllowedItems And Not ValueIsFilled(QueriesTexts), " " + "ALLOWED", "")); // @Query-part-1, @Query-part-3
				QueryStrings.Add(TablesFields);
				QueryStrings.Add("FROM"); // @Query-part-1
				QueryStrings.Add(Tables);
				QueryStrings.Add("WHERE"); // @Query-part-1
				QueryStrings.Add(Conditions);
				
				QueryText = StrConcat(QueryStrings, Chars.LF);
			EndIf;
		EndIf;
		
		QueriesTexts.Add(QueryText);
	EndDo;
	
	QueryText = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF);
	
	Query = New Query(QueryText);
	Query.SetParameter("LanguageCode", LanguageCode);
	For Each Parameter In QueryOptions Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	Try
		Selection = Query.Execute().Select();
	Except
		
		// 
		Attributes = StrReplace(Attributes, " ", "");
		// 
		Attributes = StrSplit(Attributes, ",");
		
		// 
		ErrorList = New Array;
		For Each FullMetadataObjectName In MetadataObjectNames Do
			Result = CheckIfObjectAttributesExist(FullMetadataObjectName, Attributes);
			If Result.Error Then 
				ErrorList.Add(Result.ErrorDescription);
			EndIf;
		EndDo;
		
		If ValueIsFilled(ErrorList) Then
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of the %1 parameter, function %2: %3';"), 
				"Attributes", "Common.ObjectsAttributesValues", 
				StrConcat(ErrorList, Chars.LF)),
				ErrorCategory.ConfigurationError);
		EndIf;
		
		Raise;
		
	EndTry;
	
	While Selection.Next() Do
		Result = New Structure(Attributes);
		FillPropertyValues(Result, Selection);
		AttributesValues[Selection.Ref] = Result;
		
	EndDo;
	
	Return AttributesValues;
	
EndFunction

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
//  ReferencesArrray       - Array of AnyRef
//                     - FixedArray of AnyRef
//  AttributeName       - String -  for example, "Code".
//  SelectAllowedItems - Boolean -  if True, the request to objects is executed with the user's rights taken into account;
//                                if an object is excluded from the selection by rights, this object
//                                will also be excluded from the result;
//                                if False, an exception will occur if there are no rights to the table
//                                or any of the details.
//  LanguageCode - String -  language code for multilingual props. The default value is the main configuration language.
//
// Returns:
//  Map of KeyAndValue:
//      * Key     - AnyRef  -  object reference,
//      * Value - Arbitrary -  the value of the read props.
// 
Function ObjectsAttributeValue(ReferencesArrray, AttributeName, SelectAllowedItems = False, Val LanguageCode = Undefined) Export
	
	If IsBlankString(AttributeName) Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter, function %2:
			|The attribute name cannot be empty.';"), 
			"AttributeName", "Common.ObjectsAttributeValue"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	AttributesValues = ObjectsAttributesValues(ReferencesArrray, AttributeName, SelectAllowedItems, LanguageCode);
	For Each Item In AttributesValues Do
		AttributesValues[Item.Key] = Item.Value[AttributeName];
	EndDo;
		
	Return AttributesValues;
	
EndFunction

// 
//
//  
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject
//         - ChartOfCharacteristicTypesObject
//         - InformationRegisterRecord -  the object to fill in.
//  AttributeName - String -  name of the information to fill in. For Example, " Comment"
//  Value - String -  the value to put in the props.
//  LanguageCode - String -  the language code of the props. For example, "ru".
//
Procedure SetAttributeValue(Object, AttributeName, Value, LanguageCode = Undefined) Export
	SetAttributesValues(Object, New Structure(AttributeName, Value), LanguageCode);
EndProcedure

// 
//
//  
//
// Parameters:
//  Object - CatalogObject
//         - DocumentObject
//         - ChartOfCharacteristicTypesObject
//         - InformationRegisterRecord -  the object to fill in.
//  Values - Structure -  where the key is the name of the prop, and the value contains the string to be placed in the prop.
//  LanguageCode - String -  the language code of the props. For example, "ru".
//
Procedure SetAttributesValues(Object, Values, LanguageCode = Undefined) Export
	
	If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.SetAttributesValues(Object, Values, LanguageCode);
		Return;
	EndIf;
	
	For Each AttributeValue In Values Do
		Value = AttributeValue.Value;
		If TypeOf(Value) = Type("String") And StringAsNstr(Value) Then
			Value = NStr(AttributeValue.Value);
		EndIf;
		Object[AttributeValue.Key] = Value;
	EndDo;
	
EndProcedure

// Returns the code of the main language of the information base, for example "ru".
// On which automatically generated strings are programmatically written to the information database.
// For example, when initially filling in the information database with data from the layout, auto-generating a comment
// on a transaction, or determining the value of the EventName parameter of the log record method.
//
// Returns:
//  String
//
Function DefaultLanguageCode() Export
	
	If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
		Return ModuleNationalLanguageSupportServer.DefaultLanguageCode();
	EndIf;
	
	Return Metadata.DefaultLanguage.LanguageCode;
	
EndFunction

// Returns a flag indicating that the user has set the interface language
// corresponding to the main language of the information base.
//
// Returns:
//  Boolean
//
Function IsMainLanguage() Export
	
	Return StrCompare(DefaultLanguageCode(), CurrentLanguage().LanguageCode) = 0;
	
EndFunction

// Returns a reference to a predefined element by its full name.
// Predefined elements can only be contained in the following objects:
//   - directories;
//   - plans of types of characteristics;
//   - chart of accounts;
//   - plans for calculation types.
// After changing the composition of the predefined ones, run the method
// Update the re-used values (), which will reset the Repeat cache in the current session.
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
	
	StandardProcessing = CommonInternalClientServer.UseStandardGettingPredefinedItemFunction(
		FullPredefinedItemName);
	
	If StandardProcessing Then 
		Return PredefinedValue(FullPredefinedItemName);
	EndIf;
	
	PredefinedItemFields = CommonInternalClientServer.PredefinedItemNameByFields(FullPredefinedItemName);
	
	PredefinedValues = StandardSubsystemsCached.RefsByPredefinedItemsNames(
		PredefinedItemFields.FullMetadataObjectName);
	
	Return CommonInternalClientServer.PredefinedItem(
		FullPredefinedItemName, PredefinedItemFields, PredefinedValues);
	
EndFunction

// 
// 
// 
// 
// Parameters:
//  Items - Array of AnyRef
//
// Returns:
//  Map of KeyAndValue - :
//   * Key - AnyRef -  object reference.
//   * Value - Boolean - 
//
Function ArePredefinedItems(Val Items) Export
	
	AttributesNames = New Array;
	For Each AttributeName In StandardSubsystemsServer.PredefinedDataAttributes() Do
		AttributesNames.Add(AttributeName.Key);
	EndDo;
	
	AttributesValues = StandardSubsystemsServer.ObjectAttributeValuesIfExist(Items, AttributesNames);
	Result = New Map;
	For Each Item In AttributesValues Do
		ThisIsAPredefinedItem = False;
		For Each Value In Item.Value Do
			If ValueIsFilled(Value.Value) Then
				ThisIsAPredefinedItem = True;
			EndIf;
		EndDo;
		Result[Item.Key] = ThisIsAPredefinedItem;
	EndDo;
	Return Result;	
	
EndFunction

// Checks the status of the submitted documents and returns
// those that were not processed.
//
// Parameters:
//  Var_Documents - Array of DocumentRef -  documents that need to be checked for their status.
//
// Returns:
//  Array of DocumentRef - 
//
Function CheckDocumentsPosting(Val Var_Documents) Export
	
	Result = New Array;
	
	QueryTemplate = 	
		"SELECT
		|	SpecifiedTableAlias.Ref AS Ref
		|FROM
		|	&DocumentName AS SpecifiedTableAlias
		|WHERE
		|	SpecifiedTableAlias.Ref IN(&DocumentsArray)
		|	AND NOT SpecifiedTableAlias.Posted";
	
	UnionAllText = UnionAllText();
	
	DocumentNames = New Array;
	For Each Document In Var_Documents Do
		MetadataOfDocument = Document.Metadata();
		If DocumentNames.Find(MetadataOfDocument.FullName()) = Undefined
			And Metadata.Documents.Contains(MetadataOfDocument)
			And MetadataOfDocument.Posting = Metadata.ObjectProperties.Posting.Allow Then
				DocumentNames.Add(MetadataOfDocument.FullName());
		EndIf;
	EndDo;
	
	QueryText = "";
	For Each DocumentName In DocumentNames Do
		If Not IsBlankString(QueryText) Then
			QueryText = QueryText + UnionAllText;
		EndIf;
		SubqueryText = StrReplace(QueryTemplate, "&DocumentName", DocumentName);
		QueryText = QueryText + SubqueryText;
	EndDo;
		
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentsArray", Var_Documents);
	
	If Not IsBlankString(QueryText) Then
		Result = Query.Execute().Unload().UnloadColumn("Ref");
	EndIf;
	
	Return Result;
	
EndFunction

// Attempts to process documents.
//
// Parameters:
//  Var_Documents - Array of DocumentRef -  documents to be processed.
//
// Returns:
//  Array of Structure:
//   * Ref         - DocumentRef -  document that could not be processed,
//   * ErrorDescription - String         -  text of the error description.
//
Function PostDocuments(Var_Documents) Export
	
	UnpostedDocuments = New Array;
	
	For Each DocumentRef In Var_Documents Do
		
		ExecutedSuccessfully = False;
		DocumentObject = DocumentRef.GetObject();
		If DocumentObject.CheckFilling() Then
			PostingMode = DocumentPostingMode.Regular;
			If DocumentObject.Date >= BegOfDay(CurrentSessionDate())
				And DocumentRef.Metadata().RealTimePosting = Metadata.ObjectProperties.RealTimePosting.Allow Then
					PostingMode = DocumentPostingMode.RealTime;
			EndIf;
			Try
				DocumentObject.Write(DocumentWriteMode.Posting, PostingMode);
				ExecutedSuccessfully = True;
			Except
				ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			EndTry;
		Else
			ErrorPresentation = NStr("en = 'Document fields cannot be empty.';");
		EndIf;
		
		If Not ExecutedSuccessfully Then
			UnpostedDocuments.Add(New Structure("Ref,ErrorDescription", DocumentRef, ErrorPresentation));
		EndIf;
		
	EndDo;
	
	Return UnpostedDocuments;
	
EndFunction 

// Checks for references to the object in the database.
// When called in an undivided session, it does not detect links in split areas.
//
// Parameters:
//  RefOrRefArray - AnyRef
//                        - Array of AnyRef - 
//  SearchInInternalObjects - Boolean - 
//      
//      
//      
//
// Returns:
//  Boolean - 
//
Function RefsToObjectFound(Val RefOrRefArray, Val SearchInInternalObjects = False) Export
	
	If TypeOf(RefOrRefArray) = Type("Array") Then
		ReferencesArrray = RefOrRefArray;
	Else
		ReferencesArrray = CommonClientServer.ValueInArray(RefOrRefArray);
	EndIf;
	
	SetPrivilegedMode(True);
	UsageInstances = FindByRef(ReferencesArrray);
	SetPrivilegedMode(False);
	
	If Not SearchInInternalObjects Then
		For Each Item In InternalDataLinks(UsageInstances) Do
			UsageInstances.Delete(Item.Key);
		EndDo;
	EndIf;
	
	Return UsageInstances.Count() > 0;
	
EndFunction

// 
//
// Parameters:
//  UsageInstances		 - ValueTable - :
//   *  Ref - AnyRef -  the link being checked.
//   *  Data - AnyRef -  place of use.
//   *  Metadata - MetadataObject -  metadata of the place of use.
//  RefSearchExclusions	 - See RefSearchExclusions
//   
// Returns:
//   Map of KeyAndValue:
//     * Key - ValueTableRow
//     * Value - Boolean - 
//
Function InternalDataLinks(Val UsageInstances, Val RefSearchExclusions = Undefined) Export
	
	If RefSearchExclusions = Undefined Then
		RefSearchExclusions = RefSearchExclusions();
	EndIf;

	Result = New Map;
	UsageInstanceByMetadata = New Map;
	
	For Each UsageInstance1 In UsageInstances Do
		SearchException = RefSearchExclusions[UsageInstance1.Metadata];
		
		// 
		If SearchException = Undefined Then
			If UsageInstance1.Ref = UsageInstance1.Data Then
				Result[UsageInstance1] = True; // 
			EndIf;
			Continue;
		ElsIf SearchException = "*" Then
			Result[UsageInstance1] = True; // 
			Continue;
		EndIf;
	
		IsReference = IsReference(TypeOf(UsageInstance1.Data));
		If Not IsReference Then 
			For Each AttributePath1 In SearchException Do
				AttributeValue = New Structure(AttributePath1);
				FillPropertyValues(AttributeValue, UsageInstance1.Data);
				If AttributeValue[AttributePath1] = UsageInstance1.Ref Then 
					Result[UsageInstance1] = True;
					Break;
				EndIf;
			EndDo;
			Continue;
		EndIf;

		If SearchException.Count() = 0 Then
			Continue;
		EndIf;
		
		TableName = UsageInstance1.Metadata.FullName();
		Value = UsageInstanceByMetadata[TableName];
		If Value = Undefined Then
			Value = New ValueTable;
			Value.Columns.Add("Ref", AllRefsTypeDetails());
			Value.Columns.Add("Data", AllRefsTypeDetails());
			Value.Columns.Add("Metadata");
			UsageInstanceByMetadata[TableName] = Value;
		EndIf;
		FillPropertyValues(Value.Add(), UsageInstance1);

	EndDo;
	
	IndexOf = 1;
	Query = New Query;
	QueryTexts = New Array;
	TemporaryTable = New Array;
	
	For Each UsageInstance1 In UsageInstanceByMetadata Do
		 
		TableName = UsageInstance1.Key; // String
		UsageInstance1 = UsageInstance1.Value; // ValueTable

		// 
		If UsageInstance1.Count() > 1 Then
			QueryTemplate = 
				"SELECT
				|	References.Data AS Ref,
				|	References.Ref AS RefToCheck
				|INTO TTRefTable
				|FROM
				|	&References AS References
				|;
				|
				|SELECT
				|	RefsTable.Ref AS Ref,
				|	RefsTable.RefToCheck AS RefToCheck
				|FROM
				|	TTRefTable AS RefsTable
				|		LEFT JOIN #FullMetadataObjectName AS Table
				|		ON RefsTable.Ref = Table.Ref
				|WHERE
				|	&Condition";

			QueryText = StrReplace(QueryTemplate, "#FullMetadataObjectName", TableName);
			QueryText = StrReplace(QueryText, "TTRefTable", "TTRefTable" + Format(IndexOf, "NG=;NZ="));

			ParameterName = "References" + Format(IndexOf, "NG=;NZ=");
			QueryText = StrReplace(QueryText, "&References", "&" + ParameterName);
			Query.SetParameter(ParameterName, UsageInstance1);
			
			QueryParts = StrSplit(QueryText, ";");
			TemporaryTable.Add(QueryParts[0]);
			QueryText = QueryParts[1];

		Else
			QueryTemplate = 
				"SELECT
				|	&OwnerReference AS Ref,
				|	&RefToCheck AS RefToCheck
				|FROM
				|	#FullMetadataObjectName AS Table
				|WHERE
				|	Table.Ref = &OwnerReference
				|	AND (&Condition)";

			QueryText = StrReplace(QueryTemplate, "#FullMetadataObjectName", TableName);

			ParameterName = "OwnerReference" + Format(IndexOf, "NG=;NZ=");
			QueryText = StrReplace(QueryText, "&OwnerReference", "&" + ParameterName);
			Query.SetParameter(ParameterName, UsageInstance1[0].Data);

			ParameterName = "RefToCheck" + Format(IndexOf, "NG=;NZ=");
			QueryText = StrReplace(QueryText, "&RefToCheck", "&" + ParameterName);
			Query.SetParameter(ParameterName, UsageInstance1[0].Ref);

		EndIf;

		ConditionText = New Array;
		// 
		For Each AttributePath1 In RefSearchExclusions[UsageInstance1[0].Metadata] Do
			ConditionText.Add(AttributePath1 + " = " 
				+ ?(UsageInstance1.Count() > 1, "RefsTable.RefToCheck", "&" + ParameterName));
		EndDo;
		QueryText = StrReplace(QueryText, "&Condition", StrConcat(ConditionText, " OR "));
		
		QueryTexts.Add(QueryText);
		IndexOf = IndexOf + 1;
		
	EndDo;
	
	If QueryTexts.Count() = 0 Then
		Return Result;
	EndIf;
	
	Query.Text = StrConcat(TemporaryTable, ";" + Chars.LF)
		+ ?(TemporaryTable.Count() > 0, ";" + Chars.LF, "") 
		+ StrConcat(QueryTexts, Chars.LF + "UNION" + Chars.LF);
	SetPrivilegedMode(True);
	QuerySelection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	UsageInstances.Indexes.Add("Ref,Data");
	While QuerySelection.Next() Do
		InternalDataLinks = UsageInstances.FindRows(New Structure("Ref,Data", 
			QuerySelection.RefToCheck, QuerySelection.Ref));
		For Each InternalDataLink In InternalDataLinks Do
			Result[InternalDataLink] = True;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

// 
//
// Parameters:
//  UsageInstance1		 - Structure:
//   *  Ref - AnyRef -  the link being checked.
//   *  Data - AnyRef -  place of use.
//   *  Metadata - MetadataObject -  metadata of the place of use.
//  RefSearchExclusions	 - See RefSearchExclusions
// 
// Returns:
//   Boolean
//
Function IsInternalDataLink(Val UsageInstance1, Val RefSearchExclusions = Undefined) Export
	
	If RefSearchExclusions = Undefined Then
		RefSearchExclusions = RefSearchExclusions();
	EndIf;

	Value = New ValueTable;
	Value.Columns.Add("Ref", AllRefsTypeDetails());
	Value.Columns.Add("Data", AllRefsTypeDetails());
	Value.Columns.Add("Metadata");
	UsageInstanceRow = Value.Add();
	FillPropertyValues(UsageInstanceRow, UsageInstance1);
	
	Result = InternalDataLinks(Value, RefSearchExclusions);
	Return Result[UsageInstanceRow] <> Undefined;

EndFunction

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
//   ReplacementPairs - Map of KeyAndValue:
//       * Key     - AnyRef -  what we are looking for (double).
//       * Value - AnyRef -  what we replace (the original).
//       Links to themselves and empty search links will be ignored.
//   
//   ReplacementParameters - See Common.RefsReplacementParameters
//
// Returns:
//   ValueTable - :
//       * Ref - AnyRef -  the link that was replaced.
//       * ErrorObject - Arbitrary -  object - the cause of the error.
//       * ErrorObjectPresentation - String -  string representation of the error object.
//       * ErrorType - String - :
//           
//           
//           
//           
//           
//       * ErrorInfo - ErrorInfo
//       * ErrorText - String - 
//
Function ReplaceReferences(Val ReplacementPairs, Val ReplacementParameters = Undefined) Export
	
	Statistics = New Map;
	StringType = New TypeDescription("String");
	
	ReplacementErrors = New ValueTable;
	ReplacementErrors.Columns.Add("Ref");
	ReplacementErrors.Columns.Add("ErrorObject");
	ReplacementErrors.Columns.Add("ErrorObjectPresentation", StringType);
	ReplacementErrors.Columns.Add("ErrorType", StringType);
	ReplacementErrors.Columns.Add("ErrorText", StringType);
	ReplacementErrors.Columns.Add("ErrorInfo");
	
	ReplacementErrors.Indexes.Add("Ref");
	ReplacementErrors.Indexes.Add("Ref, ErrorObject, ErrorType");
	
	Result = TheResultOfReplacingLinks(ReplacementErrors);
	
	ExecutionParameters = NewReferenceReplacementExecutionParameters(ReplacementParameters);
	
	UsageInstancesSearchParameters = UsageInstancesSearchParameters();
	SupplementSubordinateObjectsRefSearchExceptions(UsageInstancesSearchParameters.AdditionalRefSearchExceptions);
	ExecutionParameters.Insert("UsageInstancesSearchParameters", UsageInstancesSearchParameters);
	
	SSLSubsystemsIntegration.BeforeSearchForUsageInstances(ReplacementPairs, ExecutionParameters);
	
	If ReplacementPairs.Count() = 0 Then
		Return Result.Errors;
	EndIf;
	
	Duplicates = GenerateDuplicates(ExecutionParameters, ReplacementParameters, ReplacementPairs, Result);	
	SearchTable = UsageInstances(Duplicates,, ExecutionParameters.UsageInstancesSearchParameters);
	
	// 
	// 
	SearchTable.Columns.Add("ReplacementKey", StringType);
	SearchTable.Indexes.Add("Ref, ReplacementKey");
	SearchTable.Indexes.Add("Data, ReplacementKey");
	
	// 
	SearchTable.Columns.Add("DestinationRef");
	SearchTable.Columns.Add("Processed", New TypeDescription("Boolean"));
	
	// 
	MarkupErrors = New Array;
	ObjectsWithErrors = New Array;
	Count = Duplicates.Count();
	For Number = 1 To Count Do
		ReverseIndex = Count - Number;
		Duplicate1 = Duplicates[ReverseIndex];
		MarkupResult = MarkUsageInstances(ExecutionParameters, Duplicate1, ReplacementPairs[Duplicate1], SearchTable);
		If Not MarkupResult.Success Then
			Duplicates.Delete(ReverseIndex);
			For Each Error In MarkupResult.MarkupErrors Do
				Error.Insert("Duplicate1", Duplicate1);
				ObjectsWithErrors.Add(Error.Object);
			EndDo;
			CommonClientServer.SupplementArray(MarkupErrors, MarkupResult.MarkupErrors);
		EndIf;
	EndDo;
			
	If MarkupErrors.Count() > 0 Then
		ObjectsPresentations = SubjectAsString(ObjectsWithErrors);
		For Each Error In MarkupErrors Do
			RegisterReplacementError(Result, Error.Duplicate1,
				ReplacementErrorDescription("UnknownData", Error.Object, ObjectsPresentations[Error.Object], 
					Error.Text));
		EndDo;
	EndIf;
	
	// 
	ExecutionParameters.Insert("ReplacementPairs",      ReplacementPairs);
	ExecutionParameters.Insert("SuccessfulReplacements", New Map);
	
	DisableAccessKeysUpdate(True);
	
	Try
		
		DuplicateCount = Duplicates.Count();
		Number = 1;
		For Each Duplicate1 In Duplicates Do
			
			HadErrors = Result.HasErrors;
			Result.HasErrors = False;
			
			// 
			ReplaceRefsUsingShortTransactions(Result, ExecutionParameters, Duplicate1, SearchTable);
					
			If Not Result.HasErrors Then
				ExecutionParameters.SuccessfulReplacements.Insert(Duplicate1, ExecutionParameters.ReplacementPairs[Duplicate1]);	
			EndIf;
			Result.HasErrors = Result.HasErrors Or HadErrors;
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("SessionNumber", InfoBaseSessionNumber());
			AdditionalParameters.Insert("ProcessedItemsCount", Number);
			TimeConsumingOperations.ReportProgress(Number,
				StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Replacing duplicates… processed (%1 of %2)';"), 
					Number, DuplicateCount), AdditionalParameters);
			Number = Number + 1;
			AddToReferenceReplacementStatistics(Statistics, Duplicate1, Result.HasErrors);
			
		EndDo;
		
		CommonOverridable.AfterReplaceRefs(Result, ExecutionParameters, SearchTable);
	
		DisableAccessKeysUpdate(False);
		
	Except
		DisableAccessKeysUpdate(False);
		Raise;
	EndTry;
	
	If SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") 
		And ExecutionParameters.ShouldDeleteDirectly Then
		
		ModuleMarkedObjectsDeletion = CommonModule("MarkedObjectsDeletion");
		
		TimeConsumingOperations.ReportProgress(0, NStr("en = 'Deleting duplicates…';"));
		DeletionResult = ModuleMarkedObjectsDeletion.ToDeleteMarkedObjects(Result.QueueForDirectDeletion);
		RegisterDeletionErrors(Result, DeletionResult.ObjectsPreventingDeletion);
		
	EndIf;
	
	SendReferenceReplacementStatistics(Statistics);
	
	Return Result.Errors;
	
EndFunction

// Structure designer for the parameter Parametrization functions Observatsionnoe.Replace links.
// 
// Returns:
//   Structure:
//     * DeletionMethod - String - :
//         
//         
//         
//     * TakeAppliedRulesIntoAccount - Boolean -  if True, the function "possibility to Replace elements of the Manager module" is called for each pair of "duplicate-original" 
//          
//         (the subsystem "Search and delete duplicates" is required). By default, False.
//     * IncludeBusinessLogic - Boolean -  mode for recording objects when replacing duplicate references with originals.
//         If True (by default), then the places where duplicates are used are recorded in the normal mode,
//         otherwise the recording is performed in the Tricked mode.Upload = True.
//     * ReplacePairsInTransaction - Boolean -  outdated. determines the size of the transaction when replacing duplicates.
//         If True (default), then all the places where the same duplicate is used are replaced in a single transaction. 
//         This can be very resource-intensive in the case of a large number of use cases.
//         If False, the replacement at each use location is performed in a separate transaction.
//     * WriteInPrivilegedMode - Boolean -  if True, then set the privileged mode before writing
//         objects when replacing duplicate references in them with the originals. False by default.
//
Function RefsReplacementParameters() Export
	Result = New Structure;
	Result.Insert("DeletionMethod", "");
	Result.Insert("TakeAppliedRulesIntoAccount", False);
	Result.Insert("IncludeBusinessLogic", True);
	Result.Insert("ReplacePairsInTransaction", False);
	Result.Insert("WriteInPrivilegedMode", False);
	Return Result;
EndFunction

// Gets all places where links are used.
// If a reference is not used anywhere, there will be no rows for it in the resulting table.
// When called in an undivided session, it does not detect links in split areas.
//
// Parameters:
//     RefSet     - Array of AnyRef -  links that we are looking for places to use.
//     ResultAddress - String - 
//     AdditionalParameters - See Common.UsageInstancesSearchParameters 
// 
// Returns:
//     ValueTable:
//       * Ref - AnyRef -  the link that is being analyzed.
//       * Data - Arbitrary -  data containing the analyzed link.
//       * Metadata - MetadataObject -  metadata of the found data.
//       * DataPresentation - String -  representation of data containing the analyzed link.
//       * RefType - Type -  the type of link being analyzed.
//       * AuxiliaryData - Boolean -  True if the data is used by the analyzed link as
//           auxiliary data (the leading dimension or was included in the exception for adding exceptions to links).
//       * IsInternalData - Boolean -  the data was included in the exclusionreferencesexternal Links
//
Function UsageInstances(Val RefSet, Val ResultAddress = "", AdditionalParameters = Undefined) Export
	
	UsageInstances = New ValueTable;
	
	SetPrivilegedMode(True);
	UsageInstances = FindByRef(RefSet); // See UsageInstances.
	SetPrivilegedMode(False);
	
	// 
	// 
	// 
	// 
	
	UsageInstances.Columns.Add("DataPresentation", New TypeDescription("String"));
	UsageInstances.Columns.Add("RefType");
	UsageInstances.Columns.Add("UsageInstanceInfo");
	UsageInstances.Columns.Add("AuxiliaryData", New TypeDescription("Boolean"));
	UsageInstances.Columns.Add("IsInternalData", New TypeDescription("Boolean"));
	
	UsageInstances.Indexes.Add("Ref");
	UsageInstances.Indexes.Add("Data");
	UsageInstances.Indexes.Add("AuxiliaryData");
	UsageInstances.Indexes.Add("Ref, AuxiliaryData");
	
	RecordKeysType = RecordKeysTypeDetails();
	AllRefsType = AllRefsTypeDetails();
	
	SequenceMetadata = Metadata.Sequences;
	ConstantMetadata = Metadata.Constants;
	MetadataOfDocuments = Metadata.Documents;
	
	RefSearchExclusions = RefSearchExclusions();
	
	AdditionalRefSearchExceptions = CommonClientServer.StructureProperty(
		AdditionalParameters, "AdditionalRefSearchExceptions", New Map);
	For Each MetadataExceptionAttributes In AdditionalRefSearchExceptions Do
		ExceptionValue = RefSearchExclusions[MetadataExceptionAttributes.Key];
		If ExceptionValue = Undefined Then
			RefSearchExclusions.Insert(MetadataExceptionAttributes.Key, MetadataExceptionAttributes.Value);
		ElsIf TypeOf(ExceptionValue) = Type("Array") Then
			CommonClientServer.SupplementArray(ExceptionValue, MetadataExceptionAttributes.Value);
		EndIf;
	EndDo;
	
	CancelRefsSearchExceptions = CommonClientServer.StructureProperty(AdditionalParameters,
		"CancelRefsSearchExceptions", New Array);
	For Each CancelException In CancelRefsSearchExceptions Do
		RefSearchExclusions.Delete(CancelException);	
	EndDo;
	
	InternalDataLinks = InternalDataLinks(UsageInstances, RefSearchExclusions);
	RegisterDimensionCache = New Map;
	
	For Each UsageInstance1 In UsageInstances Do
		DataType = TypeOf(UsageInstance1.Data);
		
		IsInternalData = InternalDataLinks[UsageInstance1] <> Undefined;
		IsAuxiliaryData = IsInternalData;
		
		If DataType = Undefined Or MetadataOfDocuments.Contains(UsageInstance1.Metadata) Then
			Presentation = String(UsageInstance1.Data);
			
		ElsIf ConstantMetadata.Contains(UsageInstance1.Metadata) Then
			Presentation = UsageInstance1.Metadata.Presentation() + " (" + NStr("en = 'constant';") + ")";
			
		ElsIf SequenceMetadata.Contains(UsageInstance1.Metadata) Then
			Presentation = UsageInstance1.Metadata.Presentation() + " (" + NStr("en = 'sequence';") + ")";
			
		ElsIf AllRefsType.ContainsType(DataType) Then
			ObjectMetaPresentation = New Structure("ObjectPresentation");
			FillPropertyValues(ObjectMetaPresentation, UsageInstance1.Metadata);
			If IsBlankString(ObjectMetaPresentation.ObjectPresentation) Then
				MetaPresentation = UsageInstance1.Metadata.Presentation();
			Else
				MetaPresentation = ObjectMetaPresentation.ObjectPresentation;
			EndIf;
			Presentation = String(UsageInstance1.Data);
			If Not IsBlankString(MetaPresentation) Then
				Presentation = Presentation + " (" + MetaPresentation + ")";
			EndIf;
			
		ElsIf RecordKeysType.ContainsType(DataType) Then
			Presentation = UsageInstance1.Metadata.RecordPresentation;
			If IsBlankString(Presentation) Then
				Presentation = UsageInstance1.Metadata.Presentation();
			EndIf;
			
			DimensionsDetails = New Array;
			For Each MetadataExceptionAttributes In RecordSetDimensionsDetails(UsageInstance1.Metadata, RegisterDimensionCache) Do
				Value = UsageInstance1.Data[MetadataExceptionAttributes.Key];
				LongDesc = MetadataExceptionAttributes.Value;
				If UsageInstance1.Ref = Value Then
					If LongDesc.Master Then
						IsAuxiliaryData = True;
					EndIf;
				EndIf;
				If Not IsInternalData Then // 
					ValueFormat = LongDesc.Format; 
					DimensionsDetails.Add(LongDesc.Presentation + " """ 
						+ ?(ValueFormat = Undefined, String(Value), Format(Value, ValueFormat)) + """");
				EndIf;
			EndDo;
			
			If DimensionsDetails.Count() > 0 Then
				Presentation = Presentation + " (" + StrConcat(DimensionsDetails, ", ") + ")";
			EndIf;
			
		Else
			Presentation = String(UsageInstance1.Data);
		EndIf;
		
		UsageInstance1.DataPresentation = Presentation;
		UsageInstance1.AuxiliaryData = IsAuxiliaryData;
		UsageInstance1.IsInternalData = IsInternalData;
		UsageInstance1.RefType = TypeOf(UsageInstance1.Ref);
	EndDo;
	
	If Not IsBlankString(ResultAddress) Then
		PutToTempStorage(UsageInstances, ResultAddress);
	EndIf;
	
	Return UsageInstances;
EndFunction

// Returns the structure for the parameter Additional parameters of the General purpose function.Places of use. 
// 
// Returns:
//   Structure:
//   * AdditionalRefSearchExceptions - Map -  allows you to extend link search exceptions
// 			See CommonOverridable.OnAddReferenceSearchExceptions
//   * CancelRefsSearchExceptions - Array of MetadataObject -  fully repeals the exception of references search for
//                                                                 metadata objects.
//
Function UsageInstancesSearchParameters() Export

	SearchParameters = New Structure;
	SearchParameters.Insert("AdditionalRefSearchExceptions", New Map);
	SearchParameters.Insert("CancelRefsSearchExceptions", New Map);

	Return SearchParameters;

EndFunction

// Returns exceptions when searching for places where objects are used.
//
// Returns:
//   Map of KeyAndValue - :
//       * Key - MetadataObject -  the metadata object that exceptions are applied to.
//       * Value - String
//                  - Array of String - 
//           
//           
//
Function RefSearchExclusions() Export
	
	SearchExceptionsIntegration = New Array;
	SSLSubsystemsIntegration.OnAddReferenceSearchExceptions(SearchExceptionsIntegration);
	
	SearchExceptions = New Array;
	CommonClientServer.SupplementArray(SearchExceptions, SearchExceptionsIntegration);
	CommonOverridable.OnAddReferenceSearchExceptions(SearchExceptions);
	
	Result = New Map;
	For Each SearchException In SearchExceptions Do
		// 
		If TypeOf(SearchException) = Type("String") Then
			FullName          = SearchException;
			SubstringsArray     = StrSplit(FullName, ".");
			SubstringCount = SubstringsArray.Count();
			MetadataObject   = MetadataObjectByFullName(SubstringsArray[0] + "." + SubstringsArray[1]);
		Else
			MetadataObject   = SearchException;
			FullName          = MetadataObject.FullName();
			SubstringsArray     = StrSplit(FullName, ".");
			SubstringCount = SubstringsArray.Count();
			If SubstringCount > 2 Then
				While True Do
					Parent = MetadataObject.Parent();
					If TypeOf(Parent) = Type("ConfigurationMetadataObject") Then
						Break;
					Else
						MetadataObject = Parent;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
		// 
		If SubstringCount < 4 Then
			Result.Insert(MetadataObject, "*");
		Else
			PathsToAttributes = Result.Get(MetadataObject);
			If PathsToAttributes = "*" Then
				Continue; // 
			ElsIf PathsToAttributes = Undefined Then
				PathsToAttributes = New Array;
				Result.Insert(MetadataObject, PathsToAttributes);
			EndIf;
			// 
			//   
			//   
			//     
			//     
			//     
			// 
			//   
			If SubstringCount = 4 Then
				RelativePathToAttribute = SubstringsArray[3];
			Else
				RelativePathToAttribute = SubstringsArray[3] + "." + SubstringsArray[5];
			EndIf;
			PathsToAttributes.Add(RelativePathToAttribute);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// 
//
// 
// 
// 
//	
//	
//	  
//	   See Common.SubordinateObjectsLinksByTypes  
//	  
//
// Returns:
//  ValueTable:
//    * SubordinateObject - MetadataObject -  
//    * LinksFields - String - 
//    * OnSearchForReferenceReplacement - String -  
//                              
//    * RunReferenceReplacementsAutoSearch - Boolean -  
//                               
//                              
//
Function SubordinateObjects() Export
	
	LinksDetails = New ValueTable;
	LinksDetails.Columns.Add("SubordinateObject", New TypeDescription("MetadataObject"));
	LinksDetails.Columns.Add("LinksFields");
	LinksDetails.Columns.Add("OnSearchForReferenceReplacement", StringTypeDetails(0));
	LinksDetails.Columns.Add("RunReferenceReplacementsAutoSearch", New TypeDescription("Boolean"));
	
	SSLSubsystemsIntegration.OnDefineSubordinateObjects(LinksDetails);
	CommonOverridable.OnDefineSubordinateObjects(LinksDetails);
	
	// 
	For Each LinkRow In LinksDetails Do
		
		LinkFieldsDetailsType = TypeOf(LinkRow.LinksFields);
		If LinkFieldsDetailsType = Type("Structure")
			Or LinkFieldsDetailsType = Type("Map") Then
			
			LinksFieldsAsString = "";
			For Each KeyValue In LinkRow.LinksFields Do
				LinksFieldsAsString = LinksFieldsAsString + KeyValue.Key + ",";		
			EndDo;
			StringFunctionsClientServer.DeleteLastCharInString(LinksFieldsAsString,1);
			LinkRow.LinksFields = LinksFieldsAsString;
			
		EndIf;
		
		If LinkFieldsDetailsType = Type("Array") Then
			LinkRow.LinksFields = StrConcat(LinkRow.LinksFields, ","); 	
		EndIf;
	
	EndDo;
	
	Return LinksDetails;
	
EndFunction

// Returns relationships of subordinate objects with the type of relationship field specified.
//
// Returns:
//   ValueTable:
//    * Key - String
//    * AttributeType - Type
//    * AttributeName - String
//    * Used - Boolean
//    * Metadata - MetadataObject
//
Function SubordinateObjectsLinksByTypes() Export

	Result = New ValueTable;
	Result.Columns.Add("AttributeType", New TypeDescription("Type"));
	Result.Columns.Add("AttributeName", StringTypeDetails(0));
	Result.Columns.Add("Key", StringTypeDetails(0));
	Result.Columns.Add("Used", New TypeDescription("Boolean"));
	Result.Columns.Add("Metadata");
	
	Return Result;

EndFunction 

#EndRegion

#Region ConditionCalls

////////////////////////////////////////////////////////////////////////////////
// 

// 
// 
//
// 
// 
// 
//
// Parameters:
//  FullSubsystemName - String -  the full name of the subsystem metadata object
//                        without the words " Subsystem."and case-sensitive.
//                        For example: "Standard subsystems.Variants of reports".
//
// Example:
//  
//  	
//  	
//  
//
// Returns:
//  Boolean
//
Function SubsystemExists(FullSubsystemName) Export
	
	SubsystemsNames = StandardSubsystemsCached.SubsystemsNames();
	Return SubsystemsNames.Get(FullSubsystemName) <> Undefined;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  Name - String -  
//                 
//
// Returns:
//   CommonModule
//   Object Manager Module
//
// Example:
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
Function CommonModule(Name) Export
	
	If Metadata.CommonModules.Find(Name) <> Undefined Then
		// 
		SetSafeMode(True);
		Module = Eval(Name);
		// 
	ElsIf StrOccurrenceCount(Name, ".") = 1 Then
		Return ServerManagerModule(Name);
	Else
		Module = Undefined;
	EndIf;
	
	If TypeOf(Module) <> Type("CommonModule") Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid parameter %1 in %2. Common module ""%1"" does not exist.';"), 
			"Name", "Common.CommonModule", Name), 
			ErrorCategory.ConfigurationError);
	EndIf;
	
	Return Module;
	
EndFunction

#EndRegion

#Region CurrentEnvironment

////////////////////////////////////////////////////////////////////////////////
// 

// Returns True if the client application is running on Windows.
//
// Returns:
//  Boolean - 
//
Function IsWindowsClient() Export
	
	SetPrivilegedMode(True);
	
	IsWindowsClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsWindowsClient");
	
	If IsWindowsClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsWindowsClient;
	
EndFunction

// Returns True if the current session is running on a server running Windows.
//
// Returns:
//  Boolean - 
//
Function IsWindowsServer() Export
	
	SystemInfo = New SystemInfo;
	Return SystemInfo.PlatformType = PlatformType.Windows_x86 
		Or SystemInfo.PlatformType = PlatformType.Windows_x86_64;
	
EndFunction

// Returns True if the client application is running under Linux.
//
// Returns:
//  Boolean - 
//
Function IsLinuxClient() Export
	
	SetPrivilegedMode(True);
	
	IsLinuxClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsLinuxClient");
	
	If IsLinuxClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsLinuxClient;
	
EndFunction

// Returns True if the current session is running on a server running Linux.
//
// Returns:
//  Boolean - 
//
Function IsLinuxServer() Export
	
	SystemInfo = New SystemInfo;
	Return SystemInfo.PlatformType = PlatformType.Linux_x86
		Or SystemInfo.PlatformType = PlatformType.Linux_x86_64
		Or CommonClientServer.CompareVersions(SystemInfo.AppVersion, "8.3.22.1923") >= 0
			And (SystemInfo.PlatformType = PlatformType["Linux_ARM64"]
			Or SystemInfo.PlatformType = PlatformType["Linux_E2K"]);
	
EndFunction

// Returns True if the client application is running under MacOS.
//
// Returns:
//  Boolean - 
//
Function IsMacOSClient() Export
	
	SetPrivilegedMode(True);
	
	IsMacOSClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsMacOSClient");
	
	If IsMacOSClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsMacOSClient;
	
EndFunction

// Returns True if the client application is a Web client.
//
// Returns:
//  Boolean - 
//
Function IsWebClient() Export
	
	SetPrivilegedMode(True);
	IsWebClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsWebClient");
	
	If IsWebClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsWebClient;
	
EndFunction

// Returns True if the client application is a mobile client.
//
// Returns:
//  Boolean - 
//
Function IsMobileClient() Export
	
	SetPrivilegedMode(True);
	
	IsMobileClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsMobileClient");
	
	If IsMobileClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsMobileClient;
	
EndFunction

// Returns True if the client application is connected to the database via a web server.
//
// Returns:
//  Boolean - 
//
Function ClientConnectedOverWebServer() Export
	
	SetPrivilegedMode(True);
	
	InfoBaseConnectionString = StandardSubsystemsServer.ClientParametersAtServer().Get("InfoBaseConnectionString");
	
	If InfoBaseConnectionString = Undefined Then
		Return False; // 
	EndIf;
	
	Return StrFind(Upper(InfoBaseConnectionString), "WS=") = 1;
	
EndFunction

// 
// 
//
// Returns:
//  FixedStructure:
//    * OSVersion - String
//    * AppVersion - String
//    * ClientID - UUID
//    * UserAgentInformation - String
//    * RAM - Number
//    * Processor - String
//    * PlatformType - See CommonClientServer.NameOfThePlatformType
//  
//   
//   
//
Function ClientSystemInfo() Export
	
	SetPrivilegedMode(True);
	Return StandardSubsystemsServer.ClientParametersAtServer().Get("SystemInfo");
	
EndFunction

// 
// 
//
// Returns:
//  String - 
//           
//           
//           
//  
//   
//   
//
Function ClientUsed() Export
	
	SetPrivilegedMode(True);
	Return StandardSubsystemsServer.ClientParametersAtServer().Get("ClientUsed");
	
EndFunction

// Returns True if debugging mode is enabled.
//
// Returns:
//  Boolean - 
//
Function DebugMode() Export
	
	ApplicationStartupParameter = StandardSubsystemsServer.ClientParametersAtServer(False).Get("LaunchParameter");
	
	Return StrFind(ApplicationStartupParameter, "DebugMode") > 0;
	
EndFunction

// Returns the amount of RAM available to the client application.
//
// Returns:
//  Number - 
//  
//
Function RAMAvailableForClientApplication() Export
	
	AvailableMemorySize = StandardSubsystemsServer.ClientParametersAtServer().Get("RAM");
	Return AvailableMemorySize;
	
EndFunction

// Defines the operation mode of the information database: file (True) or server (False).
// When checking, the information database connection String is used, which can be specified explicitly.
//
// Parameters:
//  InfoBaseConnectionString - String -  this parameter is used if
//                 you need to check the connection string of a non-current database.
//
// Returns:
//  Boolean - 
//
Function FileInfobase(Val InfoBaseConnectionString = "") Export
	
	If IsBlankString(InfoBaseConnectionString) Then
		Return StandardSubsystemsCached.FileInfobase();
	EndIf;
	
	Return StrFind(Upper(InfoBaseConnectionString), "FILE=") = 1;
	
EndFunction 

// Returns True if this information base is connected to 1C: Fresh.
//
// Returns:
//  Boolean - 
//
Function IsStandaloneWorkplace() Export
	
	If SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = CommonModule("DataExchangeServer");
		Return ModuleDataExchangeServer.IsStandaloneWorkplace();
	EndIf;
	
	Return False;
	
EndFunction

// 
//
// Returns:
//   Boolean
//
Function IsDistributedInfobase() Export
	
	SetPrivilegedMode(True);
	Return StandardSubsystemsCached.DIBUsed();
	
EndFunction

// Determines that this information base is a subordinate node
// of the distributed information base (rib).
//
// Returns: 
//  Boolean - 
//
Function IsSubordinateDIBNode() Export
	
	SetPrivilegedMode(True);
	
	Return ExchangePlans.MasterNode() <> Undefined;
	
EndFunction

// Determines that this information base is a subordinate node
// of a distributed information base (rib) with a filter.
//
// Returns: 
//  Boolean - 
//
Function IsSubordinateDIBNodeWithFilter() Export
	
	SetPrivilegedMode(True);
	
	If ExchangePlans.MasterNode() <> Undefined
		And SubsystemExists("StandardSubsystems.DataExchange") Then
		ModuleDataExchangeServer = CommonModule("DataExchangeServer");
		If ModuleDataExchangeServer.ExchangePlanPurpose(ExchangePlans.MasterNode().Metadata().Name) = "DIBWithFilter" Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
	
EndFunction

// Returns True if the configuration of the information base of the subordinate rib node needs to be updated.
// The master node is always False.
//
// Returns: 
//  Boolean - 
//
Function SubordinateDIBNodeConfigurationUpdateRequired() Export
	
	Return IsSubordinateDIBNode() And ConfigurationChanged();
	
EndFunction

// Returns a flag for working in the data division mode by area
// (technically, this is a sign of conditional division).
// 
// Returns False if the configuration can't work in data separation mode
// (it doesn't contain General details intended for data separation).
//
// Returns:
//  Boolean - 
//           
//
Function DataSeparationEnabled() Export
	
	Return StandardSubsystemsCached.DataSeparationEnabled();
	
EndFunction

// Returns whether split data (which is part of separators) can be accessed.
// This attribute is specific to the session, but may change during the session if partitioning was enabled
// in the session itself, so you should check it immediately before accessing the split data.
// 
// Returns True if the configuration can't work in data separation mode
// (it doesn't contain any General details intended for data separation).
//
// Returns:
//   Boolean - 
//                    
//            
//
Function SeparatedDataUsageAvailable() Export
	
	Return StandardSubsystemsCached.SeparatedDataUsageAvailable();
	
EndFunction

// Returns the publication address of the information base for generating direct links to information security objects 
// for users who have access to the database through the publication on the Internet to go to them.
// For example, if you include such an address in an email, you can go from the email with a single click
// to the object form in the program itself.
// 
// Returns:
//   String - 
//            
//            
//
// Example: 
//  General purpose.Adresspublicationinformation baselocal network () + " / " + e1cib/app/Processing.Viruskrankheiten";
//  returns a direct link to open processing Viruskrankheiten.
//
Function InfobasePublicationURL() Export
	
	SetPrivilegedMode(True);
	Result = Constants.InfobasePublicationURL.Get();
	If DataSeparationEnabled() And SeparatedDataUsageAvailable() Then 
		If IsBlankString(Result)
			And SubsystemExists("CloudTechnology.Core")
			And SubsystemExists("CloudTechnology.ExternalAPI") Then

			ModuleSaaSOperations = CommonModule("SaaSOperations");
			ModuleServiceProgrammingInterface = CommonModule("ServiceProgrammingInterface");
			SessionSeparator = ModuleSaaSOperations.SessionSeparatorValue();
			Try
				Result = ModuleServiceProgrammingInterface.ApplicationProperties(SessionSeparator).ApplicationURL;
			Except
				WriteLogEvent(NStr("en = 'Publication address';", DefaultLanguageCode()), //  
					EventLogLevel.Warning,,, 
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Return "";
			EndTry;
			Constants.InfobasePublicationURL.Set(Result);
		EndIf;
		Return Result;
	EndIf;	
	Return Result;
	
EndFunction

//  
// 
// 
// 
// 
// 
// 
// Returns:
//   String - 
//            
//            
//
// Example: 
//  General purpose.Adresspublicationinformation baselocal network () + " / " + e1cib/app/Processing.Viruskrankheiten";
//  returns a direct link to open processing Viruskrankheiten.
//
Function LocalInfobasePublishingURL() Export
	
	If DataSeparationEnabled() And SeparatedDataUsageAvailable() Then 
		Return InfobasePublicationURL();
	EndIf;

	SetPrivilegedMode(True);
	Return Constants.LocalInfobasePublishingURL.Get();
	
EndFunction

// Generates a link to log in to the program for the specified user.
//
// Parameters:
//  User - String -  user's login to log in to the program;
//  Password - String -  user password to log in to the program;
//  IBPublicationType - String - :
//                           
//
// Returns:
//  String, Undefined - 
//
Function ProgrammAuthorizationAddress(User, Password, IBPublicationType) Export
	
	Result = "";
	
	If Lower(IBPublicationType) = Lower("InInternet") Then
		Result = InfobasePublicationURL();
	ElsIf Lower(IBPublicationType) = Lower("InLocalNetwork") Then
		Result = LocalInfobasePublishingURL();
	EndIf;
	
	If IsBlankString(Result) Then
		Return Undefined;
	EndIf;
	
	If Not StrEndsWith(Result, "/") Then
		Result = Result + "/";
	EndIf;
	
	Result = Result + "?n=" + EncodeString(User, StringEncodingMethod.URLEncoding);
	If ValueIsFilled(Password) Then
		Result = Result + "&p=" + EncodeString(Password, StringEncodingMethod.URLEncoding);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the configuration revision.
// The first two groups of digits in the full version of the configuration are usually called editors.
// For example, the version " 1.2.3.4 "has the revision"1.2".
//
// Returns:
//  String - 
//
Function ConfigurationRevision() Export
	
	Result = "";
	ConfigurationVersion = Metadata.Version;
	
	Position = StrFind(ConfigurationVersion, ".");
	If Position > 0 Then
		Result = Left(ConfigurationVersion, Position);
		ConfigurationVersion = Mid(ConfigurationVersion, Position + 1);
		Position = StrFind(ConfigurationVersion, ".");
		If Position > 0 Then
			Result = Result + Left(ConfigurationVersion, Position - 1);
		Else
			Result = "";
		EndIf;
	EndIf;
	
	If IsBlankString(Result) Then
		Result = Metadata.Version;
	EndIf;
	
	Return Result;
	
EndFunction

// 
// 
// Parameters:
//   ShouldReturnCachedValue - Boolean -  the service parameter.
//
// Returns:
//   See CommonOverridable.OnDetermineCommonCoreParameters.CommonParameters
//
Function CommonCoreParameters(ShouldReturnCachedValue = True) Export
	
	If ShouldReturnCachedValue Then
		Return StandardSubsystemsCached.CommonCoreParameters();
	EndIf;

	Result = New Structure;
	Result.Insert("PersonalSettingsFormName", "");
	Result.Insert("AskConfirmationOnExit", True);
	Result.Insert("RecommendedRAM", 4);
	Result.Insert("MinPlatformVersion", MinPlatformVersion());
	Result.Insert("RecommendedPlatformVersion", Result.MinPlatformVersion);
	Result.Insert("ShouldIncludeFullStackInLongRunningOperationErrors", False);
	Result.Insert("DisableMetadataObjectsIDs", False);
	// 
	Result.Insert("MinPlatformVersion1", "");
	Result.Insert("MustExit", False); // 
	
	CommonOverridable.OnDetermineCommonCoreParameters(Result);
	Result.MinPlatformVersion = BuildNumberForTheCurrentPlatformVersion(Result.MinPlatformVersion);
	Result.RecommendedPlatformVersion = BuildNumberForTheCurrentPlatformVersion(Result.RecommendedPlatformVersion);
	
	
	SystemInfo = New SystemInfo;
	If CommonClientServer.CompareVersions(SystemInfo.AppVersion, Result.MinPlatformVersion) < 0
		And IsVersionOfProtectedComplexITSystem(SystemInfo.AppVersion) Then
		Result.MinPlatformVersion = SystemInfo.AppVersion;
		Result.RecommendedPlatformVersion = SystemInfo.AppVersion;
	EndIf;
	
	Min   = Result.MinPlatformVersion;
	Recommended = Result.RecommendedPlatformVersion;
	If IsMinRecommended1CEnterpriseVersionInvalid(Min, Recommended) Then
		MessageText = NStr("en = 'The minimum and recommended platform versions specified in %1 do not meet the following requirements:
			| - The minimum version must be filled.
			| - The minimum version cannot be earlier than the minimum SSL version (see %2).
			| - The minimum version cannot be earlier than the recommended version.
			|Minimum version: %3
			|Minimum SSL version: %4
			|Recommended version: %5';",
			DefaultLanguageCode());
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
			"CommonOverridable.OnDetermineCommonCoreParameters",
			"Common.MinPlatformVersion",
			Min, BuildNumberForTheCurrentPlatformVersion(MinPlatformVersion()), Recommended);
		WriteLogEvent(NStr("en = 'Core';", DefaultLanguageCode()), EventLogLevel.Warning,,, 
			MessageText);		
	EndIf;
	
	// 
	MinPlatformVersion1 = Result.MinPlatformVersion1;
	If ValueIsFilled(MinPlatformVersion1) Then
		If Result.MustExit Then
			Result.MinPlatformVersion   = MinPlatformVersion1;
			Result.RecommendedPlatformVersion = "";
		Else
			Result.RecommendedPlatformVersion = MinPlatformVersion1;
			Result.MinPlatformVersion   = "";
		EndIf;
	Else
		Current = SystemInfo.AppVersion;
		If CommonClientServer.CompareVersions(Min, Current) > 0 Then
			Result.MinPlatformVersion1 = Min;
			Result.MustExit = True;
		Else
			Result.MinPlatformVersion1 = Recommended;
			Result.MustExit = False;
		EndIf;
	EndIf;
	
	ClarifyPlatformVersion(Result);
	
	Return Result;
	

EndFunction

// Returns descriptions of all configuration libraries, including
// a description of the configuration itself.
//
// Returns:
//  Array - :
//     * Name                            - String -  name of the subsystem, for example, "standard Subsystems".
//     * OnlineSupportID - String - 
//     * Version                         - String -  version in a four-digit format, such as "2.3.3.1".
//     * IsConfiguration                - Boolean -  indicates that this subsystem is the primary configuration.
//
Function SubsystemsDetails() Export
	Result = New Array;
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemDetails In SubsystemsDetails.ByNames Do
		Parameters = New Structure;
		Parameters.Insert("Name");
		Parameters.Insert("OnlineSupportID");
		Parameters.Insert("Version");
		Parameters.Insert("IsConfiguration");
		
		FillPropertyValues(Parameters, SubsystemDetails.Value);
		Result.Add(Parameters);
	EndDo;
	
	Return Result;
EndFunction

// Returns the ID of the Internet support for the main configuration.
//
// Returns:
//  String -  unique name of the program in Internet support services.
//
Function ConfigurationOnlineSupportID() Export
	SubsystemsDetails = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemDetails In SubsystemsDetails.ByNames Do
		If SubsystemDetails.Value.IsConfiguration Then
			Return SubsystemDetails.Value.OnlineSupportID;
		EndIf;
	EndDo;
	
	Return "";
EndFunction

#EndRegion

#Region Dates

////////////////////////////////////////////////////////////////////////////////
// 

// Converts a local date to the format" YYYY-MM-DDThh:mm:ssTZD " according to ISO 8601.
//
// Parameters:
//  LocalDate - Date -  date in the session's time zone.
// 
// Returns:
//   String - 
//
Function LocalDatePresentationWithOffset(LocalDate) Export
	
	Offset = StandardTimeOffset(SessionTimeZone());
	Return CommonInternalClientServer.LocalDatePresentationWithOffset(LocalDate, Offset);
	
EndFunction

// Returns a string representation of the interval between the transmitted dates or
// relative to the transmitted date and the current session date.
//
// Parameters:
//  BeginTime    - Date -  starting point of the interval.
//  EndTime - Date -  end point of the interval, if not specified, the current session date is taken.
//
// Returns:
//  String - 
//
Function TimeIntervalString(BeginTime, EndTime = Undefined) Export
	
	If EndTime = Undefined Then
		EndTime = CurrentSessionDate();
	ElsIf BeginTime > EndTime Then
		Raise NStr("en = 'The end date cannot be earlier than the start date.';");
	EndIf;
	
	IntervalValue = EndTime - BeginTime;
	IntervalValueInDays = Int(IntervalValue/60/60/24);
	
	If IntervalValueInDays > 365 Then
		IntervalDetails = NStr("en = 'more than a year';");
	ElsIf IntervalValueInDays > 31 Then
		IntervalDetails = NStr("en = 'more than a month';");
	ElsIf IntervalValueInDays >= 1 Then
		IntervalDetails = Format(IntervalValueInDays, "NFD=0") + " "
			+ UsersInternalClientServer.IntegerSubject(IntervalValueInDays,
				"", NStr("en = 'day,days,,,0';"));
	Else
		IntervalDetails = NStr("en = 'less than a day';");
	EndIf;
	
	Return IntervalDetails;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Saves the user's work date setting.
//
// Parameters:
//  NewWorkingDate - Date -  the date to set as the user's work date.
//  UserName - String -  name of the user to set the working date for.
//		If omitted, it is set for the current user.
//			
Procedure SetUserWorkingDate(NewWorkingDate, UserName = Undefined) Export

	ObjectKey = Upper("WorkingDate");
	
	CommonSettingsStorageSave(ObjectKey, "", NewWorkingDate, , UserName);

EndProcedure

// Returns the value of the work date setting for the user.
//
// Parameters:
//  UserName - String -  name of the user for whom the work date is requested.
//		If omitted, it is set for the current user.
//
// Returns:
//  Date - 
//
Function UserWorkingDate(UserName = Undefined) Export

	ObjectKey = Upper("WorkingDate");

	Result = CommonSettingsStorageLoad(ObjectKey, "", '0001-01-01', , UserName);
	
	If TypeOf(Result) <> Type("Date") Then
		Result = '0001-01-01';
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the value of the user's work date setting, or the current session date
// if the user's work date is not set.
//
// Parameters:
//  UserName - String -  name of the user for whom the work date is requested.
//		If omitted, it is set for the current user.
//
// Returns:
//  Date - 
//
Function CurrentUserDate(UserName = Undefined) Export

	Result = UserWorkingDate(UserName);
	
	If Not ValueIsFilled(Result) Then
		Result = CurrentSessionDate();
	EndIf;
	
	Return BegOfDay(Result);
	
EndFunction

#EndRegion

#Region Data

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the string name of the enumeration value by its reference.
// Throws an exception if a nonexistent enumeration value is passed 
// (for example, one that was deleted in the configuration or from a disabled configuration extension).
//
// Parameters:
//  Value - EnumRef -  the value for which you want to retrieve the name of the enumeration.
//
// Returns:
//  String
//
// Example:
//   The result will contain the string value "physical Person":
//   Result = General Values.Number_name (Enumeration.Legal and physical person.Physical person);
//
Function EnumerationValueName(Value) Export
	
	MetadataObject = Value.Metadata();
	ValueIndex = Enums[MetadataObject.Name].IndexOf(Value);
	Return MetadataObject.EnumValues[ValueIndex].Name;
	
EndFunction 

// The procedure removes the elements corresponding to the names 
// of the object's details from the array of array-Verifiedrequisits from the array array.
// For use in the event handlers of Obrabatyvaniya.
//
// Parameters:
//  AttributesArray              - Array -  collection of names and details of the object.
//  NotCheckedAttributeArray - Array -  collection of names of object details that do not require verification.
//
Procedure DeleteNotCheckedAttributesFromArray(AttributesArray, NotCheckedAttributeArray) Export
	
	For Each ArrayElement In NotCheckedAttributeArray Do
	
		SequenceNumber = AttributesArray.Find(ArrayElement);
		If SequenceNumber <> Undefined Then
			AttributesArray.Delete(SequenceNumber);
		EndIf;
	
	EndDo;
	
EndProcedure

// Converts a table of values to an array of structures.
// It can be used for transmitting data to the client if the table
// it contains only values that can
// be passed from the server to the client.
//
// The resulting array contains structures, each of which repeats
// the structure of columns in the table of values.
//
// It is not recommended to use it for converting tables of values
// with a large number of rows.
//
// Parameters:
//  ValueTable - ValueTable -  the original table of values.
//
// Returns:
//  Array - 
//
Function ValueTableToArray(ValueTable) Export
	
	Array = New Array();
	StructureString = "";
	CommaRequired = False;
	For Each Column In ValueTable.Columns Do
		If CommaRequired Then
			StructureString = StructureString + ",";
		EndIf;
		StructureString = StructureString + Column.Name;
		CommaRequired = True;
	EndDo;
	For Each TableRow In ValueTable Do
		NewRow = New Structure(StructureString);
		FillPropertyValues(NewRow, TableRow);
		Array.Add(NewRow);
	EndDo;
	Return Array;

EndFunction

// Converts a row in the value table to a structure.
// The structure properties and their values match the columns of the passed string.
//
// Parameters:
//  ValueTableRow - ValueTableRow
//
// Returns:
//  Structure - 
//
Function ValueTableRowToStructure(ValueTableRow) Export
	
	Structure = New Structure;
	For Each Column In ValueTableRow.Owner().Columns Do
		Structure.Insert(Column.Name, ValueTableRow[Column.Name]);
	EndDo;
	
	Return Structure;
	
EndFunction

// Creates a structure containing the names and values of dimensions, resources, and details
// of the passed information register record Manager.
//
// Parameters:
//  RecordManager     - InformationRegisterRecordManagerInformationRegisterName -  the record Manager to get the structure from.
//  RegisterMetadata - MetadataObjectInformationRegister -  metadata of the information register.
//
// Returns:
//  Structure - 
//
Function StructureByRecordManager(RecordManager, RegisterMetadata) Export
	
	RecordAsStructure = New Structure;
	
	If RegisterMetadata.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		RecordAsStructure.Insert("Period", RecordManager.Period);
	EndIf;
	For Each Field In RegisterMetadata.Dimensions Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Resources Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	For Each Field In RegisterMetadata.Attributes Do
		RecordAsStructure.Insert(Field.Name, RecordManager[Field.Name]);
	EndDo;
	
	Return RecordAsStructure;
	
EndFunction

// Creates an array and copies to it the values contained in the column of the object
// that can be traversed using the operator for each ... From.
//
// Parameters:
//  RowsCollection           - ValueTable
//                           - ValueTree
//                           - ValueList
//                           - TabularSection
//                           - Map
//                           - Structure - 
//                                         
//                                         
//  ColumnName               - String -  the field name of the collection whose values should be loaded.
//  UniqueValuesOnly - Boolean -  if True,
//                                      only different values will be included in the array.
//
// Returns:
//  Array - 
//
Function UnloadColumn(RowsCollection, ColumnName, UniqueValuesOnly = False) Export

	ArrayOfValues = New Array;
	
	UniqueValues = New Map;
	
	For Each CollectionRow In RowsCollection Do
		Value = CollectionRow[ColumnName];
		If UniqueValuesOnly And UniqueValues[Value] <> Undefined Then
			Continue;
		EndIf;
		ArrayOfValues.Add(Value);
		UniqueValues.Insert(Value, True);
	EndDo; 
	
	Return ArrayOfValues;
	
EndFunction

// Converts text in the specified XML format to a table of values,
// and the table columns are formed based on the description in XML.
//
// XML schema:
// <? xml version= "1.0" encoding= "utf-8"?>
//  <xs:schema attributeFormDefault="unqualified" elementFormDefault=" qualified " xmlns:xs="http://www.w3.org/2001/XMLSchema">
//   <xs:element name="Items">
//    <xs:complexType>
//     <xs:sequence>
//      <xs:element maxOccurs="unbounded" name="Item">
//       <xs:complexType>
//        <xs:attribute name="Code" type="xs:integer" use="required" />
//        <xs:attribute name="Name" type="xs:string" use="required" />
//        <xs:attribute name="Socr" type="xs:string" use="required" />
//        <xs:attribute name="Index" type="xs:string" use="required" />
//       </xs:complexType>
//      </xs:element>
//     </xs:sequence>
//    <xs:attribute name="Description" type="xs:string" use="required" />
//    <xs:attribute name="Columns" type="xs:string" use="required" />
//   </xs:complexType>
//  </xs:element>
// </xs:schema>
//
// Parameters:
//  XML - String
//      - XMLReader - 
//
// Returns:
//  Structure:
//   * TableName - String          -  table name.
//   * Data     - ValueTable -  converted from an XML table.
//
// Example:
//   Classifier Table = General purpose.Read the XML table(
//     Processing.The download of the courses is complete.Get a package ("All-Russian Classifier of the currency").Get the text()).Data;
//
Function ReadXMLToTable(Val XML) Export
	
	If TypeOf(XML) <> Type("XMLReader") Then
		Read = New XMLReader;
		Read.SetString(XML);
	Else
		Read = XML;
	EndIf;
	
	// 
	If Not Read.Read() Then
		Raise NStr("en = 'The XML file is empty. Data couldn''t be imported.';");
	ElsIf Read.Name <> "Items" Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t export data from the XML file. The file is missing a required tag: ""%1"".';"),
			"Items");
	EndIf;
	
	// 
	TableName = Read.GetAttribute("Description");
	ColumnsNames = StrReplace(Read.GetAttribute("Columns"), ",", Chars.LF);
	Columns1 = StrLineCount(ColumnsNames);
	
	ValueTable = New ValueTable;
	For Cnt = 1 To Columns1 Do
		ValueTable.Columns.Add(StrGetLine(ColumnsNames, Cnt), New TypeDescription("String"));
	EndDo;
	
	// 
	While Read.Read() Do
		
		If Read.NodeType = XMLNodeType.EndElement And Read.Name = "Items" Then
			Break;
		ElsIf Read.NodeType <> XMLNodeType.StartElement Then
			Continue;
		ElsIf Read.Name <> "Item" Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t export data from the XML file. The tag ""%1"" is missing a required tag: ""%2"".';"),
				"Items", "Item");
		EndIf;
		
		NwRw = ValueTable.Add();
		For Cnt = 1 To Columns1 Do
			ColumnName = StrGetLine(ColumnsNames, Cnt);
			NwRw[Cnt-1] = Read.GetAttribute(ColumnName);
		EndDo;
		
	EndDo;
	
	// 
	Result = New Structure;
	Result.Insert("TableName", TableName);
	Result.Insert("Data", ValueTable);
	
	Return Result;
	
EndFunction

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
//  RowsCollection1 - ValueTable
//                  - ValueTree
//                  - ValueList
//                  - TabularSection
//                  - Map
//                  - Array
//                  - FixedArray
//                  - Structure - 
//                     
//  RowsCollection2 - ValueTable
//                  - ValueTree
//                  - ValueList
//                  - TabularSection
//                  - Map
//                  - Array
//                  - FixedArray
//                  - Structure - 
//                     
//  ColumnsNames - String - 
//                          :
//                          
//                          
//                          
//                          
//                          
//                          
//                          
//                          
//  ExcludingColumns - String -  names of columns that are ignored during comparison.
//  UseRowOrder - Boolean -  if True, collections are recognized 
//                      as identical only if the same rows are placed in the same places in the collections.
//
// Returns:
//  Boolean - 
//
Function IdenticalCollections(RowsCollection1, RowsCollection2, Val ColumnsNames = "", Val ExcludingColumns = "", 
	UseRowOrder = False) Export
	
	CollectionType = TypeOf(RowsCollection1);
	ArraysCompared = (CollectionType = Type("Array") Or CollectionType = Type("FixedArray"));
	
	ColumnsToCompare = Undefined;
	If Not ArraysCompared Then
		ColumnsToCompare = ColumnsToCompare(RowsCollection1, ColumnsNames, ExcludingColumns);
	EndIf;
	
	If UseRowOrder Then
		Return SequenceSensitiveToCompare(RowsCollection1, RowsCollection2, ColumnsToCompare);
	ElsIf ArraysCompared Then // 
		Return CompareArrays(RowsCollection1, RowsCollection2);
	Else
		Return SequenceIgnoreSensitiveToCompare(RowsCollection1, RowsCollection2, ColumnsToCompare);
	EndIf;
	
EndFunction

// Compares data of a complex structure with consideration for nesting.
//
// Parameters:
//  Data1 - Structure
//          - FixedStructure
//          - Map
//          - FixedMap
//          - Array
//          - FixedArray
//          - ValueStorage
//          - ValueTable
//          - String
//          - Number
//          - Boolean - 
//  Data2 - Arbitrary -  the same types as for the Data1 parameter.
//
// Returns:
//  Boolean - 
//
Function DataMatch(Data1, Data2) Export
	
	If TypeOf(Data1) <> TypeOf(Data2) Then
		Return False;
	EndIf;
	
	If TypeOf(Data1) = Type("Structure")
	 Or TypeOf(Data1) = Type("FixedStructure") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		For Each KeyAndValue In Data1 Do
			PreviousValue2 = Undefined;
			
			If Not Data2.Property(KeyAndValue.Key, PreviousValue2)
			 Or Not DataMatch(KeyAndValue.Value, PreviousValue2) Then
			
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Map")
	      Or TypeOf(Data1) = Type("FixedMap") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		NewMapKeys = New Map;
		
		For Each KeyAndValue In Data1 Do
			NewMapKeys.Insert(KeyAndValue.Key, True);
			PreviousValue2 = Data2.Get(KeyAndValue.Key);
			
			If Not DataMatch(KeyAndValue.Value, PreviousValue2) Then
				Return False;
			EndIf;
		EndDo;
		
		For Each KeyAndValue In Data2 Do
			If NewMapKeys[KeyAndValue.Key] = Undefined Then
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Array")
	      Or TypeOf(Data1) = Type("FixedArray") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		IndexOf = Data1.Count()-1;
		While IndexOf >= 0 Do
			If Not DataMatch(Data1.Get(IndexOf), Data2.Get(IndexOf)) Then
				Return False;
			EndIf;
			IndexOf = IndexOf - 1;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueTable") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		If Data1.Columns.Count() <> Data2.Columns.Count() Then
			Return False;
		EndIf;
		
		For Each Column In Data1.Columns Do
			If Data2.Columns.Find(Column.Name) = Undefined Then
				Return False;
			EndIf;
			
			IndexOf = Data1.Count()-1;
			While IndexOf >= 0 Do
				If Not DataMatch(Data1[IndexOf][Column.Name], Data2[IndexOf][Column.Name]) Then
					Return False;
				EndIf;
				IndexOf = IndexOf - 1;
			EndDo;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueStorage") Then
	
		If Not DataMatch(Data1.Get(), Data2.Get()) Then
			Return False;
		EndIf;
		
		Return True;
	EndIf;
	
	Return Data1 = Data2;
	
EndFunction

// Captures data of the Structure, Match, and Array types, taking into account nesting.
//
// Parameters:
//  Data - Structure
//         - Map
//         - Array - 
//           :
//           
//           
//           
//
//  RaiseException1 - Boolean -  the initial value is True. When set to False, then if there
//                                is non-commitable data, the exception will not be raised, and the data will
//                                be fixed for as long as possible.
//
// Returns:
//  FixedStructure, FixedMap, FixedArray - 
//    
// 
Function FixedData(Data, RaiseException1 = True) Export
	
	If TypeOf(Data) = Type("Array") Then
		Array = New Array;
		
		For Each Value In Data Do
			
			If TypeOf(Value) = Type("Structure")
			 Or TypeOf(Value) = Type("Map")
			 Or TypeOf(Value) = Type("Array") Then
				
				Array.Add(FixedData(Value, RaiseException1));
			Else
				If RaiseException1 Then
					CheckFixedData(Value, True);
				EndIf;
				Array.Add(Value);
			EndIf;
		EndDo;
		
		Return New FixedArray(Array);
		
	ElsIf TypeOf(Data) = Type("Structure")
	      Or TypeOf(Data) = Type("Map") Then
		
		If TypeOf(Data) = Type("Structure") Then
			Collection = New Structure;
		Else
			Collection = New Map;
		EndIf;
		
		For Each KeyAndValue In Data Do
			Value = KeyAndValue.Value;
			
			If TypeOf(Value) = Type("Structure")
			 Or TypeOf(Value) = Type("Map")
			 Or TypeOf(Value) = Type("Array") Then
				
				Collection.Insert(
					KeyAndValue.Key, FixedData(Value, RaiseException1));
			Else
				If RaiseException1 Then
					CheckFixedData(Value, True);
				EndIf;
				Collection.Insert(KeyAndValue.Key, Value);
			EndIf;
		EndDo;
		
		If TypeOf(Data) = Type("Structure") Then
			Return New FixedStructure(Collection);
		Else
			Return New FixedMap(Collection);
		EndIf;
		
	ElsIf RaiseException1 Then
		CheckFixedData(Data);
	EndIf;
	
	Return Data;
	
EndFunction

// Calculates a checksum for arbitrary data using the specified algorithm.
//
// Parameters:
//  Data   - Arbitrary -  any serializable value.
//  Algorithm - HashFunction   -  algorithm for calculating the checksum. By default, MD5.
// 
// Returns:
//  String - 
//
Function CheckSumString(Val Data, Val Algorithm = Undefined) Export
	
	If Algorithm = Undefined Then
		Algorithm = HashFunction.MD5;
	EndIf;
	
	DataHashing = New DataHashing(Algorithm);
	If TypeOf(Data) <> Type("String") And TypeOf(Data) <> Type("BinaryData") Then
		Data = ValueToXMLString(Data);
	EndIf;
	DataHashing.Append(Data);
	
	If TypeOf(DataHashing.HashSum) = Type("BinaryData") Then 
		Result = StrReplace(DataHashing.HashSum, " ", "");
	ElsIf TypeOf(DataHashing.HashSum) = Type("Number") Then
		Result = Format(DataHashing.HashSum, "NG=");
	EndIf;
	
	Return Result;
	
EndFunction

// Reduces the string to the desired length, and the truncated part is hashed,
// ensuring that the string is unique. Checks the length of the input string and, if
// the maximum length is exceeded, converts its end using the MD5 algorithm to a
// unique string of 32 characters.
//
// Parameters:
//  String            - String -  source string of any length.
//  MaxLength - Number  -  required maximum number of characters per line,
//                               minimum value: 32.
// 
// Returns:
//   String - 
//
Function TrimStringUsingChecksum(String, MaxLength) Export
	
	If MaxLength < 32 Then
		CommonClientServer.Validate(False, 
		StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'The %1 parameter cannot be less than 32.';"),
			"MaxLength"), "Common.TrimStringUsingChecksum");
	EndIf;
	
	Result = String;
	If StrLen(String) > MaxLength Then
		Result = Left(String, MaxLength - 32);
		DataHashing = New DataHashing(HashFunction.MD5);
		DataHashing.Append(Mid(String, MaxLength - 32 + 1));
		Result = Result + StrReplace(DataHashing.HashSum, " ", "");
	EndIf;
	Return Result;
EndFunction

// Creates a complete copy of a structure, match, array, list, or table of values, recursively,
// with consideration for the types of child elements. However, the contents of object type values are
// (Reference object, document Object, etc.) are not copied, but references to the source object are returned.
//
// Parameters:
//  Source - Structure
//           - FixedStructure
//           - Map
//           - FixedMap
//           - Array
//           - FixedArray
//           - ValueList - 
//  FixData - Boolean       -  if True, fix it, if False, remove the fixation.
//                    - Undefined - 
//
// Returns:
//  Structure, 
//  Fixed Structure,
//  Accordance
//  Fixed Compliance
//  Array
//  Fixed Array
//  The list of values is a copy of the object passed in the Source parameter.
//
Function CopyRecursive(Source, FixData = Undefined) Export
	
	Var Receiver;
	
	SourceType = TypeOf(Source);
	
	If SourceType = Type("ValueTable") Then
		Receiver = Source.Copy();
		CopyValuesFromValTable(Receiver, FixData);
	ElsIf SourceType = Type("ValueTree") Then
		Receiver = Source.Copy();
		CopyValuesFromValTreeRow(Receiver.Rows, FixData);
	ElsIf SourceType = Type("Structure")
		Or SourceType = Type("FixedStructure") Then
		Receiver = CopyStructure(Source, FixData);
	ElsIf SourceType = Type("Map")
		Or SourceType = Type("FixedMap") Then
		Receiver = CopyMap(Source, FixData);
	ElsIf SourceType = Type("Array")
		Or SourceType = Type("FixedArray") Then
		Receiver = CopyArray(Source, FixData);
	ElsIf SourceType = Type("ValueList") Then
		Receiver = CopyValueList(Source, FixData);
	Else
		Receiver = Source;
	EndIf;
	
	Return Receiver;
	
EndFunction

// 
//  
// 
// 
// 
// Parameters:
//  ReferenceToSubject - Arbitrary
//
// Returns:
//   String - 
// 
Function SubjectString(ReferenceToSubject) Export
	
	If ReferenceToSubject <> Undefined Then
		Return SubjectAsString(CommonClientServer.ValueInArray(ReferenceToSubject))[ReferenceToSubject];
	Else
		Return NStr("en = 'not specified';");
	EndIf;
	
EndFunction

// 
//  
// 
// 
// 
// 
// 
// Parameters:
//  RefsToSubjects - Array of AnyRef
//
// Returns:
//   Map of KeyAndValue:
//     * Key - AnyRef
//     * Value - String - 
// 
Function SubjectAsString(Val RefsToSubjects) Export
	
	RefsToCheck = New Array;
	Result = New Map;
	For Each ReferenceToSubject In RefsToSubjects Do
		If ReferenceToSubject = Undefined Then
			Result[ReferenceToSubject] = NStr("en = 'empty';");
		ElsIf Not IsReference(TypeOf(ReferenceToSubject)) Then 
			Result[ReferenceToSubject] = String(ReferenceToSubject);
		ElsIf ReferenceToSubject.IsEmpty() Then	
			Result[ReferenceToSubject] = NStr("en = 'empty';");
		ElsIf Metadata.Enums.Contains(ReferenceToSubject.Metadata()) Then
			Result[ReferenceToSubject] = String(ReferenceToSubject);
		Else
			RefsToCheck.Add(ReferenceToSubject);
		EndIf;
	EndDo;
	
	For Each ExistingRef In RefsPresentations(RefsToCheck) Do
		ReferenceToSubject = ExistingRef.Key;
		Result[ReferenceToSubject] = ExistingRef.Value;
		If Not Metadata.Documents.Contains(ReferenceToSubject.Metadata()) Then
			ObjectPresentation = ReferenceToSubject.Metadata().ObjectPresentation;
			If IsBlankString(ObjectPresentation) Then
				ObjectPresentation = ReferenceToSubject.Metadata().Presentation();
			EndIf;
			Result[ReferenceToSubject] = StringFunctionsClientServer.SubstituteParametersToString("%1 (%2)", 
				Result[ReferenceToSubject], ObjectPresentation);
		EndIf;
	EndDo;
		
	Return Result;
	
EndFunction

// 
//
// Parameters:
//  RefsToCheck - Array of AnyRef, AnyRef
// 
// Returns:
//  Map of KeyAndValue:
//   * Key - AnyRef
//   * Value - String - 
//
Function RefsPresentations(RefsToCheck) Export
	
	ObjectsByType = New Map;
	If TypeOf(RefsToCheck) = Type("Array") Then
		For Each RefToCheck In RefsToCheck Do
			Objects = ObjectsByType[RefToCheck.Metadata()];
			If Objects = Undefined Then
				Objects = New Array;
				ObjectsByType[RefToCheck.Metadata()] = Objects;
			EndIf;
			Objects.Add(RefToCheck);
		EndDo; 
	Else
		ObjectsByType[RefsToCheck.Metadata()] = CommonClientServer.ValueInArray(RefsToCheck);
	EndIf;
	
	Result = New Map;
	If ObjectsByType.Count() = 0 Then
		Return Result;
	EndIf;
	
	Query = New Query;
	QueriesTexts = New Array;
	IndexOf = 0;
	For Each ObjectType In ObjectsByType Do
	
		QueryText = 
			"SELECT ALLOWED
			|	Presentation AS Presentation,
			|	Table.Ref AS Ref
			|FROM
			|	&TableName AS Table
			|WHERE
			|	Table.Ref IN (&Ref)";
		
		If QueriesTexts.Count() > 0 Then
			QueryText = StrReplace(QueryText, "SELECT ALLOWED", "SELECT"); // @query-part-1, @query-part-2
		EndIf;
		QueryText = StrReplace(QueryText, "&TableName", ObjectType.Key.FullName());
		
		ParameterName = "Ref" + Format(IndexOf, "NG=;NZ=");
		QueryText = StrReplace(QueryText, "&Ref", "&" + ParameterName);
		QueriesTexts.Add(QueryText);
		Query.SetParameter(ParameterName, ObjectType.Value);

		IndexOf = IndexOf + 1;
	EndDo;
	
	Query.Text = StrConcat(QueriesTexts, Chars.LF + "UNION ALL" + Chars.LF); // @query-part;
	
	SetPrivilegedMode(True);
	ActualLinks = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	RefsPresentations = Query.Execute().Unload();
	RefsPresentations.Indexes.Add("Ref");
	
	For Each Ref In ActualLinks Do
		If ValueIsFilled(Ref.Ref) Then
			RepresentationOfTheReference = RefsPresentations.Find(Ref.Ref, "Ref");
			Result[Ref.Ref] = ?(RepresentationOfTheReference <> Undefined, 
				RepresentationOfTheReference.Presentation, String(Ref.Ref));
		EndIf;
	EndDo;
	For Each Ref In RefsToCheck Do
		If Result[Ref] = Undefined Then
			Result[Ref] = NStr("en = 'does not exist';");
		EndIf;
	EndDo;
		
	Return Result;
	
EndFunction

#EndRegion

#Region DynamicList

// Creates a structure for the second parameter of the properties of the list of the procedure to set the properties of the dynamic list.
//
// Returns:
//  Structure - :
//     * QueryText - String -  the new text of the request.
//     * MainTable - String -  name of the main table.
//     * DynamicDataRead - Boolean -  indicates whether dynamic reading is used.
//
Function DynamicListPropertiesStructure() Export
	
	Return New Structure("QueryText, MainTable, DynamicDataRead");
	
EndFunction

// To set the text of the query, the underlying table or dynamically loading a dynamic list.
// You should set these properties in a single call to this procedure to avoid performance degradation.
//
// Parameters:
//  List - FormTable -  a dynamic list form element for which properties are set.
//  ListProperties - See DynamicListPropertiesStructure
//
Procedure SetDynamicListProperties(List, ListProperties) Export
	
	Form = List.Parent;
	TypeClientApplicationForm = Type("ClientApplicationForm");
	
	While TypeOf(Form) <> TypeClientApplicationForm Do
		Form = Form.Parent;
	EndDo;
	
	DynamicList = Form[List.DataPath];
	QueryText = ListProperties.QueryText;
	
	If Not IsBlankString(QueryText) Then
		DynamicList.QueryText = QueryText;
	EndIf;
	
	MainTable = ListProperties.MainTable;
	
	If MainTable <> Undefined Then
		DynamicList.MainTable = MainTable;
	EndIf;
	
	DynamicDataRead = ListProperties.DynamicDataRead;
	
	If TypeOf(DynamicDataRead) = Type("Boolean") Then
		DynamicList.DynamicDataRead = DynamicDataRead;
	EndIf;
	
EndProcedure

#EndRegion

#Region ExternalConnection

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the CLSID of the COM class for working with "1C:"8" via COM connection.
//
// Parameters:
//  COMConnectorName - String -  name of the COM class for working with " 1C:"8" via COM connection.
//
// Returns:
//  String - 
//
Function COMConnectorID(Val COMConnectorName) Export
	
	If COMConnectorName = "v83.COMConnector" Then
		Return "181E893D-73A4-4722-B61D-D604B3D67D47";
	EndIf;
	
	Raise(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invalid value of parameter ""%1"" in function ""%2"". CLSID for class ""%3"" is not specified.';"), 
		"COMConnectorName", "Common.COMConnectorID", COMConnectorName),
		ErrorCategory.ConfigurationError);
	
EndFunction

// Sets up an external connection to the database based on the passed connection parameters and returns a pointer
// to this connection.
// 
// Parameters:
//  Parameters - See CommonClientServer.ParametersStructureForExternalConnection
// 
// Returns:
//  Structure:
//    * Join - COMObject
//                 - Undefined - 
//    * BriefErrorDetails - String -  short description of the error;
//    * DetailedErrorDetails - String -  detailed description of the error;
//    * AddInAttachmentError - Boolean -  COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(Parameters) Export
	
	ConnectionNotAvailable = IsLinuxServer();
	BriefErrorDetails = NStr("en = 'Servers on Linux do not support direct infobase connections.';");
	
	Return CommonInternalClientServer.EstablishExternalConnectionWithInfobase(Parameters, ConnectionNotAvailable, BriefErrorDetails);
	
EndFunction

#EndRegion

#Region Metadata

////////////////////////////////////////////////////////////////////////////////
// 

// 

// Defines whether the metadata object belongs to the General "Document" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to documents.
// 
// Returns:
//   Boolean - 
//
Function IsDocument(MetadataObject) Export
	
	Return Metadata.Documents.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General Reference type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsCatalog(MetadataObject) Export
	
	Return Metadata.Catalogs.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General "Enumeration" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsEnum(MetadataObject) Export
	
	Return Metadata.Enums.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General "exchange Plan" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsExchangePlan(MetadataObject) Export
	
	Return Metadata.ExchangePlans.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General "feature types Plan" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsChartOfCharacteristicTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General "Business process" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsBusinessProcess(MetadataObject) Export
	
	Return Metadata.BusinessProcesses.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General "Task" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsTask(MetadataObject) Export
	
	Return Metadata.Tasks.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General chart of accounts type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsChartOfAccounts(MetadataObject) Export
	
	Return Metadata.ChartsOfAccounts.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General type "plan of calculation types".
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsChartOfCalculationTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCalculationTypes.Contains(MetadataObject);
	
EndFunction

// Registers

// Defines whether the metadata object belongs to the General "data Register" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsInformationRegister(MetadataObject) Export
	
	Return Metadata.InformationRegisters.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General "accumulation Register" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsAccumulationRegister(MetadataObject) Export
	
	Return Metadata.AccumulationRegisters.Contains(MetadataObject);
	
EndFunction

// Determines whether the metadata object belongs to the General "accounting Register" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsAccountingRegister(MetadataObject) Export
	
	Return Metadata.AccountingRegisters.Contains(MetadataObject);
	
EndFunction

// Defines whether the metadata object belongs to the General "calculation Register" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsCalculationRegister(MetadataObject) Export
	
	Return Metadata.CalculationRegisters.Contains(MetadataObject);
	
EndFunction

// Constants

// Defines whether the metadata object belongs to the General "Constant" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsConstant(MetadataObject) Export
	
	Return Metadata.Constants.Contains(MetadataObject);
	
EndFunction

// 

// Defines whether the metadata object belongs to the General document Log type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean -  True if the object is a document log.
//
Function IsDocumentJournal(MetadataObject) Export
	
	Return Metadata.DocumentJournals.Contains(MetadataObject);
	
EndFunction

// Sequences

// Defines whether the metadata object belongs to the General "Sequence" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsSequence(MetadataObject) Export
	
	Return Metadata.Sequences.Contains(MetadataObject);
	
EndFunction

// ScheduledJobs

// Defines whether the metadata object belongs to the General "Routine tasks" type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsScheduledJob(MetadataObject) Export
	
	Return Metadata.ScheduledJobs.Contains(MetadataObject);
	
EndFunction

// Overall

// Determines whether the metadata object belongs to the register type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean - 
//
Function IsRegister(MetadataObject) Export
	
	Return Metadata.AccountingRegisters.Contains(MetadataObject)
		Or Metadata.AccumulationRegisters.Contains(MetadataObject)
		Or Metadata.CalculationRegisters.Contains(MetadataObject)
		Or Metadata.InformationRegisters.Contains(MetadataObject);
		
EndFunction

// Defines whether the metadata object belongs to the reference type.
//
// Parameters:
//  MetadataObject - MetadataObject -  the object to determine whether it belongs to the specified type.
// 
// Returns:
//   Boolean -  True if the object is of the reference type.
//
Function IsRefTypeObject(MetadataObject) Export
	
	MetadataObjectName = MetadataObject.FullName();
	Position = StrFind(MetadataObjectName, ".");
	If Position > 0 Then 
		BaseTypeName = Left(MetadataObjectName, Position - 1);
		Return BaseTypeName = "Catalog"
			Or BaseTypeName = "Document"
			Or BaseTypeName = "BusinessProcess"
			Or BaseTypeName = "Task"
			Or BaseTypeName = "ChartOfAccounts"
			Or BaseTypeName = "ExchangePlan"
			Or BaseTypeName = "ChartOfCharacteristicTypes"
			Or BaseTypeName = "ChartOfCalculationTypes";
	Else
		Return False;
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns the names of object details of the specified type.
//
// Parameters:
//  Ref - AnyRef -  reference to the database element that you want to get the function result for;
//  Type    - Type -  type of the prop value.
// 
// Returns:
//  String - 
//
// Example:
//  Company Details = General Purpose.Namesrequisitovpotip(Document.The Link Type("Spravochniki.Companies"));
//
Function AttributeNamesByType(Ref, Type) Export
	
	Result = "";
	ObjectMetadata = Ref.Metadata();
	
	For Each Attribute In ObjectMetadata.Attributes Do
		If Attribute.Type.ContainsType(Type) Then
			Result = Result + ?(IsBlankString(Result), "", ", ") + Attribute.Name;
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

// Returns the name of the base type based on the passed value of the metadata object.
//
// Parameters:
//  MetadataObject - MetadataObject -  the metadata object to use to determine the base type.
// 
// Returns:
//  String - 
//
// Example:
//  Base_name = General Purpose.Name Of The Base_type Of The Meta-Data Object(Metadata.Guides.Nomenclature); = "Reference Books".
//
Function BaseTypeNameByMetadataObject(MetadataObject) Export
	
	If Metadata.Documents.Contains(MetadataObject) Then
		Return "Documents";
		
	ElsIf Metadata.Catalogs.Contains(MetadataObject) Then
		Return "Catalogs";
		
	ElsIf Metadata.Enums.Contains(MetadataObject) Then
		Return "Enums";
		
	ElsIf Metadata.InformationRegisters.Contains(MetadataObject) Then
		Return "InformationRegisters";
		
	ElsIf Metadata.AccumulationRegisters.Contains(MetadataObject) Then
		Return "AccumulationRegisters";
		
	ElsIf Metadata.AccountingRegisters.Contains(MetadataObject) Then
		Return "AccountingRegisters";
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject) Then
		Return "CalculationRegisters";
		
	ElsIf Metadata.ExchangePlans.Contains(MetadataObject) Then
		Return "ExchangePlans";
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject) Then
		Return "ChartsOfCharacteristicTypes";
		
	ElsIf Metadata.BusinessProcesses.Contains(MetadataObject) Then
		Return "BusinessProcesses";
		
	ElsIf Metadata.Tasks.Contains(MetadataObject) Then
		Return "Tasks";
		
	ElsIf Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return "ChartsOfAccounts";
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(MetadataObject) Then
		Return "ChartsOfCalculationTypes";
		
	ElsIf Metadata.Constants.Contains(MetadataObject) Then
		Return "Constants";
		
	ElsIf Metadata.DocumentJournals.Contains(MetadataObject) Then
		Return "DocumentJournals";
		
	ElsIf Metadata.Sequences.Contains(MetadataObject) Then
		Return "Sequences";
		
	ElsIf Metadata.ScheduledJobs.Contains(MetadataObject) Then
		Return "ScheduledJobs";
		
	ElsIf Metadata.CalculationRegisters.Contains(MetadataObject.Parent())
		And MetadataObject.Parent().Recalculations.Find(MetadataObject.Name) = MetadataObject Then
		Return "Recalculations";
		
	ElsIf Metadata.DataProcessors.Contains(MetadataObject) Then
		Return "DataProcessors";
		
	ElsIf Metadata.Reports.Contains(MetadataObject) Then
		Return "Reports";
		
	ElsIf Metadata.Subsystems.Contains(MetadataObject) Then
		Return "Subsystems";
		
	ElsIf Metadata.CommonModules.Contains(MetadataObject) Then
		Return "CommonModules";
		
	ElsIf Metadata.SessionParameters.Contains(MetadataObject) Then
		Return "SessionParameters";
		
	ElsIf Metadata.Roles.Contains(MetadataObject) Then
		Return "Roles";
		
	ElsIf Metadata.CommonAttributes.Contains(MetadataObject) Then
		Return "CommonAttributes";
		
	ElsIf Metadata.FilterCriteria.Contains(MetadataObject) Then
		Return "FilterCriteria";
		
	ElsIf Metadata.EventSubscriptions.Contains(MetadataObject) Then
		Return "EventSubscriptions";
		
	ElsIf Metadata.FunctionalOptions.Contains(MetadataObject) Then
		Return "FunctionalOptions";
		
	ElsIf Metadata.FunctionalOptionsParameters.Contains(MetadataObject) Then
		Return "FunctionalOptionsParameters";
		
	ElsIf Metadata.SettingsStorages.Contains(MetadataObject) Then
		Return "SettingsStorages";
		
	ElsIf Metadata.CommonForms.Contains(MetadataObject) Then
		Return "CommonForms";
		
	ElsIf Metadata.CommonCommands.Contains(MetadataObject) Then
		Return "CommonCommands";
		
	ElsIf Metadata.CommandGroups.Contains(MetadataObject) Then
		Return "CommandGroups";
		
	ElsIf Metadata.CommonTemplates.Contains(MetadataObject) Then
		Return "CommonTemplates";
		
	ElsIf Metadata.CommonPictures.Contains(MetadataObject) Then
		Return "CommonPictures";
		
	ElsIf Metadata.XDTOPackages.Contains(MetadataObject) Then
		Return "XDTOPackages";
		
	ElsIf Metadata.WebServices.Contains(MetadataObject) Then
		Return "WebServices";
		
	ElsIf Metadata.WSReferences.Contains(MetadataObject) Then
		Return "WSReferences";
		
	ElsIf Metadata.Styles.Contains(MetadataObject) Then
		Return "Styles";
		
	ElsIf Metadata.Languages.Contains(MetadataObject) Then
		Return "Languages";
		
	ElsIf Metadata.ExternalDataSources.Contains(MetadataObject) Then
		Return "ExternalDataSources";
		
	Else
		
		Return "";
		
	EndIf;
	
EndFunction

// Returns the object Manager by the full name of the metadata object.
// Restriction: business process route points are not processed.
//
// Parameters:
//  FullName - String -  full name of the metadata object. Example: "Directory.Companies".
//
// Returns:
//  
// 
// Example:
//  Managerphone = Observatsionnoe.Of Managedobjectreference("Handbook.Companies");
//  Portasilo = Mengersponge.Empty link();
//
Function ObjectManagerByFullName(FullName) Export
	
	Var MOClass, MetadataObjectName1, Manager;
	
	NameParts = StrSplit(FullName, ".");
	
	If NameParts.Count() >= 2 Then
		MOClass = NameParts[0];
		MetadataObjectName1   = NameParts[1];
	Else 
		Manager = Undefined;
	EndIf;
	
	If      Upper(MOClass) = "EXCHANGEPLAN" Then
		Manager = ExchangePlans;
		
	ElsIf Upper(MOClass) = "CATALOG" Then
		Manager = Catalogs;
		
	ElsIf Upper(MOClass) = "DOCUMENT" Then
		Manager = Documents;
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNAL" Then
		Manager = DocumentJournals;
		
	ElsIf Upper(MOClass) = "ENUM" Then
		Manager = Enums;
		
	ElsIf Upper(MOClass) = "REPORT" Then
		Manager = Reports;
		
	ElsIf Upper(MOClass) = "DATAPROCESSOR" Then
		Manager = DataProcessors;
		
	ElsIf Upper(MOClass) = "CHARTOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf Upper(MOClass) = "CHARTOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
		
	ElsIf Upper(MOClass) = "CHARTOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
		
	ElsIf Upper(MOClass) = "INFORMATIONREGISTER" Then
		Manager = InformationRegisters;
		
	ElsIf Upper(MOClass) = "ACCUMULATIONREGISTER" Then
		Manager = AccumulationRegisters;
		
	ElsIf Upper(MOClass) = "ACCOUNTINGREGISTER" Then
		Manager = AccountingRegisters;
		
	ElsIf Upper(MOClass) = "CALCULATIONREGISTER" Then
		
		If      NameParts.Count() = 2 Then
			Manager = CalculationRegisters;
			
		ElsIf NameParts.Count() = 4 Then
			SubordinateMOClass = NameParts[2];
			SubordinateMOName = NameParts[3];
			
			If Upper(SubordinateMOClass) = "RECALCULATION" Then 
				Manager = CalculationRegisters[MetadataObjectName1].Recalculations;
				MetadataObjectName1 = SubordinateMOName;
				
			Else 
				Manager = Undefined;
			EndIf;
			
		Else
			Manager = Undefined;
		EndIf;
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESS" Then
		Manager = BusinessProcesses;
		
	ElsIf Upper(MOClass) = "TASK" Then
		Manager = Tasks;
		
	ElsIf Upper(MOClass) = "CONSTANT" Then
		Manager = Constants;
		
	ElsIf Upper(MOClass) = "SEQUENCE" Then
		Manager = Sequences;
		
	Else
		Manager = Undefined;
	EndIf;
	
	If Manager = Undefined Then
		CheckMetadataObjectExists(FullName);
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object ""%3"" is missing an object manager.';"), 
			"FullName", "Common.ObjectManagerByFullName", FullName),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	Try
		Return Manager[MetadataObjectName1];
	Except
		CheckMetadataObjectExists(FullName);
		Raise;
	EndTry;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  Ref - AnyRef -  the object to get the Manager for.
//
// Returns:
//  CatalogManager, DocumentManager, DataProcessorManager, InformationRegisterManager - 
//
// Example:
//  Managerphone = Observatsionnoe.Managedobjectreference(Selenoorganic);
//  Portasilo = Mengersponge.Empty link();
//
Function ObjectManagerByRef(Ref) Export
	
	ObjectName = Ref.Metadata().Name;
	RefType = TypeOf(Ref);
	
	If Catalogs.AllRefsType().ContainsType(RefType) Then
		Return Catalogs[ObjectName];
		
	ElsIf Documents.AllRefsType().ContainsType(RefType) Then
		Return Documents[ObjectName];
		
	ElsIf BusinessProcesses.AllRefsType().ContainsType(RefType) Then
		Return BusinessProcesses[ObjectName];
		
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCharacteristicTypes[ObjectName];
		
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfAccounts[ObjectName];
		
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(RefType) Then
		Return ChartsOfCalculationTypes[ObjectName];
		
	ElsIf Tasks.AllRefsType().ContainsType(RefType) Then
		Return Tasks[ObjectName];
		
	ElsIf ExchangePlans.AllRefsType().ContainsType(RefType) Then
		Return ExchangePlans[ObjectName];
		
	ElsIf Enums.AllRefsType().ContainsType(RefType) Then
		Return Enums[ObjectName];
	Else
		Return Undefined;
	EndIf;
	
EndFunction

// 
// 
//
// Parameters:
//  TypeToCheck - Type -  to check for a reference data type.
//
// Returns:
//  Boolean - 
//
Function IsReference(TypeToCheck) Export
	
	Return TypeToCheck <> Type("Undefined") And AllRefsTypeDetails().ContainsType(TypeToCheck);
	
EndFunction

// Checks whether there is a physical record in the information database about the passed link value.
//
// Parameters:
//  RefToCheck - AnyRef -  the value of any information database link.
// 
// Returns:
//  Boolean - 
//
Function RefExists(RefToCheck) Export
	
	QueryText = 
		"SELECT TOP 1
		|	1 AS Field1
		|FROM
		|	&TableName AS Table
		|WHERE
		|	Table.Ref = &Ref";
	
	QueryText = StrReplace(QueryText, "&TableName", TableNameByRef(RefToCheck));
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", RefToCheck);
	
	SetPrivilegedMode(True);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// 
// 
// 
//
// Parameters:
//  Ref - AnyRef -  the object to get the view of.
//
// Returns:
//  String - 
// 
Function ObjectKindByRef(Ref) Export
	
	Return ObjectKindByType(TypeOf(Ref));
	
EndFunction 

// 
// 
// 
//
// Parameters:
//  ObjectType - Type -  the type of application object defined in the configuration.
//
// Returns:
//  String - 
// 
Function ObjectKindByType(ObjectType) Export
	
	If Catalogs.AllRefsType().ContainsType(ObjectType) Then
		Return "Catalog";
	
	ElsIf Documents.AllRefsType().ContainsType(ObjectType) Then
		Return "Document";
	
	ElsIf BusinessProcesses.AllRefsType().ContainsType(ObjectType) Then
		Return "BusinessProcess";
	
	ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(ObjectType) Then
		Return "ChartOfCharacteristicTypes";
	
	ElsIf ChartsOfAccounts.AllRefsType().ContainsType(ObjectType) Then
		Return "ChartOfAccounts";
	
	ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(ObjectType) Then
		Return "ChartOfCalculationTypes";
	
	ElsIf Tasks.AllRefsType().ContainsType(ObjectType) Then
		Return "Task";
	
	ElsIf ExchangePlans.AllRefsType().ContainsType(ObjectType) Then
		Return "ExchangePlan";
	
	ElsIf Enums.AllRefsType().ContainsType(ObjectType) Then
		Return "Enum";
	
	Else
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid data type of parameter ""%1"" in function ""%2"": ""%3"".';"), String(ObjectType)),
			"ObjectType", "Common.ObjectKindByType", ErrorCategory.ConfigurationError);
	EndIf;
	
EndFunction

// Returns the full name of the metadata object based on the passed reference value.
//
// Parameters:
//  Ref - AnyRef -  object to get the name of the information security table for.
// 
// Returns:
//  String - 
//
Function TableNameByRef(Ref) Export
	
	Return Ref.Metadata().FullName();
	
EndFunction

// Checks that the passed value is of the reference data type.
//
// Parameters:
//  Value - Arbitrary -  the value to check.
//
// Returns:
//  Boolean - 
//
Function RefTypeValue(Value) Export
	
	Return IsReference(TypeOf(Value));
	
EndFunction

// Checks whether an item in the reference list or the feature view plan is a group of items.
//
// Parameters:
//  Object - CatalogRef
//         - ChartOfCharacteristicTypesRef
//         - CatalogObject
//         - ChartOfCharacteristicTypesObject -  the object being checked.
//
// Returns:
//  Boolean
//
Function ObjectIsFolder(Object) Export
	
	If RefTypeValue(Object) Then
		Ref = Object;
	Else
		Ref = Object.Ref;
	EndIf;
	
	ObjectMetadata = Ref.Metadata();
	If IsCatalog(ObjectMetadata) Then
		If Not ObjectMetadata.Hierarchical
		 	Or ObjectMetadata.HierarchyType <> Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
			Return False;
		EndIf;
	ElsIf Not IsChartOfCharacteristicTypes(ObjectMetadata) Or Not ObjectMetadata.Hierarchical Then
		Return False;
	EndIf;
	
	If Ref <> Object Then
		Return Object.IsFolder;
	EndIf;
	
	Return ObjectAttributeValue(Ref, "IsFolder") = True;
	
EndFunction

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
// 
// 
// 
// Parameters:
//  MetadataObjectDetails - MetadataObject -  the metadata object's configuration;
//                            - Type - 
//                            - String -  
//                                       
//
//  RaiseException1 - Boolean -  if False, Null is returned for a nonexistent
//                                or unsupported metadata object instead of calling an exception.
//
// Returns:
//  CatalogRef.MetadataObjectIDs
//  Spravochniki.Identifiers
//  of the extension objects Null
//  
// Example:
//  ID = General Purpose.ID Of The Metadata Object(Type Of Tag (Link));
//  ID = General Purpose.ID Of The Metadat Object(Metadat Object);
//  ID = General Purpose.ID Of The Metadata Object ("Reference.Companies");
//
Function MetadataObjectID(MetadataObjectDetails, RaiseException1 = True) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectID(
		MetadataObjectDetails, RaiseException1);
	
EndFunction

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
// 
// 
// 
// Parameters:
//  MetadataObjectsDetails - Array of MetadataObject -  configuration metadata objects;
//                             - Array of String - 
//                         
//                             - Array of Type - 
//  RaiseException1 - Boolean -  if False, nonexistent and unsupported metadata objects
//                                will be omitted in the return value.
//
// Returns:
//  Map of KeyAndValue:
//    * Key     - String -  full name of the specified metadata object.
//    * Value - CatalogRef.MetadataObjectIDs
//               - CatalogRef.ExtensionObjectIDs - 
//
// Example:
//  Full name = new array;
//  Full name.Add (Metadata.Guides.Currencies.Full name());
//  Full name.Add (Metadata.Ledgers.Currency exchange rate.Full name());
//  IDs = General Purpose.Object IDs Of The Metadata(Full Name);
//
Function MetadataObjectIDs(MetadataObjectsDetails, RaiseException1 = True) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectIDs(
		MetadataObjectsDetails, RaiseException1);
	
EndFunction

// Returns a metadata object by the passed ID.
//
// Parameters:
//  Id - CatalogRef.MetadataObjectIDs
//                - CatalogRef.ExtensionObjectIDs - 
//                    
//
//  RaiseException1 - Boolean -  if False, then if the metadata object
//                    does not exist or is not available, returns, respectively
//                    Null or Undefined instead of calling an exception.
//
// Returns:
//  MetadataObject - 
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
//
Function MetadataObjectByID(Id, RaiseException1 = True) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectByID(
		Id, RaiseException1);
	
EndFunction

// Returns metadata objects based on the passed IDs.
//
// Parameters:
//  IDs - Array - :
//                     * Value - CatalogRef.MetadataObjectIDs
//                                - CatalogRef.ExtensionObjectIDs - 
//                                    
//
//  RaiseException1 - Boolean -  if False, then if the metadata object
//                    does not exist or is not available, returns, respectively
//                    Null or Undefined instead of calling an exception.
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - CatalogRef.MetadataObjectIDs
//              - CatalogRef.ExtensionObjectIDs - 
//   * Value - MetadataObject -  the metadata object corresponding to the ID.
//              - Null - 
//                  
//              - Undefined - 
//                  
//                  
//                  
//                  
//                  
//
Function MetadataObjectsByIDs(IDs, RaiseException1 = True) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectsByIDs(
		IDs, RaiseException1);
	
EndFunction

// 
// 
// 
//
// Parameters:
//  FullName - String - 
//
// Returns:
//  MetadataObject - 
//  
//
Function MetadataObjectByFullName(FullName) Export
	
	PointPosition = StrFind(FullName, ".");
	BaseTypeName = Left(FullName, PointPosition - 1);
	
	CollectionsNames = StandardSubsystemsCached.CollectionNamesByBaseTypeNames();
	Collection = CollectionsNames.Get(Upper(BaseTypeName));
	
	If Collection <> Undefined Then
		If Collection <> "Subsystems" Then
			ObjectName = Mid(FullName, PointPosition + 1);
			MetadataObject = Metadata[Collection].Find(ObjectName);
		Else
			SubsystemsNames = StrSplit(Upper(FullName), ".");
			Count = SubsystemsNames.Count();
			Subsystem = Metadata;
			MetadataObject = Undefined;
			IndexOf = 0;
			While True Do
				IndexOf = IndexOf + 1;
				If IndexOf >= Count Then
					Break;
				EndIf;
				SubsystemName = SubsystemsNames[IndexOf];
				Subsystem = Subsystem.Subsystems.Find(SubsystemName);
				If Subsystem = Undefined Then
					Break;
				EndIf;
				IndexOf = IndexOf + 1;
				If IndexOf = Count Then
					MetadataObject = Subsystem;
					Break;
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	If MetadataObject = Undefined Then
		MetadataObject = Metadata.FindByFullName(FullName);
	EndIf;
	
	Return MetadataObject;
	
EndFunction

// Determines the availability of the metadata object by functional options.
//
// Parameters:
//   MetadataObject - MetadataObject
//                    - String -  the metadata object to check.
//
// Returns:
//   Boolean - 
//
Function MetadataObjectAvailableByFunctionalOptions(Val MetadataObject) Export
	If MetadataObject = Undefined Then
		Return False;
	EndIf;
	If TypeOf(MetadataObject) <> Type("String") Then
		FullName = MetadataObject.FullName();
	Else
		FullName = MetadataObject;
	EndIf;
	Return StandardSubsystemsCached.ObjectsEnabledByOption().Get(FullName) <> False;
EndFunction

// Adds a description of renaming the metadata object when switching to the specified configuration version.
// The addition is performed in the Total structure, which is passed to the
// General purpose procedure Undefined.Adding the name of the metadat objects.
// 
// Parameters:
//   Total                    - See CommonOverridable.OnAddMetadataObjectsRenaming.Total
//   IBVersion                - String    -  the version of the final configuration that you want
//                                         to rename when switching to, for example, "2.1.2.14".
//   PreviousFullName         - String    - 
//                                         
//   NewFullName          - String    - 
//                                         
//   LibraryID - String    -  internal ID of the library that the version of the Library belongs to.
//                                         It is not required for the main configuration.
//                                         For example, "standard Subsystems" - as specified
//                                         in the update of the information database.In addition to the subsystems.
// Example:
//	
//		
//		
//
Procedure AddRenaming(Total, IBVersion, PreviousFullName, NewFullName, LibraryID = "") Export
	
	Catalogs.MetadataObjectIDs.AddRenaming(Total,
		IBVersion, PreviousFullName, NewFullName, LibraryID);
	
EndProcedure

// 
// 
//
// Parameters:
//  Type - Type -  for which you need to get an idea.
//
// Returns:
//  String
//
Function TypePresentationString(Type) Export
	
	Presentation = "";
	
	If IsReference(Type) Then
	
		FullName = Metadata.FindByType(Type).FullName();
		ObjectName = StrSplit(FullName, ".")[1];
		
		If Catalogs.AllRefsType().ContainsType(Type) Then
			Presentation = "CatalogRef";
		
		ElsIf Documents.AllRefsType().ContainsType(Type) Then
			Presentation = "DocumentRef";
		
		ElsIf BusinessProcesses.AllRefsType().ContainsType(Type) Then
			Presentation = "BusinessProcessRef";
		
		ElsIf BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type) Then
			Presentation = "BusinessProcessRoutePointRef";
		
		ElsIf ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCharacteristicTypesRef";
		
		ElsIf ChartsOfAccounts.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfAccountsRef";
		
		ElsIf ChartsOfCalculationTypes.AllRefsType().ContainsType(Type) Then
			Presentation = "ChartOfCalculationTypesRef";
		
		ElsIf Tasks.AllRefsType().ContainsType(Type) Then
			Presentation = "TaskRef";
		
		ElsIf ExchangePlans.AllRefsType().ContainsType(Type) Then
			Presentation = "ExchangePlanRef";
		
		ElsIf Enums.AllRefsType().ContainsType(Type) Then
			Presentation = "EnumRef";
		
		EndIf;
		
		Result = ?(Presentation = "", Presentation, Presentation + "." + ObjectName);
		
	ElsIf Type = Type("Undefined") Then
		Result = "Undefined";
		
	ElsIf Type = Type("String") Then
		Result = "String";

	ElsIf Type = Type("Number") Then
		Result = "Number";

	ElsIf Type = Type("Boolean") Then
		Result = "Boolean";

	ElsIf Type = Type("Date") Then
		Result = "Date";
	
	Else
		
		Result = String(Type);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a table of values with a description of the required properties of all metadata object details.
// Gets the values of properties of standard and custom details (created in the Configurator mode).
//
// Parameters:
//  MetadataObject  - MetadataObject -  the object for which you need to get the value of the details ' properties.
//                      For Example: Metadata.Document.Realsozialismus
//  Properties - String -  comma-separated properties of Bank details to get the value of.
//                      For example: "Name, Type, Synonym, Hint".
//
// Returns:
//  ValueTable - 
//
Function ObjectPropertiesDetails(MetadataObject, Properties) Export
	
	PropertiesArray = StrSplit(Properties, ",");
	
	// 
	ObjectPropertiesDescriptionTable = New ValueTable;
	
	// 
	For Each PropertyName In PropertiesArray Do
		ObjectPropertiesDescriptionTable.Columns.Add(TrimAll(PropertyName));
	EndDo;
	
	// 
	For Each Attribute In MetadataObject.Attributes Do
		FillPropertyValues(ObjectPropertiesDescriptionTable.Add(), Attribute);
	EndDo;
	
	// 
	For Each Attribute In MetadataObject.StandardAttributes Do
		FillPropertyValues(ObjectPropertiesDescriptionTable.Add(), Attribute);
	EndDo;
	
	Return ObjectPropertiesDescriptionTable;
	
EndFunction

// Returns an indication that the item is part of a subset of standard items.
//
// Parameters:
//  StandardAttributes - StandardAttributeDescriptions -  type and value that describe a collection of settings for various
//                                                         standard details;
//  AttributeName         - String -  a prop that needs to be checked for belonging to a set of standard
//                                  props.
// 
// Returns:
//   Boolean - 
//
Function IsStandardAttribute(StandardAttributes, AttributeName) Export
	
	For Each Attribute In StandardAttributes Do
		If Attribute.Name = AttributeName Then
			Return True;
		EndIf;
	EndDo;
	Return False;
	
EndFunction

// Allows you to determine whether the object's details include a detail with the passed name.
//
// Parameters:
//  AttributeName - String -  the name of the props;
//  ObjectMetadata - MetadataObject -  the object where you want to check the presence of props.
//
// Returns:
//  Boolean - 
//
Function HasObjectAttribute(AttributeName, ObjectMetadata) Export

	Attributes = ObjectMetadata.Attributes; // MetadataObjectCollection
	Return Not (Attributes.Find(AttributeName) = Undefined);

EndFunction

// Check that the type description consists of a single value type and 
// matches the desired type.
//
// Parameters:
//   TypeDetails - TypeDescription -  type collection to check;
//   ValueType  - Type -  the type being checked.
//
// Returns:
//   Boolean - 
//
// Example:
//  
//    
//  
//
Function TypeDetailsContainsType(TypeDetails, ValueType) Export
	
	If TypeDetails.Types().Count() = 1
	   And TypeDetails.Types().Get(0) = ValueType Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Creates a type Descriptor object containing the String type.
//
// Parameters:
//  StringLength - Number -  string length.
//
// Returns:
//  TypeDescription - 
//
Function StringTypeDetails(StringLength) Export
	
	Return New TypeDescription("String", , New StringQualifiers(StringLength));
	
EndFunction

// Creates a type Description object containing the Number type.
//
// Parameters:
//  Digits - Number -  the total number of digits (number of digits
//                        the integer part plus the number of digits of the fractional part).
//  FractionDigits - Number -  the number of digits of the fractional part.
//  NumberSign - AllowedSign -  valid sign of the number.
//
// Returns:
//  TypeDescription - 
//
Function TypeDescriptionNumber(Digits, FractionDigits = 0, Val NumberSign = Undefined) Export
	
	If NumberSign = Undefined Then 
		NumberSign = AllowedSign.Any;
	EndIf;
	
	Return New TypeDescription("Number", New NumberQualifiers(Digits, FractionDigits, NumberSign));
	
EndFunction

// Creates a type Descriptor object containing the date type.
//
// Parameters:
//  Var_DateFractions - DateFractions -  a set of options for using date values.
//
// Returns:
//  TypeDescription - 
//
Function DateTypeDetails(Var_DateFractions) Export
	
	Return New TypeDescription("Date", , , New DateQualifiers(Var_DateFractions));
	
EndFunction

// Returns a description of the type that includes all possible configuration reference types.
//
// Returns:
//  TypeDescription - 
//
Function AllRefsTypeDetails() Export
	
	Return StandardSubsystemsCached.AllRefsTypeDetails();
	
EndFunction

// Returns the string representation of the list specified in the properties of the metadata object.
// Depending on which properties of the metadata object are filled in, the function returns one of them in the specified
// order: Extended list view, list View, Synonym, or Name.
//
// Parameters:
//  MetadataObject - MetadataObject -  arbitrary object.
//
// Returns:
//  String - 
//
Function ListPresentation(MetadataObject) Export
	
	ObjectProperties = New Structure("ExtendedListPresentation,ListPresentation");
	FillPropertyValues(ObjectProperties, MetadataObject);
	
	If ValueIsFilled(ObjectProperties.ExtendedListPresentation) Then
		Result = ObjectProperties.ExtendedListPresentation;
	ElsIf ValueIsFilled(ObjectProperties.ListPresentation) Then
		Result = ObjectProperties.ListPresentation;
	Else
		Result = MetadataObject.Presentation();
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the string representation of the object specified in the metadata object properties.
// Depending on which properties of the metadata object are filled in, the function returns one of them in the specified
// order: Extended object representation, object Representation, Synonym, or Name.
//
// Parameters:
//  MetadataObject - MetadataObject -  arbitrary object.
//
// Returns:
//  String -  representation of objects.
//
Function ObjectPresentation(MetadataObject) Export
	
	ObjectProperties = New Structure("ExtendedObjectPresentation,ObjectPresentation");
	FillPropertyValues(ObjectProperties, MetadataObject);
	
	If ValueIsFilled(ObjectProperties.ExtendedObjectPresentation) Then
		Result = ObjectProperties.ExtendedObjectPresentation;
	ElsIf ValueIsFilled(ObjectProperties.ObjectPresentation) Then
		Result = ObjectProperties.ObjectPresentation;
	Else
		Result = MetadataObject.Presentation();
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region SettingsStorage

////////////////////////////////////////////////////////////////////////////////
// 

// Saves the setting to the General settings store, as the Save platform method
// , for standard storageadjustment Manager or storageadjustment Manager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// If you do not have the right to save the user's Data, saving is skipped without an error.
//
// Parameters:
//   ObjectKey       - String           - 
//   SettingsKey      - String           - 
//   Settings         - Arbitrary     - 
//   SettingsDescription  - SettingsDescription - 
//   UserName   - String           - 
//   RefreshReusableValues - Boolean -  execute the platform method of the same name.
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDescription = Undefined,
			UserName = Undefined,
			RefreshReusableValues = False) Export
	
	StorageSave(CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDescription,
		UserName,
		RefreshReusableValues);
	
EndProcedure

// Saves several settings to the General settings store, such as the Save platform method
// , the standard storageadjustment Manager, or storageadjustment Manager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// If you do not have the right to save the user's Data, saving is skipped without an error.
// 
// Parameters:
//   MultipleSettings - Array - :
//     * Value - Structure:
//         * Object    - String       - see the Key object parameter in the platform's syntax assistant.
//         * Setting - String       - see the Settings key parameter in the platform's syntax assistant.
//         * Value  - Arbitrary - see the Configuration parameter in the platform's syntax assistant.
//
//   RefreshReusableValues - Boolean -  execute the platform method of the same name.
//
Procedure CommonSettingsStorageSaveArray(MultipleSettings,
			RefreshReusableValues = False) Export
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	For Each Item In MultipleSettings Do
		CommonSettingsStorage.Save(Item.Object, SettingsKey(Item.Setting), Item.Value);
	EndDo;
	
	If RefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Loads a setting from the General settings store, as the upload method of the Platform
// , for standard storagesadjustment Manager or storagesadjustment Manager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// It also returns the specified default value if the settings do not exist.
// If you do not have the right to save user Data, the default value is returned without an error.
//
// The return value clears references to a nonexistent object in the database, namely
// - , the returned reference is replaced with the specified default value;
// - links are removed from Array data;
// - for data of the Structure and Match type, the key does not change, and the value is set Undefined;
// - analysis of values in data of the Array, Structure, and Match type is performed recursively.
//
// Parameters:
//   ObjectKey          - String           - 
//   SettingsKey         - String           - 
//   DefaultValue  - Arbitrary     -  the value that is returned if the settings do not exist.
//                                             If omitted, the value Undefined is returned.
//   SettingsDescription     - SettingsDescription - 
//   UserName      - String           - 
//
// Returns: 
//   Arbitrary - 
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDescription,
		UserName);
	
EndFunction

// Deletes a setting from the General settings store, as the delete method of the Platform
// , for standard storageadjustment Manager or storageadjustment Manager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// If you do not have the right to save the user's Data, the deletion is skipped without an error.
//
// Parameters:
//   ObjectKey     - String
//                   - Undefined - 
//   SettingsKey    - String
//                   - Undefined - 
//   UserName - String
//                   - Undefined - 
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves the setting to the system settings store, as the platform's Save method
// for the standard storage object Configuremanager, but with support for the settings key length
// of more than 128 characters by hashing the part that exceeds 96 characters.
// If you do not have the right to save the user's Data, saving is skipped without an error.
//
// Parameters:
//   ObjectKey       - String           - 
//   SettingsKey      - String           - 
//   Settings         - Arbitrary     - 
//   SettingsDescription  - SettingsDescription - 
//   UserName   - String           - 
//   RefreshReusableValues - Boolean -  execute the platform method of the same name.
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDescription = Undefined,
			UserName = Undefined,
			RefreshReusableValues = False) Export
	
	StorageSave(SystemSettingsStorage, 
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDescription,
		UserName,
		RefreshReusableValues);
	
EndProcedure

// Loads a setting from the system settings store, as the platform's Upload method,
// and the standard configuration Manager Storage object, but with support for a settings key length
// of more than 128 characters by hashing the part that exceeds 96 characters.
// It also returns the specified default value if the settings do not exist.
// If you do not have the right to save user Data, the default value is returned without an error.
//
// The returned value clears references to a nonexistent object in the database, namely:
// - the returned reference is replaced with the specified default value;
// - links are removed from Array data;
// - for data of the Structure and Match type, the key does not change, and the value is set Undefined;
// - analysis of values in data of the Array, Structure, and Match type is performed recursively.
//
// Parameters:
//   ObjectKey          - String           - 
//   SettingsKey         - String           - 
//   DefaultValue  - Arbitrary     -  the value that is returned if the settings do not exist.
//                                             If omitted, the value Undefined is returned.
//   SettingsDescription     - SettingsDescription - 
//   UserName      - String           - 
//
// Returns: 
//   Arbitrary - 
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(SystemSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDescription,
		UserName);
	
EndFunction

// Deletes a setting from the system settings store, as the delete method of the Platform
// , and the standard storage Configuremanager object, but with support for the settings key length
// of more than 128 characters by hashing the part that exceeds 96 characters.
// If you do not have the right to save the user's Data, the deletion is skipped without an error.
//
// Parameters:
//   ObjectKey     - String
//                   - Undefined - 
//   SettingsKey    - String
//                   - Undefined - 
//   UserName - String
//                   - Undefined - 
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(SystemSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves the configuration in the form data settings store, as the Save platform method
// , for standard Storagesconfigurationmanager or Storagesconfigurationmanager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// If you do not have the right to save the user's Data, saving is skipped without an error.
//
// Parameters:
//   ObjectKey       - String           - 
//   SettingsKey      - String           - 
//   Settings         - Arbitrary     - 
//   SettingsDescription  - SettingsDescription - 
//   UserName   - String           - 
//   RefreshReusableValues - Boolean -  execute the platform method of the same name.
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey, Settings,
			SettingsDescription = Undefined,
			UserName = Undefined, 
			RefreshReusableValues = False) Export
	
	StorageSave(FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		Settings,
		SettingsDescription,
		UserName,
		RefreshReusableValues);
	
EndProcedure

// Loads a setting from the form data settings store, as a method of the Upload platform,
// for standard storagesadjustment Manager or storagesadjustment Manager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// It also returns the specified default value if the settings do not exist.
// If you do not have the right to save user Data, the default value is returned without an error.
//
// The return value clears references to a nonexistent object in the database, namely
// - , the returned reference is replaced with the specified default value;
// - links are removed from Array data;
// - for data of the Structure and Match type, the key does not change, and the value is set Undefined;
// - analysis of values in data of the Array, Structure, and Match type is performed recursively.
//
// Parameters:
//   ObjectKey          - String           - 
//   SettingsKey         - String           - 
//   DefaultValue  - Arbitrary     -  the value that is returned if the settings do not exist.
//                                             If omitted, the value Undefined is returned.
//   SettingsDescription     - SettingsDescription - 
//   UserName      - String           - 
//
// Returns: 
//   Arbitrary - 
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey, DefaultValue = Undefined, 
			SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDescription, 
		UserName);
	
EndFunction

// Deletes a setting from the form data settings store, as the delete method of the Platform
// , for standard storagesadjustment Manager or storagesadjustment Manager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// If you do not have the right to save the user's Data, the deletion is skipped without an error.
//
// Parameters:
//   ObjectKey     - String
//                   - Undefined - 
//   SettingsKey    - String
//                   - Undefined - 
//   UserName - String
//                   - Undefined - 
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

#EndRegion

#Region XMLSerialization

// 
// 
// 
//
// Parameters:
//  Value - Arbitrary -  the value to serialize to an XML string.
//
// Returns:
//  String - 
//
Function ValueToXMLString(Value) Export
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
	
	Return XMLWriter.Close();
EndFunction

// 
// 
//
// Parameters:
//  XMLLine - String -  XML string with a serialized object..
//
// Returns:
//  Arbitrary - 
//
Function ValueFromXMLString(XMLLine) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLLine);
	
	Return XDTOSerializer.ReadXML(XMLReader);
EndFunction

// Returns the XML representation of the XDTO object.
//
// Parameters:
//  XDTODataObject - XDTODataObject  -  the object to generate an XML representation for.
//  Factory    - XDTOFactory -  the factory that you want to use to generate the XML representation.
//                             If this parameter is omitted, the global XDTO factory will be used.
//
// Returns: 
//   String - 
//
Function XDTODataObjectToXMLString(Val XDTODataObject, Val Factory = Undefined) Export
	
	XDTODataObject.Validate();
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Record = New XMLWriter();
	Record.SetString();
	Factory.WriteXML(Record, XDTODataObject, , , , XMLTypeAssignment.Explicit);
	
	Return Record.Close();
	
EndFunction

// Generates an XDTO object based on the XML representation.
//
// Parameters:
//  XMLLine - String    -  XML representation of an XDTO object,
//  Factory - XDTOFactory -  the factory that you want to use to generate the XDTO object.
//                          If this parameter is omitted, the global XDTO factory will be used.
//
// Returns: 
//  XDTODataObject - 
//
Function XDTODataObjectFromXMLString(Val XMLLine, Val Factory = Undefined) Export
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Read = New XMLReader();
	Read.SetString(XMLLine);
	
	Return Factory.ReadXML(Read);
	
EndFunction

#EndRegion

#Region JSONSerialization

// 
// 
// 
// 
// Parameters:
//  Value - Arbitrary
//
// Returns:
//  String
//
Function ValueToJSON(Val Value) Export
	
	JSONWriter = New JSONWriter;
	JSONWriter.SetString();
	WriteJSON(JSONWriter, Value);
	
	Return JSONWriter.Close();
	
EndFunction

// 
// 
//  
// 
// 
// 
// Parameters:
//   String - String - 
//   PropertiesWithDateValuesNames - String - 
//                                           
//                                - Array of String 
//   ReadToMap       - Boolean - 
//   
// Returns:
//  Arbitrary
//
Function JSONValue(Val String, Val PropertiesWithDateValuesNames = Undefined, Val ReadToMap = True) Export
	
	If TypeOf(PropertiesWithDateValuesNames) = Type("String") Then
		PropertiesWithDateValuesNames = StrSplit(PropertiesWithDateValuesNames, ", " + Chars.LF, False);
	EndIf;
	
	JSONReader = New JSONReader;
	JSONReader.SetString(String);
	
	Return ReadJSON(JSONReader, ReadToMap, PropertiesWithDateValuesNames);
	
EndFunction

#EndRegion

#Region WebServices

// Returns the parameter structure for the create Wsproxy function.
//
// Returns:
//   See CreateWSProxy.WSProxyConnectionParameters
//
Function WSProxyConnectionParameters() Export
	Result = New Structure;
	Result.Insert("WSDLAddress");
	Result.Insert("NamespaceURI");
	Result.Insert("ServiceName");
	Result.Insert("EndpointName", "");
	Result.Insert("UserName");
	Result.Insert("Password");
	Result.Insert("Timeout", 0);
	Result.Insert("Location");
	Result.Insert("UseOSAuthentication", False);
	Result.Insert("ProbingCallRequired", False);
	Result.Insert("SecureConnection", Undefined);
	Result.Insert("IsPackageDeliveryCheckOnErrorEnabled", True);
	Return Result;
EndFunction

// 
//  
//  
//  
//  
//
// Parameters:
//  WSProxyConnectionParameters - Structure:
//   * WSDLAddress                    - String - 
//   * NamespaceURI          - String - 
//   * ServiceName                   - String - 
//   * EndpointName          - String - 
//   * UserName              - String - 
//   * Password                       - String - 
//   * Timeout                      - Number  -  
//                                              
//   * Location               - String - 
//                                             
//                                             
//   * UseOSAuthentication - Boolean -  
//                                             
//   * ProbingCallRequired       - Boolean -  
//                                             
//   * SecureConnection         - OpenSSLSecureConnection
//                                  - Undefined - 
//   * IsPackageDeliveryCheckOnErrorEnabled - See GetFilesFromInternet.ConnectionDiagnostics.IsPackageDeliveryCheckEnabled.
//
// Returns:
//  WSProxy
//
// Example:
//	
//	
//	
//	
//	
//	
//
Function CreateWSProxy(Val WSProxyConnectionParameters) Export
	
	CommonClientServer.CheckParameter("CreateWSProxy", "Parameters", WSProxyConnectionParameters, Type("Structure"),
		New Structure("WSDLAddress,NamespaceURI,ServiceName", Type("String"), Type("String"), Type("String")));
		
	ConnectionParameters = WSProxyConnectionParameters();
	FillPropertyValues(ConnectionParameters, WSProxyConnectionParameters);
	
	ProbingCallRequired = ConnectionParameters.ProbingCallRequired;
	Timeout = ConnectionParameters.Timeout;
	
	If ProbingCallRequired And Timeout <> Undefined And Timeout > 20 Then
		ConnectionParameters.Timeout = 7;
		WSProxyPing = InformationRegisters.ProgramInterfaceCache.InnerWSProxy(ConnectionParameters);
		Try
			WSProxyPing.Ping();
		Except
			EndpointAddress = WSProxyPing.Endpoint.Location;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot check availability of the web service
				           |%1.
				           |Reason:
				           |%2.';"),
				ConnectionParameters.WSDLAddress,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			If SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
				ModuleNetworkDownload = CommonModule("GetFilesFromInternet");
				DiagnosticsResult = ModuleNetworkDownload.ConnectionDiagnostics(EndpointAddress,,
					ConnectionParameters.IsPackageDeliveryCheckOnErrorEnabled);
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1
					           |Diagnostics result:
					           |%2';"),
					ErrorText,
					DiagnosticsResult.ErrorDescription);
			EndIf;
			
			Raise(ErrorText, ErrorCategory.NetworkError);
		EndTry;
		ConnectionParameters.Timeout = Timeout;
	EndIf;
	
	Return InformationRegisters.ProgramInterfaceCache.InnerWSProxy(ConnectionParameters);
	
EndFunction

/////////////////////////////////////////////////////////////////////////////////
// 

// Returns the version numbers of the software interfaces of the remote system accessible via the web service.
// Allows you to provide full backward compatibility for changes in software interfaces
// by explicitly versioning them. For example, if the program interface is higher than a certain version,
// then only in this case you can call a new function from it.
//
// In order to save traffic when there is intense interaction between the calling and called parties 
// information about the versions are cached for one day. If you need to reset the cache before this time for debugging purposes,
// delete the corresponding entries from the cache Interface information register.
//
// Parameters:
//  Address        - String -  address of the InterfaceVersion interface versioning web service;
//  User - String -  name of the web service user;
//  Password       - String -  password of the web service user;
//  Interface    - String - 
//  IsPackageDeliveryCheckOnErrorEnabled - See GetFilesFromInternet.ConnectionDiagnostics.IsPackageDeliveryCheckEnabled
//
// Returns:
//   FixedArray -  
//                         
//
// Example:
//	  Versions = get the interface Version("http://vsrvx/sm", "ivanov",, " Servistransferencefiles");
//
//    Also, for backward compatibility, the deprecated call option is supported:
//	  connection Parameters = The New Structure;
//	  Connection parameters.Insert ("URL", "http://vsrvx/sm");
//	  Connection parameters.Insert ("UserName", " ivanov");
//	  Connection parameters.Insert ("Password", "");
//	  Versions = Get The Interface Version(Connection Parameters, " File Servertransmission");
//
Function GetInterfaceVersions(Val Address, Val User, Val Password = Undefined, 
	Val Interface = Undefined, Val IsPackageDeliveryCheckOnErrorEnabled = True) Export
	
	If TypeOf(Address) = Type("Structure") Then // 
		ConnectionParameters = Address;
		InterfaceName = User;
	Else
		ConnectionParameters = New Structure;
		ConnectionParameters.Insert("URL", Address);
		ConnectionParameters.Insert("UserName", User);
		ConnectionParameters.Insert("Password", Password);
		InterfaceName = Interface;
	EndIf;
	
	ConnectionParameters.Insert("IsPackageDeliveryCheckOnErrorEnabled", IsPackageDeliveryCheckOnErrorEnabled);
	
	If Not ConnectionParameters.Property("URL") 
		Or Not ValueIsFilled(ConnectionParameters.URL) Then
		
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter ""%1"" in function ""%2"". Service URL is not specified.';"), 
			"ConnectionParameters", "Common.GetInterfaceVersions"), ErrorCategory.ConfigurationError);
	EndIf;
	
	ReceivingParameters = New Array;
	ReceivingParameters.Add(ConnectionParameters);
	ReceivingParameters.Add(InterfaceName);
	
	Return InformationRegisters.ProgramInterfaceCache.VersionCacheData(
		InformationRegisters.ProgramInterfaceCache.VersionCacheRecordID(ConnectionParameters.URL, InterfaceName), 
		Enums.APICacheDataTypes.InterfaceVersions, 
		ReceivingParameters,
		True);
	
EndFunction

// Returns the version numbers of the software interfaces of the remote system connected via an external connection.
// Allows you to provide full backward compatibility for changes in software interfaces
// by explicitly versioning them. For example, if the program interface is higher than a certain version,
// then only in this case you can call a new function from it.
//
// Parameters:
//   ExternalConnection - COMObject -  an external connection that is used to work with the remote system.
//   InterfaceName     - String    -  the name of the requested software interface, e.g. "Serviceproduction".
//
// Returns:
//   FixedArray -  
//                         
//
// Example:
//  Versions = General Purpose.Getversiiinterfaceexternal Connection(External Connection, " Servertransferencefiles");
//
Function GetInterfaceVersionsViaExternalConnection(ExternalConnection, Val InterfaceName) Export
	Try
		XMLInterfaceVersions = ExternalConnection.StandardSubsystemsServer.SupportedVersions(InterfaceName);
	Except
		MessageString = NStr("en = 'The peer infobase does not support application interface versioning.
			|Error details: %1';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		WriteLogEvent(NStr("en = 'Getting interface versions';", DefaultLanguageCode()),
			EventLogLevel.Error, , , MessageString);
		
		Return New FixedArray(New Array);
	EndTry;
	
	Return New FixedArray(ValueFromXMLString(XMLInterfaceVersions));
EndFunction

// Deletes cache entries for software interface versions that contain the specified substring in the ID. 
// For example, the name of an interface that is no longer used in the configuration can be used as a substring.
//
// Parameters:
//  IDSearchSubstring - String -  substring of the ID search. 
//                                            Cannot contain%,_, or [characters.
//
Procedure DeleteVersionCacheRecords(Val IDSearchSubstring) Export
	
	BeginTransaction();
	Try
		
		Block = New DataLock;
		Block.Add("InformationRegister.ProgramInterfaceCache");
		Block.Lock();
		
		QueryText =
			"SELECT
			|	CacheTable.Id AS Id,
			|	CacheTable.DataType AS DataType
			|FROM
			|	InformationRegister.ProgramInterfaceCache AS CacheTable
			|WHERE
			|	CacheTable.Id LIKE ""%SearchSubstring%"" ESCAPE ""~""";
		
		QueryText = StrReplace(QueryText, "SearchSubstring", 
			GenerateSearchQueryString(IDSearchSubstring));
		Query = New Query(QueryText);
		Result = Query.Execute();
		Selection = Result.Select();
		While Selection.Next() Do
			Record = InformationRegisters.ProgramInterfaceCache.CreateRecordManager();
			Record.Id = Selection.Id;
			Record.DataType = Selection.DataType;
			Record.Delete();
		EndDo;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

#EndRegion

#Region SecureStorage

////////////////////////////////////////////////////////////////////////////////
// 

// Writes sensitive data to secure storage.
// The calling code must set the privileged mode itself.
//
// Secure storage is not readable by users (other than administrators),
// and is only available to code that accesses only its own part of the data and
// in a context that involves reading or writing sensitive data.
//
// Parameters:
//  Owner - ExchangePlanRef
//           - CatalogRef
//           - String - 
//             
//             
//             
//             
//             :
//               
//             
//               
//             
//               
//  Data  - Arbitrary -  data placed in secure storage. Undefined-deletes all data.
//            To delete data by key, use the delete data from secure Storage procedure.
//          - Structure - 
//  Var_Key    - String       - 
//                           :
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
//          
//      
//  
//
Procedure WriteDataToSecureStorage(Owner, Data, Var_Key = "Password") Export
	
	CommonClientServer.Validate(ValueIsFilled(Owner),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2.
			           |The parameter must contain a reference. The passed value is %3 (type: %4).';"),
			"Owner", "Common.WriteDataToSecureStorage", Owner, TypeOf(Owner)));
			
	If ValueIsFilled(Var_Key) Then
		
		CommonClientServer.Validate(TypeOf(Var_Key) = Type("String"),
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2.
			|The parameter must contain a string. The passed value is %3 (type: %4).';"),
			"Key", "Common.WriteDataToSecureStorage", Var_Key, TypeOf(Var_Key))); 
			
	Else
		
		CommonClientServer.Validate(TypeOf(Data) = Type("Structure"),
			StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2.
			|If Key = Undefined, the parameter must contain a structure. The passed value is %3 (type: %4).';"),
			"Data", "Common.WriteDataToSecureStorage", Data, TypeOf(Data)));
		
	EndIf;
	
	IsDataArea = DataSeparationEnabled() And SeparatedDataUsageAvailable();
	If IsDataArea Then
		SafeDataStorage = InformationRegisters.SafeDataAreaDataStorage.CreateRecordManager();
	Else
		SafeDataStorage = InformationRegisters.SafeDataStorage.CreateRecordManager();
	EndIf;
	
	SafeDataStorage.Owner = Owner;
	SafeDataStorage.Read();
	
	If Data <> Undefined Then
		
		If SafeDataStorage.Selected() Then
			
			DataToSave = SafeDataStorage.Data.Get();
			
			If TypeOf(DataToSave) <> Type("Structure") Then
				DataToSave = New Structure();
			EndIf;
			
			If ValueIsFilled(Var_Key) Then
				DataToSave.Insert(Var_Key, Data);
			Else
				CommonClientServer.SupplementStructure(DataToSave, Data, True);
			EndIf;
			
			DataForValueStorage = New ValueStorage(DataToSave, New Deflation(6));
			SafeDataStorage.Data = DataForValueStorage;
			SafeDataStorage.Write();
			
		Else
			
			DataToSave = ?(ValueIsFilled(Var_Key), New Structure(Var_Key, Data), Data);
			DataForValueStorage = New ValueStorage(DataToSave, New Deflation(6));
			
			SafeDataStorage.Data = DataForValueStorage;
			SafeDataStorage.Owner = Owner;
			SafeDataStorage.Write();
			
		EndIf;
	Else
		
		SafeDataStorage.Delete();
		
	EndIf;
	
EndProcedure

// Returns the data from the secure storage.
// The calling code must set the privileged mode itself.
//
// Secure storage is not readable by users (other than administrators),
// and is only available to code that accesses only its own part of the data and
// in a context that involves reading or writing sensitive data.
//
// Parameters:
//  Owners   - Array of ExchangePlanRef
//              - Array of CatalogRef
//              - Array of String - 
//                  
//  Keys       - String - 
//              - Undefined -  
//  SharedData - Boolean -  The truth is, if you want to model service to retrieve data from shared data in divided mode.
// 
// Returns:
//  Map of KeyAndValue:
//    * Key - ExchangePlanRef
//           - CatalogRef
//           - String -  
//                      
//    * Value - Arbitrary -  
//                                
//               - Structure    -  
//                                 
//                                 
//                                
//               - Undefined - 
//
// Example:
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
//	
//
Function ReadOwnersDataFromSecureStorage(Owners, Keys = "Password", SharedData = Undefined) Export
	
	CommonClientServer.Validate(TypeOf(Owners) = Type("Array"),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2.
			           |The parameter must contain an array. The passed value is %3 (type: %4).';"),
			"Owners", "Common.ReadDataFromSecureStorage", Owners, TypeOf(Owners)));
	
	Result = DataFromSecureStorage(Owners, Keys, SharedData);
	
	Return Result;
	
EndFunction

// Returns the data from the secure storage.
// The calling code must set the privileged mode itself.
//
// Secure storage is not readable by users (other than administrators),
// and is only available to code that accesses only its own part of the data and
// in a context that involves reading or writing sensitive data.
//
// Parameters:
//  Owner    - ExchangePlanRef
//              - CatalogRef
//              - String - 
//                  
//  Keys       - String -  contains a list of the names of the stored data specified by a comma.
//              - Undefined - 
//  SharedData - Boolean -  The truth is, if you want to model service to retrieve data from shared data in divided mode.
// 
// Returns:
//  Arbitrary, Structure, Undefined - 
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
//	
//	
//	
//	
//
Function ReadDataFromSecureStorage(Owner, Keys = "Password", SharedData = Undefined) Export
	
	Owners = CommonClientServer.ValueInArray(Owner);
	OwnerData = ReadOwnersDataFromSecureStorage(Owners, Keys, SharedData);
	
	Result = OwnerData[Owner];
	
	Return Result;
	
EndFunction

// Deletes sensitive data to secure storage.
// The calling code must set the privileged mode itself.
//
// Secure storage is not readable by users (other than administrators),
// and is only available to code that accesses only its own part of the data and
// in a context that involves reading or writing sensitive data.
//
// Parameters:
//  Owner - ExchangePlanRef
//           - CatalogRef
//           - String - 
//               
//           - Array - 
//  Keys    - String -  contains a comma-separated list of names of data to delete. 
//               Undefined-deletes all data.
//
// Example:
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
//
Procedure DeleteDataFromSecureStorage(Owner, Keys = Undefined) Export
	
	CommonClientServer.Validate(ValueIsFilled(Owner),
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %2.
			           |The parameter must contain a reference. The passed value is %3 (type: %4).';"),
			"Owner", "Common.DeleteDataFromSecureStorage", Owner, TypeOf(Owner)));
	
	If DataSeparationEnabled() And SeparatedDataUsageAvailable() Then
		SafeDataStorage = InformationRegisters.SafeDataAreaDataStorage.CreateRecordManager();
	Else
		SafeDataStorage = InformationRegisters.SafeDataStorage.CreateRecordManager();
	EndIf;  
	
	Owners = ?(TypeOf(Owner) = Type("Array"), Owner, CommonClientServer.ValueInArray(Owner));
	
	For Each DataOwner In Owners Do
		
		SafeDataStorage.Owner = DataOwner;
		SafeDataStorage.Read();
		If TypeOf(SafeDataStorage.Data) = Type("ValueStorage") Then
			DataToSave = SafeDataStorage.Data.Get();
			If Keys <> Undefined And TypeOf(DataToSave) = Type("Structure") Then
				KeysList = StrSplit(Keys, ",", False);
				If SafeDataStorage.Selected() And KeysList.Count() > 0 Then
					For Each KeyToDelete In KeysList Do
						If DataToSave.Property(KeyToDelete) Then
							DataToSave.Delete(KeyToDelete);
						EndIf;
					EndDo;
					DataForValueStorage = New ValueStorage(DataToSave, New Deflation(6));
					SafeDataStorage.Data = DataForValueStorage;
					SafeDataStorage.Write();
					Return;
				EndIf;
			EndIf;
		EndIf;
		
		SafeDataStorage.Delete();
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Clipboard

////////////////////////////////////////////////////////////////////////////////
// 

// Puts the selected row in tabular portion into the internal clipboard
// where they can be obtained using Statessupreme.
//
// Parameters:
//  TabularSection   - FormDataCollection -  the table part whose rows
//                                            should be placed in the internal clipboard.
//  SelectedRows - Array -  array of IDs of the selected rows.
//  Source         - String -  an arbitrary string identifier, such as the name of an object
//                              whose table part rows are placed in the internal clipboard.
//
Procedure CopyRowsToClipboard(TabularSection, SelectedRows, Source = Undefined) Export
	
	If SelectedRows = Undefined Then
		Return;
	EndIf;
	
	ValueTable = TabularSection.Unload();
	ValueTable.Clear();
	
	ColumnsToDelete = New Array;
	ColumnsToDelete.Add("SourceLineNumber");
	ColumnsToDelete.Add("LineNumber");
	
	For Each ColumnName In ColumnsToDelete Do
		Column = ValueTable.Columns.Find(ColumnName);
		If Column = Undefined Then
			Continue;
		EndIf;
		
		ValueTable.Columns.Delete(Column);
	EndDo;
	
	For Each RowID In SelectedRows Do
		RowToCopy = TabularSection.FindByID(RowID);
		FillPropertyValues(ValueTable.Add(), RowToCopy);
	EndDo;
	
	CopyToClipboard(ValueTable, Source);
	
EndProcedure

// Places arbitrary data in the internal clipboard, from where it can be retrieved using the clipboard string.
//
// Parameters:
//  Data           - Arbitrary -  data to be placed in the internal clipboard.
//  Source         - String       -  an arbitrary string identifier, such as the name of an object
//                                    whose table part rows are placed in the internal clipboard.
//
Procedure CopyToClipboard(Data, Source = Undefined) Export
	
	CurrentClipboard = SessionParameters.Clipboard;
	
	If ValueIsFilled(CurrentClipboard.Data) Then
		Address = CurrentClipboard.Data;
	Else
		Address = New UUID;
	EndIf;
	
	DataToStorage = PutToTempStorage(Data, Address);
	
	ClipboardStructure = New Structure;
	ClipboardStructure.Insert("Source", Source);
	ClipboardStructure.Insert("Data", DataToStorage);
	
	SessionParameters.Clipboard = New FixedStructure(ClipboardStructure);
	
EndProcedure

// Retrieves rows from the table, placed in the internal clipboard using Copyrightstatement.
//
// Returns:
//  Structure:
//     * Data   - Arbitrary -  data from the internal clipboard.
//                                 For example, Cableconnected when calling Copyrightstatement.
//     * Source - String       -  the object that the data belongs to.
//                                 If it was not specified when it was placed in the internal buffer, it is Undefined.
//
Function RowsFromClipboard() Export
	
	Result = New Structure;
	Result.Insert("Source", Undefined);
	Result.Insert("Data", Undefined);
	
	If EmptyClipboard() Then
		Return Result;
	EndIf;
	
	CurrentClipboard = SessionParameters.Clipboard; // See RowsFromClipboard
	Result.Source = CurrentClipboard.Source;
	Result.Data = GetFromTempStorage(CurrentClipboard.Data);
	
	Return Result;
EndFunction

// Checks for saved data in the internal clipboard.
//
// Parameters:
//  Source - String -  if passed, it checks whether there is data
//             in the internal clipboard with this key.
//             By default, it is Undefined.
// Returns:
//  Boolean - 
//
Function EmptyClipboard(Source = Undefined) Export
	
	CurrentClipboard = SessionParameters.Clipboard; // See RowsFromClipboard
	SourceIdentical = True;
	If Source <> Undefined Then
		SourceIdentical = (Source = CurrentClipboard.Source);
	EndIf;
	Return (Not SourceIdentical Or Not ValueIsFilled(CurrentClipboard.Data));
	
EndFunction

#EndRegion

#Region ExternalCodeSecureExecution

////////////////////////////////////////////////////////////////////////////////
// 
// 
//

// Perform the export procedure by name with the configuration privilege level.
// When security profiles are enabled, the Run () operator is called
// to switch to safe mode with the security profile used for the information base
// (if no other safe mode was set higher up the stack).
//
// Parameters:
//  MethodName  - String -  name of the export procedure in the format
//                       <object name>.< procedure name>, where <object name> is
//                       a General module or object Manager module.
//  Parameters  - Array -  parameters are passed to the <export procedure Name>
//                        procedure in the order of array elements.
// 
// Example:
//  Characteristic = new array();
//  Parameters.Add ("1");
//  General purpose.Perform A Configuration Method ("My General Module.Myprocedure", Parameters);
//
Procedure ExecuteConfigurationMethod(Val MethodName, Val Parameters = Undefined) Export
	
	CheckConfigurationProcedureName(MethodName);
	
	If SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If ModuleSafeModeManager.UseSecurityProfiles()
			And Not ModuleSafeModeManager.SafeModeSet() Then
			
			InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
			If ValueIsFilled(InfobaseProfile) Then
				
				SetSafeMode(InfobaseProfile);
				If SafeMode() = True Then
					SetSafeMode(False);
				EndIf;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined And Parameters.Count() > 0 Then
		For IndexOf = 0 To Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + XMLString(IndexOf) + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Execute MethodName + "(" + ParametersString + ")";
	
EndProcedure

// Perform an export procedure for an embedded language object by name.
// When security profiles are enabled, the Run () operator is invoked
// by switching to safe mode with the security profile used for the information base
// (if no other safe mode was set higher up the stack).
//
// Parameters:
//  Object    - Arbitrary -  object of the built-in 1C language:An object containing methods (for example, a processing Object).
//  MethodName - String       -  name of the export procedure for the processing object module.
//  Parameters - Array       -  parameters are passed to the <procedure Name>
//                             procedure in the order of array elements.
//
Procedure ExecuteObjectMethod(Val Object, Val MethodName, Val Parameters = Undefined) Export
	
	// 
	Try
		Test = New Structure(MethodName, MethodName);
		If Test = Undefined Then 
			Raise NStr("en = 'Method name validation.';");
		EndIf;
	Except
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of the %1 parameter in %3: %2.';"), 
				"MethodName", MethodName, "Common.ExecuteObjectMethod"),
			ErrorCategory.ConfigurationError);
	EndTry;
	
	If SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If ModuleSafeModeManager.UseSecurityProfiles()
			And Not ModuleSafeModeManager.SafeModeSet() Then
			
			ModuleSafeModeManager = CommonModule("SafeModeManager");
			InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
			
			If ValueIsFilled(InfobaseProfile) Then
				
				SetSafeMode(InfobaseProfile);
				If SafeMode() = True Then
					SetSafeMode(False);
				EndIf;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined And Parameters.Count() > 0 Then
		For IndexOf = 0 To Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + XMLString(IndexOf) + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Execute "Object." + MethodName + "(" + ParametersString + ")";
	
EndProcedure

// Performs an arbitrary algorithm in the built-in 1C language:Enterprises by pre-setting
// safe code execution mode and safe data separation mode for all separators
// present in the configuration.
//
// Parameters:
//  Algorithm  - String -  algorithm in the built - in language " 1C:Companies".
//  Parameters - Arbitrary -    the context that is required for executing the algorithm.
//    In the algorithm text, the context must be accessed by the name "Parameters".
//    For example, the expression " Parameters.Value1 = Parameters.Value2 "refers to the values
//    " Value1 "and" Value2 " passed to Parameters as properties.
//
// Example:
//
//  Characteristic = The New Structure;
//  Parameters.Insert ("Value1", 1);
//  Parameters.Insert ("Value2", 10);
//  General purpose.Run In Safe Mode ("Parameters.Value1 = Parameters.Value2", Parameters);
//
Procedure ExecuteInSafeMode(Val Algorithm, Val Parameters = Undefined) Export
	
	SetSafeMode(True);
	
	If SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = CommonModule("SaaSOperations");
		SeparatorArray = ModuleSaaSOperations.ConfigurationSeparators();
	Else
		SeparatorArray = New Array;
	EndIf;
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Execute Algorithm;
	
EndProcedure

// Evaluates the passed expression by first setting safe code execution mode
// and safe data separation mode for all delimiters present in the configuration.
//
// Parameters:
//  Expression - String -  the expression in the embedded language of 1C:Companies.
//  Parameters - Arbitrary -  the context that is required for evaluating the expression.
//    In the text of the expression, the context must be accessed by the name "Parameters".
//    For example, the expression " Parameters.Value1 = Parameters.Value2 "refers to the values
//    " Value1 "and" Value2 " passed to Parameters as properties.
//
// Returns:
//   Arbitrary - 
//
// Example:
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
Function CalculateInSafeMode(Val Expression, Val Parameters = Undefined) Export
	
	SetSafeMode(True);
	
	If SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = CommonModule("SaaSOperations");
		SeparatorArray = ModuleSaaSOperations.ConfigurationSeparators();
	Else
		SeparatorArray = New Array;
	EndIf;
	
	For Each SeparatorName In SeparatorArray Do
		
		SetDataSeparationSafeMode(SeparatorName, True);
		
	EndDo;
	
	Return Eval(Expression);
	
EndFunction

// 
//
// Returns:
//  UnsafeOperationProtectionDescription - 
//
Function ProtectionWithoutWarningsDetails() Export
	
	ProtectionDetails = New UnsafeOperationProtectionDescription;
	ProtectionDetails.UnsafeOperationWarnings = False;
	
	Return ProtectionDetails;
	
EndFunction

#EndRegion

#Region Queries

// 
// 
//
// Parameters:
//  SearchString - String -  arbitrary string.
//
// Returns:
//  String
//  
// Example:
//   
//    
//  
//    
//  
//    
//
//  
//
Function GenerateSearchQueryString(Val SearchString) Export
	
	Result = SearchString;
	Result = StrReplace(Result, "~", "~~");
	Result = StrReplace(Result, "%", "~%");
	Result = StrReplace(Result, "_", "~_");
	Result = StrReplace(Result, "[", "~[");
	Result = StrReplace(Result, "]", "~]");
	Result = StrReplace(Result, "^", "~^");	
	Return Result;
	
EndFunction

// Returns a fragment of the request text that separates one request from another.
//
// Returns:
//  String - 
//
Function QueryBatchSeparator() Export
	
	Return "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
EndFunction

// 
//
// Returns:
//  String
//
Function UnionAllText() Export
	
	Return
		"
		|
		|UNION ALL
		|
		|";
	
EndFunction

#EndRegion

#Region Other

// 
// 
//  
//   
//    
//  
//
// Parameters:
//  ScheduledJob - MetadataObjectScheduledJob - 
//    
//
// Example:
// 
//
Procedure OnStartExecuteScheduledJob(ScheduledJob = Undefined) Export
	
	SetPrivilegedMode(True);
	
	If InformationRegisters.ApplicationRuntimeParameters.UpdateRequired1() Then
		Text = NStr("en = 'The app is temporarily unavailable due to a version update.
			               |It is recommended that you disable scheduled jobs for the duration of the update.';");
		ScheduledJobsServer.CancelJobExecution(ScheduledJob, Text);
		Raise Text;
	EndIf;
	
	If Not DataSeparationEnabled()
	   And ExchangePlans.MasterNode() = Undefined
	   And ValueIsFilled(Constants.MasterNode.Get()) Then
	
		Text = NStr("en = 'The app is temporarily unavailable until the connection to the master node is restored.
			               |It is recommended that you disable scheduled jobs until the connection is restored.';");
		ScheduledJobsServer.CancelJobExecution(ScheduledJob, Text);
		Raise Text;
	EndIf;
	
	If ScheduledJob <> Undefined
		And SubsystemExists("StandardSubsystems.ScheduledJobs") Then
		
		ModuleWorkLockWithExternalResources = CommonModule("ExternalResourcesOperationsLock");
		ModuleWorkLockWithExternalResources.OnStartExecuteScheduledJob(ScheduledJob);
		
		ModuleScheduledJobsInternal = CommonModule("ScheduledJobsInternal");
		Available = ModuleScheduledJobsInternal.ScheduledJobAvailableByFunctionalOptions(ScheduledJob);
		
		If Not Available Then
			Jobs = ScheduledJobsServer.FindJobs(New Structure("Metadata", ScheduledJob));
			For Each Job In Jobs Do
				ScheduledJobsServer.ChangeJob(Job.UUID,
					New Structure("Use", False));
			EndDo;
			Text = NStr("en = 'The scheduled job is unavailable due to functional option values
				               |or is not supported in the current app run mode.
				               |The scheduled job execution is canceled and the job is disabled.';");
			ScheduledJobsServer.CancelJobExecution(ScheduledJob, Text);
			Raise Text;
		EndIf;
	EndIf;
	
	If StandardSubsystemsServer.RegionalInfobaseSettingsRequired() Then
		Text = NStr("en = 'The scheduled job cannot run until the regional settings are configured.
			                |The scheduled job is aborted.';");
		ScheduledJobsServer.CancelJobExecution(ScheduledJob, Text);
		Raise Text;
	EndIf;

	Catalogs.ExtensionsVersions.RegisterExtensionsVersionUsage();
	
	InformationRegisters.ExtensionVersionParameters.UponSuccessfulStartoftheExecutionoftheScheduledTask();
	
EndProcedure

// Sets the session parameters to the "not installed" state. 
// 
// Parameters:
//  ParametersToClear_ - String -  the names of the parameters of the session for clearing, separated by ",".
//  Exceptions          - String -  session parameter names not intended for cleaning, separated by ",".
//
Procedure ClearSessionParameters(ParametersToClear_ = "", Exceptions = "") Export
	
	ExceptionsArray = StrSplit(Exceptions, ",");
	ArrayOfParametersToClear = StrSplit(ParametersToClear_, ",", False);
	
	If ArrayOfParametersToClear.Count() = 0 Then
		For Each SessionParameter In Metadata.SessionParameters Do
			If ExceptionsArray.Find(SessionParameter.Name) = Undefined Then
				ArrayOfParametersToClear.Add(SessionParameter.Name);
			EndIf;
		EndDo;
	EndIf;
	
	IndexOf = ArrayOfParametersToClear.Find("ClientParametersAtServer");
	If IndexOf <> Undefined Then
		ArrayOfParametersToClear.Delete(IndexOf);
	EndIf;
	
	IndexOf = ArrayOfParametersToClear.Find("DefaultLanguage");
	If IndexOf <> Undefined Then
		ArrayOfParametersToClear.Delete(IndexOf);
	EndIf;
	
	IndexOf = ArrayOfParametersToClear.Find("InstalledExtensions");
	If IndexOf <> Undefined Then
		ArrayOfParametersToClear.Delete(IndexOf);
	EndIf;
	
	SessionParameters.Clear(ArrayOfParametersToClear);
	
EndProcedure

// Checks whether the transmitted table documents fit on the page when printing.
//
// Parameters:
//  TabDocument        - SpreadsheetDocument -  table document.
//  AreasToOutput   - Array
//                     - SpreadsheetDocument -  
//  ResultOnError - Boolean -  how to return the result when an error occurs.
//
// Returns:
//   Boolean   - 
//
Function SpreadsheetDocumentFitsPage(TabDocument, AreasToOutput, ResultOnError = True) Export

	Try
		Return TabDocument.CheckPut(AreasToOutput);
	Except
		Return ResultOnError;
	EndTry;

EndFunction 

// Saves the user's personal settings related to the basic Functionality subsystem.
// To get settings, the following functions are provided:
//  - General purpose Client.Suggest Installing Extensions To Work With Files (),
//  - Standardsystem Server.Request Confirmation Of Program Completion (),
//  - Standardsystem Server.Show pre-installed program updates().
// 
// Parameters:
//  Settings - Structure:
//    * RemindAboutFileSystemExtensionInstallation  - Boolean -  indicates whether you need
//                                                               to be reminded to install the extension.
//    * AskConfirmationOnExit - Boolean -  request confirmation when the job is completed.
//    * ShowInstalledApplicationUpdatesWarning - Boolean -  show a notification when
//                                                               the program is updated dynamically.
//
Procedure SavePersonalSettings(Settings) Export
	
	If Settings.Property("RemindAboutFileSystemExtensionInstallation") Then
		If IsWebClient() Then
			ClientID = StandardSubsystemsServer.ClientParametersAtServer().Get("ClientID");
			If ClientID = Undefined Then
				SystemInfo = New SystemInfo;
				ClientID = SystemInfo.ClientID;
			EndIf;
			CommonSettingsStorageSave(
				"ApplicationSettings/SuggestFileSystemExtensionInstallation",
				ClientID, Settings.RemindAboutFileSystemExtensionInstallation);
		EndIf;
	EndIf;
	
	If Settings.Property("AskConfirmationOnExit") Then
		CommonSettingsStorageSave("UserCommonSettings",
			"AskConfirmationOnExit",
			Settings.AskConfirmationOnExit);
	EndIf;
	
	If Settings.Property("ShowInstalledApplicationUpdatesWarning") Then
		CommonSettingsStorageSave("UserCommonSettings",
			"ShowInstalledApplicationUpdatesWarning",
			Settings.ShowInstalledApplicationUpdatesWarning);
	EndIf;
	
EndProcedure

// Performs a proportional distribution of the amount according
// to the specified distribution coefficients. 
//
// Parameters:
//  AmountToDistribute - Number  -  the amount to distribute, if the amount is 0, it is returned Undefined;
//                                 If you pass in a negative calculation in the module after inversion of the signs of the result.
//  Coefficients        - Array of Number -  
//                                          
//  Accuracy            - Number  -  
//
// Returns:
//  Array of Number - 
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
Function DistributeAmountInProportionToCoefficients(
		Val AmountToDistribute, Coefficients, Val Accuracy = 2) Export
	
	Return CommonClientServer.DistributeAmountInProportionToCoefficients(
		AmountToDistribute, Coefficients, Accuracy);
	
EndFunction

// The procedure is intended for filling in the details of a form of the data Formtree type.
//
// Parameters:
//  TreeItemsCollection - FormDataTreeItemCollection -  details to fill in.
//  ValueTree           - ValueTree    -  data to fill in.
// 
Procedure FillFormDataTreeItemCollection(TreeItemsCollection, ValueTree) Export
	
	For Each TableRow In ValueTree.Rows Do
		
		TreeItem = TreeItemsCollection.Add();
		FillPropertyValues(TreeItem, TableRow);
		If TableRow.Rows.Count() > 0 Then
			FillFormDataTreeItemCollection(TreeItem.GetItems(), TableRow);
		EndIf;
		
	EndDo;
	
EndProcedure

// Connects an external component made using Native API or COM technology
// from the configuration layout (stored as a ZIP archive).
//
// Parameters:
//   Id   - String - 
//   FullTemplateName - String -  full name of the configuration layout with the ZIP archive.
//   Isolated    - Boolean -  
//                              
//                               
//                               
//                   - Undefined - :
//                               
//                              
//                              See https://its.1c.eu/db/v83doc
//
// Returns:
//   - AddInObject -  an instance of an external component object.
//   - Undefined - 
//
// Example:
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
//
Function AttachAddInFromTemplate(Val Id, Val FullTemplateName, Val Isolated = Null) Export
	
	ResultOfCheckingTheExternalComponent = Undefined;
	
	If Isolated = Null Then
		Isolated = IsDefaultAddInAttachmentMethod();
	EndIf;
	
	If SubsystemExists("StandardSubsystems.AddIns") Then
		ModuleAddInsInternal = CommonModule("AddInsInternal");
		ResultOfCheckingTheExternalComponent = ModuleAddInsInternal.CheckAddInAttachmentAbility(Id);
		ResultOfCheckingTheExternalComponent.Insert("Available", 
			Not ValueIsFilled(ResultOfCheckingTheExternalComponent.ErrorDescription));
	EndIf;
	
	TheComponentOfTheLatestVersion = StandardSubsystemsServer.TheComponentOfTheLatestVersion(
		Id, FullTemplateName, ResultOfCheckingTheExternalComponent);
		
	Result = AttachAddInSSLByID(Id,
			TheComponentOfTheLatestVersion.Location, Isolated);
	
	Return Result.Attachable_Module;
	
EndFunction

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
//
// Returns:
//   Boolean
//
Function SessionSeparatorUsage() Export
	
	If Not DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.SessionSeparatorUsage();
	EndIf;
	
EndFunction

// Deprecated.
//  
// 
//
// Parameters:
//   Extension - String -  a directory extension that identifies the purpose of the temporary directory
//                         and the subsystem that created it.
//                         It is recommended to indicate in English.
//
// Returns:
//   String - 
//
Function CreateTemporaryDirectory(Val Extension = "") Export
	
	Return FileSystem.CreateTemporaryDirectory(Extension);
	
EndFunction

// Deprecated.
// 
// 
// 
//
//  
// 
//
// Parameters:
//   PathToDirectory - String -  full path to the temporary directory.
//
Procedure DeleteTemporaryDirectory(Val PathToDirectory) Export
	
	FileSystem.DeleteTemporaryDirectory(PathToDirectory);
	
EndProcedure

// Deprecated.
//
// Returns:
//  Boolean - 
//
Function HasUnsafeActionProtection() Export
	
	Return True;
	
EndFunction

// Deprecated.
//
// Parameters:
//  FullName - String -  full name of the metadata object. Example: "Report.business process".
//
// Returns:
//  ReportObject
//  A processing object is an instance of a report or processing.
// 
Function ObjectByFullName(FullName) Export
	RowsArray = StrSplit(FullName, ".");
	
	If RowsArray.Count() >= 2 Then
		Kind = Upper(RowsArray[0]);
		Name = RowsArray[1];
	Else
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter ""%1"" in function ""%2"". Invalid name of a report or data processor: ""%3"".';"), 
			"FullName", "Common.ObjectByFullName", FullName),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	If Kind = "REPORT" Then
		Return Reports[Name].Create();
	ElsIf Kind = "DATAPROCESSOR" Then
		Return DataProcessors[Name].Create();
	Else
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter ""%1"" in function ""%2"". The object is not a report or data processor: ""%3"".';"), 
			"FullName", "Common.ObjectByFullName", FullName),
			ErrorCategory.ConfigurationError);
	EndIf;
EndFunction

// Deprecated.
// 
//
// Returns:
//  Boolean - 
//
Function IsOSXClient() Export
	
	SetPrivilegedMode(True);
	
	IsMacOSClient = StandardSubsystemsServer.ClientParametersAtServer().Get("IsMacOSClient");
	
	If IsMacOSClient = Undefined Then
		Return False; // 
	EndIf;
	
	Return IsMacOSClient;
	
EndFunction

#EndRegion

#EndIf

#EndRegion

#If Not MobileStandaloneServer Then

#Region Internal

// 
//   
//   
//   
//   
//
// Parameters:
//   Query - Query -  the request to be uploaded to the XML string format.
//
// Returns:
//   String - 
//       :
//       * Text     - String -  query text.
//       * Parameters - Structure -   request parameters.
//
Function QueryToXMLString(Query) Export //  
	Structure = New Structure("Text, Parameters");
	FillPropertyValues(Structure, Query);
	Return ValueToXMLString(Structure);
EndFunction

Function AttachAddInSSLByID(Val Id, Val Location, Val Isolated = Null) Export
	
	CheckTheLocationOfTheComponent(Id, Location);
	
	Result = New Structure;
	Result.Insert("Attached", False);
	Result.Insert("Attachable_Module", Undefined);
	Result.Insert("ErrorDescription", "");
	
	Try
		
#If MobileAppServer Then
		ConnectionResult = AttachAddIn(Location, Id + "SymbolicName");
#Else
		If Isolated = Null Then
			Isolated = IsDefaultAddInAttachmentMethod();
		EndIf;
		ConnectionResult = AttachAddIn(Location, Id + "SymbolicName",,
			CommonInternalClientServer.AddInAttachType(Isolated));
#EndIf
		
	Except
		ErrorInfo = ErrorInfo();
		ErrorTitle = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot attach the ""%1"" add-in on the server due to:';"),
			Id);
		
		Result.ErrorDescription = ErrorTitle + Chars.LF
			+ ErrorProcessing.BriefErrorDescription(ErrorInfo);
		
		CommentForLog = ErrorTitle + Chars.LF
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo)
			+ SystemInformationForLogging();
		
		WriteLogEvent(NStr("en = 'Attaching add-in on the server';", DefaultLanguageCode()),
			EventLogLevel.Error,,, CommentForLog);
		Return Result;
	EndTry;
	
	If Not ConnectionResult Then
		
		TemplateAddInCompatibilityError = TemplateAddInCompatibilityError(Location);
		
		If ValueIsFilled(TemplateAddInCompatibilityError) Then
			Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Couldn''t attach the add-in ""%1"" on the server due to:
					 |%2.
					 |Technical information:
					 |%3
					 |Method ""%4"" returned ""False"".';"), Id, TemplateAddInCompatibilityError, Location,
				"AttachAddIn");
		Else
			Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot attach the ""%1"" add-in on the server.
					 |Technical information:
					 |%2
					 |The method ""%3"" returned ""False"".';"), Id, Location, "AttachAddIn");
		EndIf;
		
		Try
			Raise NStr("en = 'Call stack:';")
		Except
			CommentForLog = Result.ErrorDescription + Chars.LF + Chars.LF
				+ ErrorProcessing.DetailErrorDescription(ErrorInfo())
				+ SystemInformationForLogging();
		EndTry;
		
		WriteLogEvent(NStr("en = 'Attaching add-in on the server';", DefaultLanguageCode()),
			EventLogLevel.Error,,, CommentForLog);
		Return Result;
	EndIf;
	
	Attachable_Module = Undefined;
	Try
		Attachable_Module = New("AddIn." + Id + "SymbolicName" + "." + Id);
		If Attachable_Module = Undefined Then 
			Raise NStr("en = 'The New operator returned Undefined.';");
		EndIf;
	Except
		Attachable_Module = Undefined;
		ErrorInfo = ErrorInfo();
	EndTry;
	
	If Attachable_Module = Undefined Then
		Result.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot create object of the %1 add-in on the server due to:
			           |%2';"),
			Id, ErrorProcessing.BriefErrorDescription(ErrorInfo));
		
		CommentForLog = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot create an object of the %1 add-in on the server due to:
			           |%2';"),
			Id, ErrorProcessing.DetailErrorDescription(ErrorInfo)
				+ SystemInformationForLogging());
		
		WriteLogEvent(NStr("en = 'Attaching add-in on the server';", DefaultLanguageCode()),
			EventLogLevel.Error,,, CommentForLog);
		Return Result;
	EndIf;
	
	Result.Attached = True;
	Result.Attachable_Module = Attachable_Module;
	Return Result;
	
EndFunction

Function IsDefaultAddInAttachmentMethod() Export
	
#If Not WebClient And Not MobileClient And Not MobileAppServer Then
	
	SystemInfo = New SystemInfo;
	AppVersion = SystemInfo.AppVersion;
	If StrStartsWith(AppVersion, "8.3.24") And CommonClientServer.CompareVersions(AppVersion, "8.3.24.1267") >= 0
	 Or StrStartsWith(AppVersion, "8.3.23") And CommonClientServer.CompareVersions(AppVersion, "8.3.23.1947") >= 0
	 Or StrStartsWith(AppVersion, "8.3.22") And CommonClientServer.CompareVersions(AppVersion, "8.3.22.2322") >= 0
	 Or StrStartsWith(AppVersion, "8.3.21") And CommonClientServer.CompareVersions(AppVersion, "8.3.21.1930") >= 0 Then
		Return Undefined;
	Else
		Return False;
	EndIf;
#Else
	
	Return Undefined;
	
#EndIf
	
EndFunction

Function StringAsNstr(Val RowToValidate) Export
	
	RowToValidate = StrReplace(RowToValidate, " ", "");
	
	MatchesOptions = New Array;
	For Each Language In Metadata.Languages Do
		MatchesOptions.Add(Language.LanguageCode + "=");
	EndDo;
	
	For Each MatchOption In MatchesOptions Do
		If StrFind(RowToValidate, MatchOption) > 0 Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
	
EndFunction

// Sets the conditional design of the selection list
// 
// Parameters:
//  Form - ClientApplicationForm -  the form for which the design is set.
//  TagName - String -  name of the element to set the appearance for.
//  DataCompositionFieldName - String -  name of the data layout field.
//
Procedure SetChoiceListConditionalAppearance(Form, TagName, DataCompositionFieldName) Export
	
	Items           = Form.Items;
	ConditionalAppearance = Form.ConditionalAppearance;
	
	For Each ChoiceItem In Items[TagName].ChoiceList Do
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		FormItem = Items[TagName]; // FormField
		ItemField.Field = New DataCompositionField(FormItem.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField(DataCompositionFieldName);
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = ChoiceItem.Value;
		
		Item.Appearance.SetParameterValue("Text", ChoiceItem.Presentation);
		
	EndDo;
	
EndProcedure

// 
// 
// Returns:
//  String - 
//           
//  
//
Function CurrentUserLanguageSuffix() Export
	
	Result = New Structure();
	Result.Insert("CurrentLanguageSuffix", "");
	Result.Insert("IsMainLanguage", "");
	
	If SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = CommonModule("NationalLanguageSupportServer");
		CurrentLanguageSuffix = ModuleNationalLanguageSupportServer.CurrentLanguageSuffix();
		
		If ValueIsFilled(CurrentLanguageSuffix) Then
			Return CurrentLanguageSuffix;
		EndIf;
	Else
		CurrentLanguageSuffix  = "";
	EndIf;
	
	If IsMainLanguage() Then
		Return CurrentLanguageSuffix;
	EndIf;
	
	Return Undefined;
	
EndFunction

//  
//  
//  
// 
// Parameters:
//  FileName - String - 
// 
Procedure ShortenFileName(FileName) Export
	
	BytesLimit = 127;
	File = New File(FileName);
	
	If StringSizeInBytes(File.Name) <= BytesLimit Then
		Return;
	EndIf;
	
	String = "";
	RowBalance = "";
	LineSize = 0;
	MaximumRowSize = BytesLimit - 32;
	
	ExtensionSize = StringSizeInBytes(File.Extension);
	ShortenAlongWithExtension = ExtensionSize > 32;
	
	If ShortenAlongWithExtension Then
		AbbreviatedName = File.Name;
	Else
		AbbreviatedName = File.BaseName;
		LineSize = ExtensionSize;
	EndIf;
	
	For CharacterNumber = 1 To StrLen(AbbreviatedName) Do
		Char = Mid(AbbreviatedName, CharacterNumber, 1);
		SymbolSize = StringSizeInBytes(Char);
		
		If LineSize + SymbolSize > MaximumRowSize Then
			RowBalance = Mid(AbbreviatedName, CharacterNumber);
			Break;
		EndIf;
		
		String = String + Char;
		LineSize = LineSize + SymbolSize;
	EndDo;
	
	FileName = String;
	
	DataHashing = New DataHashing(HashFunction.MD5);
	DataHashing.Append(RowBalance);
	HashSum = StrReplace(DataHashing.HashSum, " ", "");
	
	FileName = File.Path + FileName + HashSum + ?(ShortenAlongWithExtension, "", File.Extension);
	
EndProcedure

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
// 
// 
// 
//
// Parameters:
//  Object - ExchangePlanObject
//         - ConstantValueManager
//         - CatalogObject
//         - DocumentObject
//         - SequenceRecordSet
//         - ChartOfCharacteristicTypesObject
//         - ChartOfAccountsObject
//         - ChartOfCalculationTypesObject
//         - BusinessProcessObject
//         - TaskObject
//         - ObjectDeletion
//         - InformationRegisterRecordSet
//         - AccumulationRegisterRecordSet
//         - AccountingRegisterRecordSet
//         - CalculationRegisterRecordSet
//         - RecalculationRecordSet
//
// IsExchangePlanNode - Boolean
//
Procedure DisableRecordingControl(Object, IsExchangePlanNode = False) Export
	
	Object.AdditionalProperties.Insert("DontControlObjectsToDelete");
	Object.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	Object.DataExchange.Load = True;
	If Not IsExchangePlanNode Then
		Object.DataExchange.Recipients.AutoFill = False;
	EndIf;
	
EndProcedure

Function TemplateExists(FullTemplateName) Export
	
	Template = Metadata.FindByFullName(FullTemplateName);
	If TypeOf(Template) = Type("MetadataObject") Then 
		
		Var_477_Template = New Structure("TemplateType");
		FillPropertyValues(Var_477_Template, Template);
		TemplateType = Undefined;
		If Var_477_Template.Property("TemplateType", TemplateType) Then 
			Return TemplateType <> Undefined;
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseData

#Region AttributesValues

// 
// 
// Parameters:
//  FullMetadataObjectName - String -  full name of the object being checked.
//  ExpressionsToCheck       - Array -  field names or verifiable expressions of the metadata object.
// 
// Returns:
//  Structure:
//   * Error         - Boolean -  an error was found.
//   * ErrorDescription - String -  description of errors found.
//
// Example:
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
//
Function CheckIfObjectAttributesExist(FullMetadataObjectName, ExpressionsToCheck)
	
	ObjectMetadata = MetadataObjectByFullName(FullMetadataObjectName);
	If ObjectMetadata = Undefined Then 
		Return New Structure("Error, ErrorDescription", True, 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Non-existing metadata object: ""%1"".';"), FullMetadataObjectName));
	EndIf;

	// 
	// 
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Schema = New QuerySchema;
	Package = Schema.QueryBatch.Add(Type("QuerySchemaSelectQuery"));
	Operator = Package.Operators.Get(0);
	
	Source = Operator.Sources.Add(FullMetadataObjectName, "Table");
	ErrorText = "";
	
	For Each CurrentExpression In ExpressionsToCheck Do
		
		If Not QuerySchemaSourceFieldAvailable(Source, CurrentExpression) Then 
			ErrorText = ErrorText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'The ""%1"" object field does not exist.';"), CurrentExpression);
		EndIf;
		
	EndDo;
		
	Return New Structure("Error, ErrorDescription", Not IsBlankString(ErrorText), ErrorText);
	
EndFunction

// 
// 
//
Function QuerySchemaSourceFieldAvailable(OperatorSource, ExpressToCheck)
	
	FieldNameParts = StrSplit(ExpressToCheck, ".");
	AvailableFields = OperatorSource.Source.AvailableFields;
	
	CurrentFieldNamePart = 0;
	While CurrentFieldNamePart < FieldNameParts.Count() Do 
		
		CurrentField = AvailableFields.Find(FieldNameParts.Get(CurrentFieldNamePart)); 
		
		If CurrentField = Undefined Then 
			Return False;
		EndIf;
		
		// 
		CurrentFieldNamePart = CurrentFieldNamePart + 1;
		AvailableFields = CurrentField.Fields;
		
	EndDo;
	
	Return True;
	
EndFunction

#EndRegion

#Region ReplaceReferences

Function MarkUsageInstances(Val ExecutionParameters, Val Ref, Val DestinationRef, Val SearchTable)
	SetPrivilegedMode(True);
	
	// 
	Result = New Structure;
	Result.Insert("UsageInstances", SearchTable.FindRows(New Structure("Ref", Ref)));
	Result.Insert("MarkupErrors",     New Array);
	Result.Insert("Success",              True);
	
	For Each UsageInstance1 In Result.UsageInstances Do
		If UsageInstance1.IsInternalData Then
			Continue; // 
		EndIf;
		
		Information = TypeInformation(UsageInstance1.Metadata, ExecutionParameters);
		If Information.Kind = "CONSTANT" Then
			UsageInstance1.ReplacementKey = "Constant";
			UsageInstance1.DestinationRef = DestinationRef;
			
		ElsIf Information.Kind = "SEQUENCE" Then
			UsageInstance1.ReplacementKey = "Sequence";
			UsageInstance1.DestinationRef = DestinationRef;
			
		ElsIf Information.Kind = "INFORMATIONREGISTER" Then
			UsageInstance1.ReplacementKey = "InformationRegister";
			UsageInstance1.DestinationRef = DestinationRef;
			
		ElsIf Information.Kind = "ACCOUNTINGREGISTER"
			Or Information.Kind = "ACCUMULATIONREGISTER"
			Or Information.Kind = "CALCULATIONREGISTER" Then
			UsageInstance1.ReplacementKey = "RecordKey";
			UsageInstance1.DestinationRef = DestinationRef;
			
		ElsIf Information.Referential Then
			UsageInstance1.ReplacementKey = "Object";
			UsageInstance1.DestinationRef = DestinationRef;
			
		Else
			// 
			Result.Success = False;
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot replace references in ""%1"".';"), Information.FullName);
			ErrorDescription = New Structure("Object, Text", UsageInstance1.Data, Text);
			Result.MarkupErrors.Add(ErrorDescription);
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// Parameters:
//  SearchTable - See UsageInstances
//
Procedure ReplaceRefsUsingShortTransactions(Result, Val ExecutionParameters, Val Duplicate1, Val SearchTable)
	
	// 
	RefFilter = New Structure("Ref, ReplacementKey");
	
	Result.HasErrors = False;
	
	RefFilter.Ref = Duplicate1;
	RefFilter.ReplacementKey = "Constant";
	
	UsageInstances = SearchTable.FindRows(RefFilter);
	For Each UsageInstance1 In UsageInstances Do
		ReplaceInConstant(Result, UsageInstance1, ExecutionParameters);
	EndDo;
	
	RefFilter.ReplacementKey = "Object";
	UsageInstances = SearchTable.FindRows(RefFilter);
	For Each UsageInstance1 In UsageInstances Do
		ReplaceInObject(Result, UsageInstance1, ExecutionParameters);
	EndDo;
	
	RefFilter.ReplacementKey = "RecordKey";
	UsageInstances = SearchTable.FindRows(RefFilter);
	For Each UsageInstance1 In UsageInstances Do
		ReplaceInSet(Result, UsageInstance1, ExecutionParameters);
	EndDo;
	
	RefFilter.ReplacementKey = "Sequence";
	UsageInstances = SearchTable.FindRows(RefFilter);
	For Each UsageInstance1 In UsageInstances Do
		ReplaceInSet(Result, UsageInstance1, ExecutionParameters);
	EndDo;
	
	RefFilter.ReplacementKey = "InformationRegister";
	UsageInstances = SearchTable.FindRows(RefFilter);
	For Each UsageInstance1 In UsageInstances Do
		ReplaceInInformationRegister(Result, UsageInstance1, ExecutionParameters);
	EndDo;
	
	ReplacementsToProcess = New Array;
	ReplacementsToProcess.Add(Duplicate1);
	
	If ExecutionParameters.ShouldDeleteDirectly
		Or ExecutionParameters.MarkForDeletion Then
		
  		SetDeletionMarkForObjects(Result, ReplacementsToProcess, ExecutionParameters);
	Else
		
		RepeatSearchTable = UsageInstances(ReplacementsToProcess,, ExecutionParameters.UsageInstancesSearchParameters);
		AddModifiedObjectReplacementResults(Result, RepeatSearchTable);
	EndIf;
	
EndProcedure

Procedure ReplaceInConstant(Result, Val UsageInstance1, Val WriteParameters)
	
	SetPrivilegedMode(True);
	
	Data = UsageInstance1.Data;
	MetadataConstants = UsageInstance1.Metadata;
	DataPresentation = String(Data);
	
	Filter = New Structure("Data, ReplacementKey", Data, "Constant");
	RowsToProcess = UsageInstance1.Owner().FindRows(Filter); // See UsageInstances
	For Each TableRow In RowsToProcess Do
		TableRow.ReplacementKey = "";
	EndDo;

	ActionState = "";
	BeginTransaction();
	
	Try
		Block = New DataLock;
		Block.Add(MetadataConstants.FullName());
		Try
			Block.Lock();
		Except
			ActionState = "LockError";
			RefinementErrors = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Failed to make replacement in ""%1"". Another user is editing the data.
				|Please try again later.';"), 
				DataPresentation);
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, RefinementErrors);
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
	
		ManagerOfConstant = Constants[MetadataConstants.Name].CreateValueManager();
		ManagerOfConstant.Read();
		
		ReplacementPerformed = False;
		For Each TableRow In RowsToProcess Do
			If ManagerOfConstant.Value = TableRow.Ref Then
				ManagerOfConstant.Value = TableRow.DestinationRef;
				ReplacementPerformed = True;
			EndIf;
		EndDo;
		
		If Not ReplacementPerformed Then
			RollbackTransaction();
			Return;
		EndIf;	
		 
		// 
		If Not WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		Try
			WriteObject(ManagerOfConstant, WriteParameters);
		Except
			ActionState = "WritingError";
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
				NStr("en = 'Couldn''t make replacement due to:';"));
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
		
		If Not WriteParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(True);
		EndIf;
			
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(RefReplacementEventLogMessageText(), EventLogLevel.Error,
			MetadataConstants,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		If ActionState = "WritingError" Then
			For Each TableRow In RowsToProcess Do
				RegisterReplacementError(Result, TableRow.Ref, 
					ReplacementErrorDescription("WritingError", Data, DataPresentation, ErrorInfo()));
			EndDo;
		Else		
			RegisterReplacementError(Result, TableRow.Ref, 
				ReplacementErrorDescription(ActionState, Data, DataPresentation, ErrorInfo()));
		EndIf;		
	EndTry;
	
EndProcedure

Procedure ReplaceInObject(Result, Val UsageInstance1, Val ExecutionParameters)
	
	SetPrivilegedMode(True);
	
	Data = UsageInstance1.Data;
	
	// 
	Filter = New Structure("Data, ReplacementKey", Data, "Object");
	RowsToProcess = UsageInstance1.Owner().FindRows(Filter); // See UsageInstances
	
	DataPresentation = SubjectString(Data);
	ActionState = "";
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		LockUsageInstance(ExecutionParameters, Block, UsageInstance1);
		Try
			Block.Lock();
		Except
			ActionState = "LockError";
			RefinementErrors = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Failed to make replacement in ""%1"". Another user is editing the data.
				|Please try again later.';"), 
				DataPresentation);
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, RefinementErrors);
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
		
		WritingObjects = ModifiedObjectsOnReplaceInObject(ExecutionParameters, UsageInstance1, RowsToProcess);
		
		// 
		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		Try
			If ExecutionParameters.IncludeBusinessLogic Then
				// 
				NewExecutionParameters = CopyRecursive(ExecutionParameters);
				NewExecutionParameters.IncludeBusinessLogic = False;
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, NewExecutionParameters);
				EndDo;
				// 
				NewExecutionParameters.IncludeBusinessLogic = True;
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, NewExecutionParameters);
				EndDo;
			Else
				// 
				For Each KeyValue In WritingObjects Do
					WriteObject(KeyValue.Key, ExecutionParameters);
				EndDo;
			EndIf;
		Except
			ActionState = "WritingError";
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
				NStr("en = 'Couldn''t make replacement due to:';"));
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Information = ErrorInfo();
		WriteLogEvent(RefReplacementEventLogMessageText(), EventLogLevel.Error,
			UsageInstance1.Metadata,,	ErrorProcessing.DetailErrorDescription(Information));
		Error = ReplacementErrorDescription(ActionState, Data, DataPresentation, ErrorInfo());
		If ActionState = "WritingError" Then
			For Each TableRow In RowsToProcess Do
				RegisterReplacementError(Result, TableRow.Ref, Error);
			EndDo;
		Else	
			RegisterReplacementError(Result, UsageInstance1.Ref, Error);
		EndIf;
	EndTry;
	
	// 
	For Each TableRow In RowsToProcess Do
		TableRow.ReplacementKey = "";
	EndDo;
	
EndProcedure

Procedure ReplaceInSet(Result, Val UsageInstance1, Val ExecutionParameters)
	SetPrivilegedMode(True);
	
	Data = UsageInstance1.Data;
	RegisterMetadata = UsageInstance1.Metadata;
	DataPresentation = String(Data);
	
	// 
	Filter = New Structure("Data, ReplacementKey");
	FillPropertyValues(Filter, UsageInstance1);
	RowsToProcess = UsageInstance1.Owner().FindRows(Filter); // See UsageInstances
	
	SetDetails = RecordKeyDetails(RegisterMetadata);
	RecordSet = SetDetails.RecordSet; // InformationRegisterRecordSet
	
	ReplacementPairs = New Map;
	For Each TableRow In RowsToProcess Do
		ReplacementPairs.Insert(TableRow.Ref, TableRow.DestinationRef);
	EndDo;
	
	// 
	For Each TableRow In RowsToProcess Do
		TableRow.ReplacementKey = "";
	EndDo;
	
	ActionState = "";
	BeginTransaction();
	
	Try
		
		// 
		Block = New DataLock;
		For Each KeyValue In SetDetails.MeasurementList Do
			DimensionType = KeyValue.Value;
			Name          = KeyValue.Key;
			Value     = Data[Name];
			
			For Each TableRow In RowsToProcess Do
				CurrentRef = TableRow.Ref;
				If DimensionType.ContainsType(TypeOf(CurrentRef)) Then
					Block.Add(SetDetails.LockSpace).SetValue(Name, CurrentRef);
				EndIf;
			EndDo;
			
			RecordSet.Filter[Name].Set(Value);
		EndDo;
		
		Try
			Block.Lock();
		Except
			ActionState = "LockError";
			RefinementErrors = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Failed to make replacement in ""%1"". Another user is editing the data.
				|Please try again later.';"), 
				DataPresentation);
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo, RefinementErrors);
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
				
		RecordSet.Read();
		ReplaceInRowCollection("RecordSet", "RecordSet", RecordSet, RecordSet, SetDetails.FieldList, ReplacementPairs);
		
		If RecordSet.Modified() Then
			RollbackTransaction();
			Return;
		EndIf;	

		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		Try
			WriteObject(RecordSet, ExecutionParameters);
		Except
			ActionState = "WritingError";
			ErrorInfo = ErrorInfo();
			Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
				NStr("en = 'Couldn''t make replacement due to:';"));
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		EndTry;
		
		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(True);
		EndIf;
		
		CommitTransaction();
		
	Except
		RollbackTransaction();
		Information = ErrorInfo();
		WriteLogEvent(RefReplacementEventLogMessageText(), EventLogLevel.Error,
			RegisterMetadata,, ErrorProcessing.DetailErrorDescription(Information));
		Error = ReplacementErrorDescription(ActionState, Data, DataPresentation, ErrorInfo());
		If ActionState = "WritingError" Then
			For Each TableRow In RowsToProcess Do
				RegisterReplacementError(Result, TableRow.Ref, Error);
			EndDo;
		Else	
			RegisterReplacementError(Result, UsageInstance1.Ref, Error);
		EndIf;	
	EndTry;
	
EndProcedure

Procedure ReplaceInInformationRegister(Result, Val UsageInstance1, Val ExecutionParameters)
	
	If UsageInstance1.Processed Then
		Return;
	EndIf;
	UsageInstance1.Processed = True;
	
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
	//
	// 
	
	SetPrivilegedMode(True);
	
	Duplicate1    = UsageInstance1.Ref;
	Original = UsageInstance1.DestinationRef;
	
	RegisterMetadata = UsageInstance1.Metadata;
	RegisterRecordKey = UsageInstance1.Data;
	
	Information = TypeInformation(RegisterMetadata, ExecutionParameters);
	
	TwoSetsRequired = False;
	For Each KeyValue In Information.Dimensions Do
		DuplicateDimensionValue = RegisterRecordKey[KeyValue.Key];
		If DuplicateDimensionValue = Duplicate1
			Or ExecutionParameters.SuccessfulReplacements[DuplicateDimensionValue] = Duplicate1 Then
			TwoSetsRequired = True; // 
			Break;
		EndIf;
	EndDo;
	
	Manager = ObjectManagerByFullName(Information.FullName);
	DuplicateRecordSet = Manager.CreateRecordSet();
	
	If TwoSetsRequired Then
		OriginalDimensionValues = New Structure;
		OriginalRecordSet = Manager.CreateRecordSet();
	EndIf;
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		DuplicateLock = Block.Add(Information.FullName);
		If TwoSetsRequired Then
			OriginalLock = Block.Add(Information.FullName);
		EndIf;
		
		For Each KeyValue In Information.Dimensions Do
			DuplicateDimensionValue = RegisterRecordKey[KeyValue.Key];
			
			// 
			//   
			//   
			//   
			//   
			NewDuplicateDimensionValue = ExecutionParameters.SuccessfulReplacements[DuplicateDimensionValue];
			If NewDuplicateDimensionValue <> Undefined Then
				DuplicateDimensionValue = NewDuplicateDimensionValue;
			EndIf;
			
			DuplicateRecordSet.Filter[KeyValue.Key].Set(DuplicateDimensionValue);
			
			 // 
			DuplicateLock.SetValue(KeyValue.Key, DuplicateDimensionValue);
			
			
			If TwoSetsRequired Then
				If DuplicateDimensionValue = Duplicate1 Then
					OriginalDimensionValue = Original;
				Else
					OriginalDimensionValue = DuplicateDimensionValue;
				EndIf;
				
				OriginalRecordSet.Filter[KeyValue.Key].Set(OriginalDimensionValue);
				OriginalDimensionValues.Insert(KeyValue.Key, OriginalDimensionValue);
				
				// 
				OriginalLock.SetValue(KeyValue.Key, OriginalDimensionValue);
			EndIf;
		EndDo;
		
		Block.Lock();
		
		DuplicateRecordSet.Read();
		If DuplicateRecordSet.Count() = 0 Then 
			RollbackTransaction();
			Return;
		EndIf;
		DuplicateRecord = DuplicateRecordSet[0];
		
		If TwoSetsRequired Then
			// 
			OriginalRecordSet.Read();
			If OriginalRecordSet.Count() = 0 Then
				OriginalRecord = OriginalRecordSet.Add();
				FillPropertyValues(OriginalRecord, DuplicateRecord);
				FillPropertyValues(OriginalRecord, OriginalDimensionValues);
			Else
				OriginalRecord = OriginalRecordSet[0];
			EndIf;
		Else
			// 
			OriginalRecordSet = DuplicateRecordSet;
			OriginalRecord = DuplicateRecord; // 
		EndIf;
		
		// 
		For Each KeyValue In Information.Resources Do
			AttributeValueInOriginal = OriginalRecord[KeyValue.Key];
			If AttributeValueInOriginal = Duplicate1 Then
				OriginalRecord[KeyValue.Key] = Original;
			EndIf;
		EndDo;
		For Each KeyValue In Information.Attributes Do
			AttributeValueInOriginal = OriginalRecord[KeyValue.Key];
			If AttributeValueInOriginal = Duplicate1 Then
				OriginalRecord[KeyValue.Key] = Original;
			EndIf;
		EndDo;
		
		If Not ExecutionParameters.WriteInPrivilegedMode Then
			SetPrivilegedMode(False);
		EndIf;
		
		// 
		If TwoSetsRequired Then
			DuplicateRecordSet.Clear();
			WriteObject(DuplicateRecordSet, ExecutionParameters);
		EndIf;
		
		// 
		If OriginalRecordSet.Modified() Then
			WriteObject(OriginalRecordSet, ExecutionParameters);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		RegisterErrorInTable(Result, Duplicate1, Original, RegisterRecordKey, Information, 
			"LockForRegister", ErrorInfo());
	EndTry
	
EndProcedure

Function ModifiedObjectsOnReplaceInObject(ExecutionParameters, UsageInstance1, RowsToProcess)
	Data = UsageInstance1.Data;
	SequencesDetails = SequencesDetails(UsageInstance1.Metadata);
	RegisterRecordsDetails            = RegisterRecordsDetails(UsageInstance1.Metadata);
	TaskDetails				= TaskDetails(UsageInstance1.Metadata);
	
	SetPrivilegedMode(True);
	
	// 
	Modified1 = New Map;
	
	// 
	LongDesc = ObjectDetails(Data.Metadata());
	Try
		Object = Data.GetObject();
	Except
		// 
		Object = Undefined;
	EndTry;
	
	If Object = Undefined Then
		Return Modified1;
	EndIf;
	
	For Each RegisterRecordDetails In RegisterRecordsDetails Do
		RegisterRecordDetails.RecordSet.Filter.Recorder.Set(Data);
		RegisterRecordDetails.RecordSet.Read();
	EndDo;
	
	For Each SequenceDetails In SequencesDetails Do
		SequenceDetails.RecordSet.Filter.Recorder.Set(Data);
		SequenceDetails.RecordSet.Read();
	EndDo;
	
	// 
	ReplacementPairs = New Map;
	For Each UsageInstance1 In RowsToProcess Do
		ReplacementPairs.Insert(UsageInstance1.Ref, UsageInstance1.DestinationRef);
	EndDo;
	
	ExecuteReplacementInObjectAttributes(Object, LongDesc, ReplacementPairs);
		
	// RegisterRecords
	For Each RegisterRecordDetails In RegisterRecordsDetails Do
		ReplaceInRowCollection(
			"RegisterRecords",
			RegisterRecordDetails.LockSpace,
			RegisterRecordDetails.RecordSet,
			RegisterRecordDetails.RecordSet,
			RegisterRecordDetails.FieldList,
			ReplacementPairs);
	EndDo;
	
	// Sequences
	For Each SequenceDetails In SequencesDetails Do
		ReplaceInRowCollection(
			"Sequences",
			SequenceDetails.LockSpace,
			SequenceDetails.RecordSet,
			SequenceDetails.RecordSet,
			SequenceDetails.FieldList,
			ReplacementPairs);
	EndDo;
	
	For Each RegisterRecordDetails In RegisterRecordsDetails Do
		If RegisterRecordDetails.RecordSet.Modified() Then
			Modified1.Insert(RegisterRecordDetails.RecordSet, False);
		EndIf;
	EndDo;
	
	For Each SequenceDetails In SequencesDetails Do
		If SequenceDetails.RecordSet.Modified() Then
			Modified1.Insert(SequenceDetails.RecordSet, False);
		EndIf;
	EndDo;
	
	If TaskDetails <> Undefined Then
	 	
		ProcessTask = ProcessTasks(Data, TaskDetails.LockSpace);
		While ProcessTask.Next() Do
			
			TaskObject = ProcessTask.Ref.GetObject();
			Filter = New Structure("Data, ReplacementKey", ProcessTask.Ref, "Object");
			TaskLinesToProcess = UsageInstance1.Owner().FindRows(Filter); // See UsageInstances
			For Each TaskUsageInstance In TaskLinesToProcess Do
				ReplacementPairs.Insert(TaskUsageInstance.Ref, TaskUsageInstance.DestinationRef);		
			EndDo;
			ExecuteReplacementInObjectAttributes(TaskObject, TaskDetails, ReplacementPairs);
			
			If TaskObject.Modified() Then
				Modified1.Insert(TaskObject, False);
			EndIf;
			
		EndDo;
	
	EndIf;
	
	// 
	If Object.Modified() Then
		Modified1.Insert(Object, LongDesc.CanBePosted);
	EndIf;
	
	Return Modified1;
EndFunction

Function ProcessTasks(BusinessProcess, TasksType)

	QueryText = "SELECT
	|	TableName.Ref
	|FROM
	|	&TableName AS TableName
	|WHERE
	|	TableName.BusinessProcess = &BusinessProcess";
	QueryText = StrReplace(QueryText, "&TableName", TasksType);
	Query = New Query(QueryText);
	Query.SetParameter("BusinessProcess", BusinessProcess);
	Return Query.Execute().Select();

EndFunction

Procedure ExecuteReplacementInObjectAttributes(Object, LongDesc, ReplacementPairs)
	
	// Attributes
	For Each KeyValue In LongDesc.Attributes Do
		Name = KeyValue.Key;
		DestinationRef = ReplacementPairs[ Object[Name] ];
		If DestinationRef <> Undefined Then
			RegisterReplacement(Object, Object[Name], DestinationRef, "Attributes", Name);
			Object[Name] = DestinationRef;
		EndIf;
	EndDo;
	
	// 
	For Each KeyValue In LongDesc.StandardAttributes Do
		Name = KeyValue.Key;
		DestinationRef = ReplacementPairs[ Object[Name] ];
		If DestinationRef <> Undefined Then
			RegisterReplacement(Object, Object[Name], DestinationRef, "StandardAttributes", Name);
			Object[Name] = DestinationRef;
		EndIf;
	EndDo;
	
	// 
	For Each Item In LongDesc.TabularSections Do
		ReplaceInRowCollection(
			"TabularSections",
			Item.Name,
			Object,
			Object[Item.Name],
			Item.FieldList,
			ReplacementPairs);
	EndDo;
	
	// 
	For Each Item In LongDesc.StandardTabularSections Do
		ReplaceInRowCollection(
			"StandardTabularSections",
			Item.Name,
			Object,
			Object[Item.Name],
			Item.FieldList,
			ReplacementPairs);
	EndDo;

	For Each Attribute In LongDesc.AddressingAttributes Do
		Name = Attribute.Key;
		DestinationRef = ReplacementPairs[ Object[Name] ];
		If DestinationRef <> Undefined Then
			RegisterReplacement(Object, Object[Name], DestinationRef, "AddressingAttributes", Name);
			Object[Name] = DestinationRef;
		EndIf;
	EndDo;

EndProcedure

Procedure RegisterReplacement(Object, DuplicateRef, OriginalRef, AttributeKind, AttributeName, 
	IndexOf = Undefined, ColumnName = Undefined)
	
	HasAdditionalProperties = New Structure("AdditionalProperties");
	FillPropertyValues(HasAdditionalProperties, Object);
	If TypeOf(HasAdditionalProperties.AdditionalProperties) <> Type("Structure") Then
		Return;
	EndIf;
	
	AdditionalProperties = Object.AdditionalProperties;
	AdditionalProperties.Insert("ReferenceReplacement", True);
	CompletedReplacements = CommonClientServer.StructureProperty(AdditionalProperties, "CompletedReplacements");
	If CompletedReplacements = Undefined Then
		CompletedReplacements = New Array;
		AdditionalProperties.Insert("CompletedReplacements", CompletedReplacements);
	EndIf;
	
	ReplacementDetails = New Structure;
	ReplacementDetails.Insert("DuplicateRef", DuplicateRef);
	ReplacementDetails.Insert("OriginalRef", OriginalRef);
	ReplacementDetails.Insert("AttributeKind", AttributeKind);
	ReplacementDetails.Insert("AttributeName", AttributeName);
	ReplacementDetails.Insert("IndexOf", IndexOf);
	ReplacementDetails.Insert("ColumnName", ColumnName);
	CompletedReplacements.Add(ReplacementDetails);
	
EndProcedure

Procedure SetDeletionMarkForObjects(Result, Val RefsToDelete, Val ExecutionParameters)
	
	SetPrivilegedMode(True);
	HasExternalTransaction = TransactionActive();
	AllUsageInstances = UsageInstances(RefsToDelete,,ExecutionParameters.UsageInstancesSearchParameters);
	For Each RefToDelete In RefsToDelete Do
		Information = TypeInformation(TypeOf(RefToDelete), ExecutionParameters);
		Block = New DataLock;
		Block.Add(Information.FullName).SetValue("Ref", RefToDelete);
		
		BeginTransaction();
		Try
			IsLockError = True;
			Block.Lock();
			
			IsLockError = False;
 			Success = SetDeletionMark(Result, RefToDelete, AllUsageInstances, 
				ExecutionParameters, HasExternalTransaction);
			If Not Success Then
				RollbackTransaction();
				Continue;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			If IsLockError Then 
				RegisterErrorInTable(Result, RefToDelete, Undefined, RefToDelete, Information, 
					"DataLockForDuplicateDeletion", ErrorInfo());
			EndIf;
			If HasExternalTransaction Then
				Raise;
			EndIf;	
		EndTry;
			
	EndDo;
	
EndProcedure

Function SetDeletionMark(Result, Val RefToDelete, Val AllUsageInstances, Val ExecutionParameters, 
	HasExternalTransaction)

	SetPrivilegedMode(True);
	
	RepresentationOfTheReference = SubjectString(RefToDelete);
	Filter = New Structure("Ref");
	Filter.Ref = RefToDelete;
	UsageInstances = AllUsageInstances.FindRows(Filter);
	
	IndexOf = UsageInstances.UBound();
	While IndexOf >= 0 Do
		If UsageInstances[IndexOf].AuxiliaryData Then
			UsageInstances.Delete(IndexOf);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	If UsageInstances.Count() > 0 Then
		AddModifiedObjectReplacementResults(Result, UsageInstances);
		Return False; // 
	EndIf;
	
	Object = RefToDelete.GetObject(); // DocumentObject, CatalogObject
	If Object = Undefined Then
		Return False; // 
	EndIf;
	
	If Not ExecutionParameters.WriteInPrivilegedMode Then
		SetPrivilegedMode(False);
	EndIf;
		
	Success = True;
	Try 
		WriteObjectWithMessageInterception(Object, "DeletionMark", Undefined, ExecutionParameters);
		Result.QueueForDirectDeletion.Add(Object.Ref);
	Except
		Success = False;
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo,
			NStr("en = 'Cannot mark the item for deletion. Reason:';"));
		Try
			Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
		Except
			ErrorDescription = ReplacementErrorDescription("DeletionError", RefToDelete, RepresentationOfTheReference, ErrorInfo());
			RegisterReplacementError(Result, RefToDelete, ErrorDescription);
			If HasExternalTransaction Then
				Raise;
			EndIf;	
		EndTry;
	EndTry;
	
	Return Success;
		
EndFunction

Procedure AddModifiedObjectReplacementResults(Result, RepeatSearchTable)
	
	Filter = New Structure("Ref, ErrorObject");
	For Each TableRow In RepeatSearchTable Do
		Test = New Structure("AuxiliaryData", False);
		FillPropertyValues(Test, TableRow);
		If Test.AuxiliaryData Then
			Continue;
		EndIf;
		
		Filter.ErrorObject = TableRow.Data;
		Filter.Ref       = TableRow.Ref;
		If Result.Errors.FindRows(Filter).Count() > 0 Then
			Continue; // 
		EndIf;

		RegisterReplacementError(Result, TableRow.Ref, 
			ReplacementErrorDescription("DataChanged1", TableRow.Data, SubjectString(TableRow.Data),
				NStr("en = 'Some of the instances were not replaced. Probably these instances were added or edited by other users.';")));
	EndDo;
	
EndProcedure

Procedure LockUsageInstance(ExecutionParameters, Block, UsageInstance1)
	
	If UsageInstance1.ReplacementKey = "Constant" Then
		
		Block.Add(UsageInstance1.Metadata.FullName());
		
	ElsIf UsageInstance1.ReplacementKey = "Object" Then
		
		ObjectRef2     = UsageInstance1.Data;
		ObjectMetadata = UsageInstance1.Metadata;
		
		// 
		Block.Add(ObjectMetadata.FullName()).SetValue("Ref", ObjectRef2);
		
		// 
		RegisterRecordsDetails = RegisterRecordsDetails(ObjectMetadata);
		For Each Item In RegisterRecordsDetails Do
			Block.Add(Item.LockSpace + ".RecordSet").SetValue("Recorder", ObjectRef2);
		EndDo;
		
		// 
		SequencesDetails = SequencesDetails(ObjectMetadata);
		For Each Item In SequencesDetails Do
			Block.Add(Item.LockSpace).SetValue("Recorder", ObjectRef2);
		EndDo;
		
		// 
		TaskDetails = TaskDetails(ObjectMetadata);
		If TaskDetails <> Undefined Then
			Block.Add(TaskDetails.LockSpace).SetValue("BusinessProcess", ObjectRef2);	
		EndIf;
		
	ElsIf UsageInstance1.ReplacementKey = "Sequence" Then
		
		ObjectRef2     = UsageInstance1.Data;
		ObjectMetadata = UsageInstance1.Metadata;
		
		SequencesDetails = SequencesDetails(ObjectMetadata);
		For Each Item In SequencesDetails Do
			Block.Add(Item.LockSpace).SetValue("Recorder", ObjectRef2);
		EndDo;
		
	ElsIf UsageInstance1.ReplacementKey = "RecordKey"
		Or UsageInstance1.ReplacementKey = "InformationRegister" Then
		
		Information = TypeInformation(UsageInstance1.Metadata, ExecutionParameters);
		DuplicateType = UsageInstance1.RefType;
		OriginalType = TypeOf(UsageInstance1.DestinationRef);
		
		For Each KeyValue In Information.Dimensions Do
			DimensionType = KeyValue.Value.Type;
			If DimensionType.ContainsType(DuplicateType) Then
				DataLockByDimension = Block.Add(Information.FullName);
				DataLockByDimension.SetValue(KeyValue.Key, UsageInstance1.Ref);
			EndIf;
			If DimensionType.ContainsType(OriginalType) Then
				DataLockByDimension = Block.Add(Information.FullName);
				DataLockByDimension.SetValue(KeyValue.Key, UsageInstance1.DestinationRef);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure DisableAccessKeysUpdate(Value)
	
	If SubsystemExists("StandardSubsystems.AccessManagement") Then
		SetPrivilegedMode(True);
		ModuleAccessManagement = CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(Value);
	EndIf;
	
EndProcedure	

// Parameters:
//   MetadataObject - MetadataObject
// 	
// Returns:
//  Array of Structure:
//   * FieldList - Structure
//   * DimensionStructure - Structure
//   * MasterDimentionList - Structure
//   * RecordSet - InformationRegisterRecordSet
//   * LockSpace - String
//
Function RegisterRecordsDetails(Val MetadataObject)
	
	RegisterRecordsDetails = New Array;
	If Not Metadata.Documents.Contains(MetadataObject) Then
		Return RegisterRecordsDetails;
	EndIf;
	
	For Each Movement In MetadataObject.RegisterRecords Do
		
		If Metadata.AccumulationRegisters.Contains(Movement) Then
			RecordSet = AccumulationRegisters[Movement.Name].CreateRecordSet();
			ExcludeFields = "Active, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.InformationRegisters.Contains(Movement) Then
			RecordSet = InformationRegisters[Movement.Name].CreateRecordSet();
			ExcludeFields = "Active, RecordType, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.AccountingRegisters.Contains(Movement) Then
			RecordSet = AccountingRegisters[Movement.Name].CreateRecordSet();
			ExcludeFields = "Active, RecordType, LineNumber, Period, Recorder"; 
			
		ElsIf Metadata.CalculationRegisters.Contains(Movement) Then
			RecordSet = CalculationRegisters[Movement.Name].CreateRecordSet();
			ExcludeFields = "Active, EndOfBasePeriod, BegOfBasePeriod, LineNumber, ActionPeriod,
			                |EndOfActionPeriod, BegOfActionPeriod, RegistrationPeriod, Recorder, ReversingEntry,
			                |ActualActionPeriod";
		Else
			// 
			Continue;
		EndIf;
		
		// 
		// 
		LongDesc = ObjectFieldLists(RecordSet, Movement.Dimensions, ExcludeFields);
		If LongDesc.FieldList.Count() = 0 Then
			// 
			Continue;
		EndIf;
		
		LongDesc.Insert("RecordSet", RecordSet);
		LongDesc.Insert("LockSpace", Movement.FullName() );
		
		RegisterRecordsDetails.Add(LongDesc);
	EndDo;
	
	Return RegisterRecordsDetails;
EndFunction

// Parameters:
//  Meta - MetadataObject
// 
// Returns:
//  Array of Structure:
//    * RecordSet - SequenceRecordSet
//    * LockSpace - String
//    * Dimensions - Structure
// 
Function SequencesDetails(Val Meta)
	
	SequencesDetails = New Array;
	If Not Metadata.Documents.Contains(Meta) Then
		Return SequencesDetails;
	EndIf;
	
	For Each Sequence In Metadata.Sequences Do
		If Not Sequence.Documents.Contains(Meta) Then
			Continue;
		EndIf;
		
		TableName = Sequence.FullName();
		
		// 
		LongDesc = ObjectFieldLists(TableName, Sequence.Dimensions, "Recorder");
		If LongDesc.FieldList.Count() > 0 Then
			
			LongDesc.Insert("RecordSet",           Sequences[Sequence.Name].CreateRecordSet());
			LongDesc.Insert("LockSpace", TableName + ".Records");
			LongDesc.Insert("Dimensions",              New Structure);
			
			SequencesDetails.Add(LongDesc);
		EndIf;
		
	EndDo;
	
	Return SequencesDetails;
EndFunction

// Returns:
//   Structure:
//   * StandardAttributes - Structure
//   * AddressingAttributes - Structure
//   * Attributes - Structure
//   * StandardTabularSections - Array of Structure:
//    ** Name - String
//    ** FieldList - Structure
//   * TabularSections - Array of Structure:
//    ** Name - String
//    ** FieldList - Structure
//   * CanBePosted - Boolean
//
Function ObjectDetails(Val MetadataObject)
	
	AllRefsType = AllRefsTypeDetails();
	
	Candidates = New Structure("Attributes, StandardAttributes, TabularSections, StandardTabularSections, AddressingAttributes");
	FillPropertyValues(Candidates, MetadataObject);
	
	ObjectDetails = New Structure;
	
	ObjectDetails.Insert("Attributes", New Structure);
	If Candidates.Attributes <> Undefined Then
		For Each MetaAttribute In Candidates.Attributes Do
			If DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
				ObjectDetails.Attributes.Insert(MetaAttribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("StandardAttributes", New Structure);
	If Candidates.StandardAttributes <> Undefined Then
		ToExclude = New Structure("Ref");
		
		For Each MetaAttribute In Candidates.StandardAttributes Do
			Name = MetaAttribute.Name;
			If Not ToExclude.Property(Name) And DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
				ObjectDetails.Attributes.Insert(MetaAttribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("TabularSections", New Array);
	If Candidates.TabularSections <> Undefined Then
		For Each MetaTable In Candidates.TabularSections Do
			
			FieldList = New Structure;
			For Each MetaAttribute In MetaTable.Attributes Do
				If DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
					FieldList.Insert(MetaAttribute.Name);
				EndIf;
			EndDo;
			
			If FieldList.Count() > 0 Then
				ObjectDetails.TabularSections.Add(New Structure("Name, FieldList", MetaTable.Name, FieldList));
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("StandardTabularSections", New Array);
	If Candidates.StandardTabularSections <> Undefined Then
		For Each MetaTable In Candidates.StandardTabularSections Do
			
			FieldList = New Structure;
			For Each MetaAttribute In MetaTable.StandardAttributes Do
				If DescriptionTypesOverlap(MetaAttribute.Type, AllRefsType) Then
					FieldList.Insert(MetaAttribute.Name);
				EndIf;
			EndDo;
			
			If FieldList.Count() > 0 Then
				ObjectDetails.StandardTabularSections.Add(New Structure("Name, FieldList", MetaTable.Name, FieldList));
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("AddressingAttributes", New Structure);
	If Candidates.AddressingAttributes <> Undefined Then
		For Each Attribute In Candidates.AddressingAttributes Do
			If DescriptionTypesOverlap(Attribute.Type, AllRefsType) Then
				ObjectDetails.AddressingAttributes.Insert(Attribute.Name);
			EndIf;
		EndDo;
	EndIf;
	
	ObjectDetails.Insert("CanBePosted", Metadata.Documents.Contains(MetadataObject));
	Return ObjectDetails;
EndFunction

// Parameters:
//   Object Of Metadata - Object Of Metadata
// 	
// Returns:
//  Array of Structure:
//   * FieldList - Structure
//   * DimensionStructure - Structure
//   * MasterDimentionList - Structure
//   * RecordSet - InformationRegisterRecordSet
//   * LockSpace - String
//
Function TaskDetails(Val Meta)

	TaskDetails = Undefined;
	If Not Metadata.BusinessProcesses.Contains(Meta) Then
		Return TaskDetails;
	EndIf;
	
	TaskDetails = ObjectDetails(Meta.Task);
	TaskDetails.Insert("LockSpace", Meta.Task.FullName());
	
	Return TaskDetails;

EndFunction

Function RecordKeyDetails(Val MetadataTables)
	
	TableName = MetadataTables.FullName();
	
	// 
	// 
	KeyDetails = ObjectFieldLists(TableName, MetadataTables.Dimensions, "Period, Recorder");
	
	If Metadata.InformationRegisters.Contains(MetadataTables) Then
		RecordSet = InformationRegisters[MetadataTables.Name].CreateRecordSet();
	ElsIf Metadata.AccumulationRegisters.Contains(MetadataTables) Then
		RecordSet = AccumulationRegisters[MetadataTables.Name].CreateRecordSet();
	ElsIf Metadata.AccountingRegisters.Contains(MetadataTables) Then
		RecordSet = AccountingRegisters[MetadataTables.Name].CreateRecordSet();
	ElsIf Metadata.CalculationRegisters.Contains(MetadataTables) Then
		RecordSet = CalculationRegisters[MetadataTables.Name].CreateRecordSet();
	ElsIf Metadata.Sequences.Contains(MetadataTables) Then
		RecordSet = Sequences[MetadataTables.Name].CreateRecordSet();
	Else
		RecordSet = Undefined;
	EndIf;
	
	KeyDetails.Insert("RecordSet", RecordSet);
	KeyDetails.Insert("LockSpace", TableName);
	
	Return KeyDetails;
EndFunction

Function DescriptionTypesOverlap(Val LongDesc1, Val LongDesc2)
	
	For Each Type In LongDesc1.Types() Do
		If LongDesc2.ContainsType(Type) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

// Returns a description by table name or by a set of records.
Function ObjectFieldLists(Val DataSource, Val RegisterDimensionsMetadata, Val ExcludeFields)
	
	LongDesc = New Structure;
	LongDesc.Insert("FieldList",     New Structure);
	LongDesc.Insert("DimensionStructure", New Structure);
	LongDesc.Insert("MasterDimentionList",   New Structure);
	
	ControlType = AllRefsTypeDetails();
	ToExclude = New Structure(ExcludeFields);
	
	DataSourceType = TypeOf(DataSource);
	
	If DataSourceType = Type("String") Then
		// 
		QueryText = "SELECT * FROM &TableName WHERE FALSE";
		QueryText = StrReplace(QueryText, "&TableName", DataSource);
		Query = New Query(QueryText);
		FieldSource = Query.Execute();
	Else
		// 
		FieldSource = DataSource.UnloadColumns();
	EndIf;
	
	For Each Column In FieldSource.Columns Do
		Name = Column.Name;
		If Not ToExclude.Property(Name) And DescriptionTypesOverlap(Column.ValueType, ControlType) Then
			LongDesc.FieldList.Insert(Name);
			
			// 
			Meta = RegisterDimensionsMetadata.Find(Name);
			If Meta <> Undefined Then
				LongDesc.DimensionStructure.Insert(Name, Meta.Type);
				Test = New Structure("Master", False);
				FillPropertyValues(Test, Meta);
				If Test.Master Then
					LongDesc.MasterDimentionList.Insert(Name, Meta.Type);
				EndIf;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return LongDesc;
EndFunction


Procedure ReplaceInRowCollection(CollectionKind, CollectionName, Object, Collection, Val FieldList, Val ReplacementPairs)
	
	ChangedCollection = Collection.Unload();
	Modified2 = False;
	ModifiedAttributesNames = New Array;
	
	For Each TableRow In ChangedCollection Do
		
		For Each KeyValue In FieldList Do
			AttributeName = KeyValue.Key;
			DestinationRef = ReplacementPairs[ TableRow[AttributeName] ];
			If DestinationRef <> Undefined Then
				RegisterReplacement(Object, TableRow[AttributeName], DestinationRef, CollectionKind, CollectionName, 
					ChangedCollection.IndexOf(TableRow), AttributeName);
				TableRow[AttributeName] = DestinationRef;
				Modified2 = True;
				ModifiedAttributesNames.Add(AttributeName);
			EndIf;
		EndDo;
		
	EndDo;
		
	If Modified2 Then
		IsAccountingRegister = CollectionKind = "RegisterRecords" And IsAccountingRegister(Collection.Metadata());
		If IsAccountingRegister Then
			ImportModifiedSetToAccountingRegister(Collection, ChangedCollection, ModifiedAttributesNames);
		Else	
			Collection.Load(ChangedCollection);
		EndIf;
	EndIf;
EndProcedure

Procedure ImportModifiedSetToAccountingRegister(RecordSet, ChangedCollection, ModifiedAttributesNames)
	NotModifiedDimensions = New Map;
	ChangedDimensions = New Map;
	RegisterMetadata = RecordSet.Metadata();
	
	For Each Dimension In RegisterMetadata.Dimensions Do
		DimensionsNames = New Array;
		
		If Dimension.Balance Or Not RegisterMetadata.Correspondence Then
			DimensionsNames.Add(Dimension.Name);			
		Else	
			DimensionsNames.Add(Dimension.Name + "Dr");
			DimensionsNames.Add(Dimension.Name + "Cr");		
		EndIf;
		
		For Each DimensionName In DimensionsNames Do
			If ModifiedAttributesNames.Find(DimensionName) = Undefined Then
				NotModifiedDimensions.Insert(DimensionName, RecordSet.UnloadColumn(DimensionName));
			Else
				ChangedDimensions.Insert(DimensionName, RecordSet.UnloadColumn(DimensionName));
			EndIf;
		EndDo;
	EndDo;
	
	For Cnt = 0 To RecordSet.Count()-1 Do
	
		For Each ValueDimensionName In ChangedDimensions Do
			If RecordSet[Cnt][ValueDimensionName.Key] = NULL Then
				ValueDimensionName.Value[Cnt] = NULL;
			Else
				ValueDimensionName.Value[Cnt] = ChangedCollection[Cnt][ValueDimensionName.Key];
			EndIf;
		EndDo;
	
	EndDo;
	
	RecordSet.Load(ChangedCollection);
	
	For Each ValueDimensionsInColumn In NotModifiedDimensions Do
		RecordSet.LoadColumn(ValueDimensionsInColumn.Value, ValueDimensionsInColumn.Key);
	EndDo;
	
	For Each ValueDimensionsInColumn In ChangedDimensions Do
		RecordSet.LoadColumn(ValueDimensionsInColumn.Value, ValueDimensionsInColumn.Key);
	EndDo;
EndProcedure

Procedure WriteObjectWithMessageInterception(Val Object, Val Action, Val WriteMode, Val WriteParameters)
	
	// 
	PreviousMessages = GetUserMessages(True);
	ReportAgain    = CurrentRunMode() <> Undefined;
	
	Try
		
		If Action = "Record" Then
			
			Object.DataExchange.Load = Not WriteParameters.IncludeBusinessLogic;
			
			If WriteMode = Undefined Then
				Object.Write();
			Else
				Object.Write(WriteMode);
			EndIf;
			
		ElsIf Action = "DeletionMark" Then
			
			ObjectMetadata = Object.Metadata();
			If IsCatalog(ObjectMetadata)
				Or IsChartOfCharacteristicTypes(ObjectMetadata)
				Or IsChartOfAccounts(ObjectMetadata) Then 
				
				Object.DataExchange.Load = Not WriteParameters.IncludeBusinessLogic;
				Object.SetDeletionMark(True, False);
			ElsIf IsDocument(ObjectMetadata) 
				And ObjectMetadata.Posting = Metadata.ObjectProperties.Posting.Allow Then
				
				Object.SetDeletionMark(True);
			Else
				Object.DataExchange.Load = Not WriteParameters.IncludeBusinessLogic;
				Object.SetDeletionMark(True);
			EndIf;
			
		EndIf;
		
	Except
		MessagesText = "";
		For Each Message In GetUserMessages(False) Do
			MessagesText = MessagesText + Chars.LF + Message.Text;
		EndDo;
		
		If ReportAgain Then
			ReportDeferredMessages(PreviousMessages);
		EndIf;
		
		If MessagesText = "" Then
			Raise;
		EndIf;
		ErrorInfo = ErrorInfo();
		Refinement = CommonClientServer.ExceptionClarification(ErrorInfo);
		Refinement.Text = Refinement.Text + Chars.LF + TrimAll(MessagesText);
		Raise(Refinement.Text, Refinement.Category,,, ErrorInfo);
	EndTry;
	
	If ReportAgain Then
		ReportDeferredMessages(PreviousMessages);
	EndIf;
	
EndProcedure

Procedure ReportDeferredMessages(Val Messages)
	
	For Each Message In Messages Do
		Message.Message();
	EndDo;
	
EndProcedure

Procedure WriteObject(Val Object, Val WriteParameters)
	
	ObjectMetadata = Object.Metadata();
	
	If IsDocument(ObjectMetadata) Then
		WriteObjectWithMessageInterception(Object, "Record", DocumentWriteMode.Write, WriteParameters);
		Return;
	EndIf;
	
	// 
	ObjectProperties = New Structure("Hierarchical, ExtDimensionTypes, Owners", False, Undefined, New Array);
	FillPropertyValues(ObjectProperties, ObjectMetadata);
	
	// 
	If ObjectProperties.Hierarchical Or ObjectProperties.ExtDimensionTypes <> Undefined Then 
		
		If Object.Parent = Object.Ref Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot write ""%1"" because it cannot be its own parent element.';"),
				SubjectString(Object));
			EndIf;
			
	EndIf;
	
	// 
	If ObjectProperties.Owners.Count() > 1 And Object.Owner = Object.Ref Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot write ""%1"" because it cannot own itself.';"),
			SubjectString(Object));
	EndIf;
	
	// 
	If IsSequence(ObjectMetadata)
		And Not AccessRight("Update", ObjectMetadata)
		And Users.IsFullUser(,, False) Then
		
		SetPrivilegedMode(True);
	EndIf;
	
	WriteObjectWithMessageInterception(Object, "Record", Undefined, WriteParameters);
EndProcedure

Function RefReplacementEventLogMessageText()
	
	Return NStr("en = 'Searching for references and deleting them';", DefaultLanguageCode());
	
EndFunction

// Parameters:
//   Result - See TheResultOfReplacingLinks 
//   Ref - AnyRef
//   ErrorDescription - See ReplacementErrorDescription
//
Procedure RegisterReplacementError(Result, Val Ref, Val ErrorDescription)
	
	Result.HasErrors = True;
	
	String = Result.Errors.Add();
	String.Ref = Ref;
	String.ErrorObjectPresentation = ErrorDescription.ErrorObjectPresentation;
	String.ErrorObject               = ErrorDescription.ErrorObject;
	String.ErrorInfo         = ?(TypeOf(ErrorDescription.ErrorInfo) = Type("ErrorInfo"), 
		ErrorDescription.ErrorInfo, Undefined);
	String.ErrorText                = ?(TypeOf(ErrorDescription.ErrorInfo) = Type("ErrorInfo"),
		ErrorProcessing.BriefErrorDescription(ErrorDescription.ErrorInfo), ErrorDescription.ErrorInfo);
	String.ErrorType                  = ErrorDescription.ErrorType;
	
EndProcedure

// Returns:
//   Structure:
//    * ErrorType - String
//    * ErrorObject - AnyRef
//    * ErrorObjectPresentation - String
//    * ErrorInfo - 
//
Function ReplacementErrorDescription(Val ErrorType, Val ErrorObject, Val ErrorObjectPresentation, Val ErrorInfo)

	Result = New Structure;
	Result.Insert("ErrorType",                  ErrorType);
	Result.Insert("ErrorObject",               ErrorObject);
	Result.Insert("ErrorObjectPresentation", ErrorObjectPresentation);
	Result.Insert("ErrorInfo",         ErrorInfo);
	Return Result;

EndFunction

// Returns:
//   Structure:
//     * HasErrors - Boolean
//     * QueueForDirectDeletion - Array
//     * Errors - See Common.ReplaceReferences
//
Function TheResultOfReplacingLinks(Val ReplacementErrors)

	Result = New Structure;
	Result.Insert("HasErrors", False);
	Result.Insert("QueueForDirectDeletion", New Array);
	Result.Insert("Errors", ReplacementErrors);
	Return Result
	
EndFunction

Procedure RegisterErrorInTable(Result, Duplicate1, Original, Data, Information, ErrorType, ErrorInfo)
	Result.HasErrors = True;
	
	WriteLogEvent(RefReplacementEventLogMessageText(),
		EventLogLevel.Error,,,
		ErrorProcessing.DetailErrorDescription(ErrorInfo));
	
	FullDataPresentation = String(Data) + " (" + Information.ItemPresentation + ")";
	
	Error = Result.Errors.Add();
	Error.Ref       = Duplicate1;
	Error.ErrorObject = Data;
	Error.ErrorObjectPresentation = FullDataPresentation;
	
	If ErrorType = "LockForRegister" Then
		NewTemplate = NStr("en = 'Cannot start editing %1: %2';");
		Error.ErrorType = "LockError";
	ElsIf ErrorType = "DataLockForDuplicateDeletion" Then
		NewTemplate = NStr("en = 'Cannot start deletion: %2';");
		Error.ErrorType = "LockError";
	ElsIf ErrorType = "DeleteDuplicateSet" Then
		NewTemplate = NStr("en = 'Cannot clear duplicate''s details in %1: %2';");
		Error.ErrorType = "WritingError";
	ElsIf ErrorType = "WriteOriginalSet" Then
		NewTemplate = NStr("en = 'Cannot update information in %1: %2';");
		Error.ErrorType = "WritingError";
	Else
		NewTemplate = ErrorType + " (%1): %2";
		Error.ErrorType = ErrorType;
	EndIf;
	
	NewTemplate = NewTemplate + Chars.LF + Chars.LF + NStr("en = 'See the Event log for details.';");
	
	BriefPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	Error.ErrorText = StringFunctionsClientServer.SubstituteParametersToString(NewTemplate, FullDataPresentation, BriefPresentation);
	
EndProcedure

// Generates information about the type of metadata object: full name, views, view, and so on.
Function TypeInformation(FullNameOrMetadataOrType, Cache)
	FirstParameterType = TypeOf(FullNameOrMetadataOrType);
	If FirstParameterType = Type("String") Then
		MetadataObject = MetadataObjectByFullName(FullNameOrMetadataOrType);
	Else
		If FirstParameterType = Type("Type") Then // 
			MetadataObject = Metadata.FindByType(FullNameOrMetadataOrType);
		Else
			MetadataObject = FullNameOrMetadataOrType;
		EndIf;
	EndIf;
	FullName = Upper(MetadataObject.FullName());
	
	TypesInformation = CommonClientServer.StructureProperty(Cache, "TypesInformation");
	If TypesInformation = Undefined Then
		TypesInformation = New Map;
		Cache.Insert("TypesInformation", TypesInformation);
	Else
		Information = TypesInformation.Get(FullName);
		If Information <> Undefined Then
			Return Information;
		EndIf;
	EndIf;
	
	Information = New Structure("FullName, ItemPresentation, 
	|Kind, Referential, Technical, Separated1,
	|Hierarchical,
	|HasSubordinateItems, SubordinatesNames,
	|Dimensions, Attributes, Resources");
	TypesInformation.Insert(FullName, Information);
	
	// 
	Information.FullName = FullName;
	
	// 
	Information.ItemPresentation = ObjectPresentation(MetadataObject);
	
	// 
	Information.Kind = Left(Information.FullName, StrFind(Information.FullName, ".")-1);
	If Information.Kind = "CATALOG"
		Or Information.Kind = "DOCUMENT"
		Or Information.Kind = "ENUM"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or Information.Kind = "CHARTOFACCOUNTS"
		Or Information.Kind = "CHARTOFCALCULATIONTYPES"
		Or Information.Kind = "BUSINESSPROCESS"
		Or Information.Kind = "TASK"
		Or Information.Kind = "EXCHANGEPLAN" Then
		Information.Referential = True;
	Else
		Information.Referential = False;
	EndIf;
	
	If Information.Kind = "CATALOG"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES" Then
		Information.Hierarchical = MetadataObject.Hierarchical;
	ElsIf Information.Kind = "CHARTOFACCOUNTS" Then
		Information.Hierarchical = True;
	Else
		Information.Hierarchical = False;
	EndIf;
	
	Information.HasSubordinateItems = False;
	If Information.Kind = "CATALOG"
		Or Information.Kind = "CHARTOFCHARACTERISTICTYPES"
		Or Information.Kind = "EXCHANGEPLAN"
		Or Information.Kind = "CHARTOFACCOUNTS"
		Or Information.Kind = "CHARTOFCALCULATIONTYPES" Then
		For Each Catalog In Metadata.Catalogs Do
			If Catalog.Owners.Contains(MetadataObject) Then
				If Information.HasSubordinateItems = False Then
					Information.HasSubordinateItems = True;
					Information.SubordinatesNames = New Array;
				EndIf;
				SubordinatesNames = Information.SubordinatesNames;  // Array - 
				SubordinatesNames.Add(Catalog.FullName());
			EndIf;
		EndDo;
	EndIf;
	
	If Information.FullName = "CATALOG.METADATAOBJECTIDS"
		Or Information.FullName = "CATALOG.PREDEFINEDREPORTSOPTIONS" Then
		Information.Technical = True;
		Information.Separated1 = False;
	Else
		Information.Technical = False;
		If Not Cache.Property("SaaSModel") Then
			Cache.Insert("SaaSModel", DataSeparationEnabled());
			If Cache.SaaSModel Then
				
				If SubsystemExists("CloudTechnology.Core") Then
					ModuleSaaSOperations = CommonModule("SaaSOperations");
					MainDataSeparator = ModuleSaaSOperations.MainDataSeparator();
					AuxiliaryDataSeparator = ModuleSaaSOperations.AuxiliaryDataSeparator();
				Else
					MainDataSeparator = Undefined;
					AuxiliaryDataSeparator = Undefined;
				EndIf;
				
				Cache.Insert("InDataArea", DataSeparationEnabled() And SeparatedDataUsageAvailable());
				Cache.Insert("MainDataSeparator",        MainDataSeparator);
				Cache.Insert("AuxiliaryDataSeparator", AuxiliaryDataSeparator);
			EndIf;
		EndIf;
		If Cache.SaaSModel Then
			If SubsystemExists("CloudTechnology.Core") Then
				ModuleSaaSOperations = CommonModule("SaaSOperations");
				IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(MetadataObject);
			Else
				IsSeparatedMetadataObject = True;
			EndIf;
			Information.Separated1 = IsSeparatedMetadataObject;
		EndIf;
	EndIf;
	
	Information.Dimensions = New Structure;
	Information.Attributes = New Structure;
	Information.Resources = New Structure;
	
	AttributesKinds = New Structure("StandardAttributes, Attributes, Dimensions, Resources");
	FillPropertyValues(AttributesKinds, MetadataObject);
	For Each KeyAndValue In AttributesKinds Do
		Collection = KeyAndValue.Value; // MetadataObjectCollection
		If TypeOf(Collection) = Type("MetadataObjectCollection") Then
			WhereToWrite = ?(Information.Property(KeyAndValue.Key), Information[KeyAndValue.Key], Information.Attributes);
			For Each Attribute In Collection Do
				WhereToWrite.Insert(Attribute.Name, AttributeInformation1(Attribute));
			EndDo;
		EndIf;
	EndDo;
	If Information.Kind = "INFORMATIONREGISTER"
		And MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
		AttributeInformation1 = New Structure("Master, Presentation, Format, Type, DefaultValue, FillFromFillingValue");
		AttributeInformation1.Master = False;
		AttributeInformation1.FillFromFillingValue = False;
		If MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
			AttributeInformation1.Type = New TypeDescription("PointInTime");
		ElsIf MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.Second Then
			AttributeInformation1.Type = New TypeDescription("Date", , , New DateQualifiers(DateFractions.DateTime));
		Else
			AttributeInformation1.Type = New TypeDescription("Date", , , New DateQualifiers(DateFractions.Date));
		EndIf;
		Information.Dimensions.Insert("Period", AttributeInformation1);
	EndIf;
	
	Return Information;
EndFunction

// Parameters:
//   AttributeMetadata - MetadataObjectAttribute
// 
Function AttributeInformation1(AttributeMetadata)
	// 
	// 
	// 
	// 
	Information = New Structure("Master, Presentation, Format, Type, DefaultValue, FillFromFillingValue");
	FillPropertyValues(Information, AttributeMetadata);
	Information.Presentation = AttributeMetadata.Presentation();
	If Information.FillFromFillingValue = True Then
		Information.DefaultValue = AttributeMetadata.FillValue;
	Else
		Information.DefaultValue = AttributeMetadata.Type.AdjustValue();
	EndIf;
	Return Information;
EndFunction

Procedure AddToReferenceReplacementStatistics(Statistics, Duplicate1, HasErrors)

	DuplicateKey = Duplicate1.Metadata().FullName();
	StatisticsItem = Statistics[DuplicateKey];
	If StatisticsItem = Undefined Then
	     StatisticsItem = New Structure("ItemCount, ErrorsCount",0,0);
		 Statistics.Insert(DuplicateKey, StatisticsItem);
	 EndIf;
	 
	 StatisticsItem.ItemCount = StatisticsItem.ItemCount + 1;
	 StatisticsItem.ErrorsCount = StatisticsItem.ErrorsCount + ?(HasErrors, 1,0);

EndProcedure

Procedure SendReferenceReplacementStatistics(Statistics)

	If Not SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		Return;
	EndIf;	
	
	ModuleMonitoringCenter = CommonModule("MonitoringCenter");
	For Each StatisticsItem In Statistics Do
		ModuleMonitoringCenter.WriteBusinessStatisticsOperation(
			"Core.ReferenceReplacement." + StatisticsItem.Key, StatisticsItem.Value.ItemCount);
		ModuleMonitoringCenter.WriteBusinessStatisticsOperation(
			"Core.ReferenceReplacementErrorsCount." + StatisticsItem.Key, StatisticsItem.Value.ErrorsCount);
	EndDo;

EndProcedure

Procedure SupplementSubordinateObjectsRefSearchExceptions(Val RefSearchExclusions)
	
	For Each SubordinateObjectDetails In SubordinateObjects() Do
		
		LinkFields = StringFunctionsClientServer.SplitStringIntoSubstringsArray(
			SubordinateObjectDetails.LinksFields, ",",, True);
		ValueRefSearchExceptions = New Array;
		For Each LinksField In LinkFields Do
			ValueRefSearchExceptions.Add(LinksField);
		EndDo;
		RefSearchExclusions.Insert(SubordinateObjectDetails.SubordinateObject, ValueRefSearchExceptions);
		
	EndDo;

EndProcedure

Procedure RegisterDeletionErrors(Result, ObjectsPreventingDeletion)

	RefsPresentations = SubjectAsString(ObjectsPreventingDeletion.UnloadColumn("UsageInstance1"));	
	For Each ObjectsPreventingDeletion In ObjectsPreventingDeletion Do
		ErrorText = NStr("en = 'An item is not deleted since there are references to it.';");
		ErrorDescription = ReplacementErrorDescription("DeletionError", ObjectsPreventingDeletion.UsageInstance1, 
			RefsPresentations[ObjectsPreventingDeletion.UsageInstance1], ErrorText);
		RegisterReplacementError(Result, ObjectsPreventingDeletion.ItemToDeleteRef, ErrorDescription);
	EndDo;

EndProcedure

Function GenerateDuplicates(ExecutionParameters, ReplacementParameters, ReplacementPairs, Result)
	
	Duplicates = New Array;
	For Each KeyValue In ReplacementPairs Do
		Duplicate1 = KeyValue.Key;
		Original = KeyValue.Value;
		If Duplicate1 = Original Or Duplicate1.IsEmpty() Then
			Continue; // 
		EndIf;
		Duplicates.Add(Duplicate1);
		// 
		OriginalOriginal = ReplacementPairs[Original];
		HasOriginalOriginal = (OriginalOriginal <> Undefined And OriginalOriginal <> Duplicate1 And OriginalOriginal <> Original);
		If HasOriginalOriginal Then
			While HasOriginalOriginal Do
				Original = OriginalOriginal;
				OriginalOriginal = ReplacementPairs[Original];
				HasOriginalOriginal = (OriginalOriginal <> Undefined And OriginalOriginal <> Duplicate1 And OriginalOriginal <> Original);
			EndDo;
			ReplacementPairs.Insert(Duplicate1, Original);
		EndIf;
	EndDo;
	
	If ExecutionParameters.TakeAppliedRulesIntoAccount And SubsystemExists("StandardSubsystems.DuplicateObjectsDetection") Then
		ModuleDuplicateObjectsDetection = CommonModule("DuplicateObjectsDetection");
		Errors = ModuleDuplicateObjectsDetection.CheckCanReplaceItems(ReplacementPairs, ReplacementParameters);
		
		ObjectsOriginals = New Array;
		For Each KeyValue In Errors Do
			Duplicate1 = KeyValue.Key;
			ObjectsOriginals.Add(ReplacementPairs[Duplicate1]);

			IndexOf = Duplicates.Find(Duplicate1);
			If IndexOf <> Undefined Then
				Duplicates.Delete(IndexOf); // 
			EndIf;
		EndDo;
		
		ObjectsPresentations = SubjectAsString(ObjectsOriginals);
		For Each KeyValue In Errors Do
			Duplicate1 = KeyValue.Key;
			Original = ReplacementPairs[Duplicate1];
			ErrorText = KeyValue.Value;
			Cause = ReplacementErrorDescription("WritingError", Original, ObjectsPresentations[Original], ErrorText);
			RegisterReplacementError(Result, Duplicate1, Cause);
		EndDo;
	EndIf;
	Return Duplicates;

EndFunction

Function NewReferenceReplacementExecutionParameters(Val ReplacementParameters)
	
	DefaultParameters = RefsReplacementParameters();
	ExecutionParameters = New Structure;
	ExecutionParameters.Insert("ShouldDeleteDirectly",     DefaultParameters.DeletionMethod = "Directly");
	ExecutionParameters.Insert("MarkForDeletion",         DefaultParameters.DeletionMethod = "Check");
	ExecutionParameters.Insert("IncludeBusinessLogic",       DefaultParameters.IncludeBusinessLogic);
	ExecutionParameters.Insert("WriteInPrivilegedMode",    DefaultParameters.WriteInPrivilegedMode);
	ExecutionParameters.Insert("TakeAppliedRulesIntoAccount", DefaultParameters.TakeAppliedRulesIntoAccount);
	ExecutionParameters.Insert("ReplacementLocations", New Array);
	
	// 
	ParameterValue = CommonClientServer.StructureProperty(ReplacementParameters, "DeletionMethod");
	If ParameterValue = "Directly" Then
		ExecutionParameters.ShouldDeleteDirectly = True;
		ExecutionParameters.MarkForDeletion     = False;
	ElsIf ParameterValue = "Check" Then
		ExecutionParameters.ShouldDeleteDirectly = False;
		ExecutionParameters.MarkForDeletion     = True;
	EndIf;
	
	ParameterValue = CommonClientServer.StructureProperty(ReplacementParameters, "IncludeBusinessLogic");
	If TypeOf(ParameterValue) = Type("Boolean") Then
		ExecutionParameters.IncludeBusinessLogic = ParameterValue;
	EndIf;
	
	ParameterValue = CommonClientServer.StructureProperty(ReplacementParameters, "WriteInPrivilegedMode");
	If TypeOf(ParameterValue) = Type("Boolean") Then
		ExecutionParameters.WriteInPrivilegedMode = ParameterValue;
	EndIf;
	
	ParameterValue = CommonClientServer.StructureProperty(ReplacementParameters, "TakeAppliedRulesIntoAccount");
	If TypeOf(ParameterValue) = Type("Boolean") Then
		ExecutionParameters.TakeAppliedRulesIntoAccount = ParameterValue;
	EndIf;
	
	ParameterValue =  CommonClientServer.StructureProperty(ReplacementParameters, "ReplacementLocations", New Array);
	If (ParameterValue.Count() > 0) Then
		ExecutionParameters.ReplacementLocations = New Array(New FixedArray(ParameterValue));
	EndIf;
	
	Return ExecutionParameters;
EndFunction

#EndRegion

#Region UsageInstances

Function RecordKeysTypeDetails()
	
	AddedTypes = New Array;
	For Each Meta In Metadata.InformationRegisters Do
		AddedTypes.Add(Type("InformationRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.AccumulationRegisters Do
		AddedTypes.Add(Type("AccumulationRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.AccountingRegisters Do
		AddedTypes.Add(Type("AccountingRegisterRecordKey." + Meta.Name));
	EndDo;
	For Each Meta In Metadata.CalculationRegisters Do
		AddedTypes.Add(Type("CalculationRegisterRecordKey." + Meta.Name));
	EndDo;
	
	Return New TypeDescription(AddedTypes); 
EndFunction

Function RecordSetDimensionsDetails(Val RegisterMetadata, RegisterDimensionCache)
	
	DimensionsDetails = RegisterDimensionCache[RegisterMetadata];
	If DimensionsDetails <> Undefined Then
		Return DimensionsDetails;
	EndIf;
	
	// 
	DimensionsDetails = New Structure;
	
	DimensionData = New Structure("Master, Presentation, Format, Type", False);
	
	If Metadata.InformationRegisters.Contains(RegisterMetadata) Then
		// 
		MetaPeriod = RegisterMetadata.InformationRegisterPeriodicity; 
		Periodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity;
		
		If MetaPeriod = Periodicity.RecorderPosition Then
			DimensionData.Type           = Documents.AllRefsType();
			DimensionData.Presentation = NStr("en = 'Recorder';");
			DimensionData.Master       = True;
			DimensionsDetails.Insert("Recorder", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Year Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("en = 'Period';");
			DimensionData.Format        = NStr("en = 'DF=''yyyy''; DE=''No date''';");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Day Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("en = 'Period';");
			DimensionData.Format        = NStr("en = 'DLF=D; DE=''No date''';");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Quarter Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("en = 'Period';");
			DimensionData.Format        =  NStr("en = 'DF=''""""Q""""q yyyy''; DE=''No date''';");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Month Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("en = 'Period';");
			DimensionData.Format        = NStr("en = 'DF=''MMMM yyyy''; DE=''No date''';");
			DimensionsDetails.Insert("Period", DimensionData);
			
		ElsIf MetaPeriod = Periodicity.Second Then
			DimensionData.Type           = New TypeDescription("Date");
			DimensionData.Presentation = NStr("en = 'Period';");
			DimensionData.Format        = NStr("en = 'DLF=DT; DE=''No date''';");
			DimensionsDetails.Insert("Period", DimensionData);
			
		EndIf;
		
	Else
		DimensionData.Type           = Documents.AllRefsType();
		DimensionData.Presentation = NStr("en = 'Recorder';");
		DimensionData.Master       = True;
		DimensionsDetails.Insert("Recorder", DimensionData);
		
	EndIf;
	
	// 
	For Each MetaDimension In RegisterMetadata.Dimensions Do
		DimensionData = New Structure("Master, Presentation, Format, Type");
		DimensionData.Type           = MetaDimension.Type;
		DimensionData.Presentation = MetaDimension.Presentation();
		DimensionData.Master       = MetaDimension.Master;
		DimensionsDetails.Insert(MetaDimension.Name, DimensionData);
	EndDo;
	
	RegisterDimensionCache[RegisterMetadata] = DimensionsDetails;
	Return DimensionsDetails;
	
EndFunction

#EndRegion

#EndRegion

#Region ConditionCalls

// Returns the backend module Manager by the name of the object.
Function ServerManagerModule(Name)
	ObjectFound = False;
	
	NameParts = StrSplit(Name, ".");
	If NameParts.Count() = 2 Then
		
		KindName = Upper(NameParts[0]);
		ObjectName = NameParts[1];
		
		If KindName = Upper("Constants") Then
			If Metadata.Constants.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("InformationRegisters") Then
			If Metadata.InformationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccumulationRegisters") Then
			If Metadata.AccumulationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("AccountingRegisters") Then
			If Metadata.AccountingRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("CalculationRegisters") Then
			If Metadata.CalculationRegisters.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Catalogs") Then
			If Metadata.Catalogs.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Documents") Then
			If Metadata.Documents.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Reports") Then
			If Metadata.Reports.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DataProcessors") Then
			If Metadata.DataProcessors.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("BusinessProcesses") Then
			If Metadata.BusinessProcesses.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("DocumentJournals") Then
			If Metadata.DocumentJournals.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("Tasks") Then
			If Metadata.Tasks.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfAccounts") Then
			If Metadata.ChartsOfAccounts.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ExchangePlans") Then
			If Metadata.ExchangePlans.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCharacteristicTypes") Then
			If Metadata.ChartsOfCharacteristicTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		ElsIf KindName = Upper("ChartsOfCalculationTypes") Then
			If Metadata.ChartsOfCalculationTypes.Find(ObjectName) <> Undefined Then
				ObjectFound = True;
			EndIf;
		EndIf;
		
	EndIf;
	
	If Not ObjectFound Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid value of parameter ""%1"" in function ""%2"". Metadata object doesn''t exist: ""%3"".';"), 
			"Name", "Common.ServerManagerModule", Name),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	// 
	SetSafeMode(True);
	Module = Eval(Name);
	// 
	
	Return Module;
EndFunction

#EndRegion

#Region Data

Function ColumnsToCompare(Val RowsCollection, Val ColumnsNames, Val ExcludingColumns)
	
	If IsBlankString(ColumnsNames) Then
		
		CollectionType = TypeOf(RowsCollection);
		IsValueList = (CollectionType = Type("ValueList"));
		IsValueTable = (CollectionType = Type("ValueTable"));
		IsKeyAndValueCollection = (CollectionType = Type("Map"))
			Or (CollectionType = Type("Structure"))
			Or (CollectionType = Type("FixedMap"))
			Or (CollectionType = Type("FixedStructure"));
		
		ColumnsToCompare = New Array;
		If IsValueTable Then
			For Each Column In RowsCollection.Columns Do
				ColumnsToCompare.Add(Column.Name);
			EndDo;
		ElsIf IsValueList Then
			ColumnsToCompare.Add("Value");
			ColumnsToCompare.Add("Picture");
			ColumnsToCompare.Add("Check");
			ColumnsToCompare.Add("Presentation");
		ElsIf IsKeyAndValueCollection Then
			ColumnsToCompare.Add("Key");
			ColumnsToCompare.Add("Value");
		Else	
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid value of parameter ""%1"" (of ""%2"" type) in ""%3"". Specify the names of the fields for comparison.';"),
				"RowsCollection1", CollectionType, "Common.IdenticalCollections"),
				ErrorCategory.ConfigurationError);
		EndIf;
	Else
		ColumnsToCompare = StrSplit(StrReplace(ColumnsNames, " ", ""), ",");
	EndIf;
	
	// 
	If Not IsBlankString(ExcludingColumns) Then
		ExcludingColumns = StrSplit(StrReplace(ExcludingColumns, " ", ""), ",");
		ColumnsToCompare = CommonClientServer.ArraysDifference(ColumnsToCompare, ExcludingColumns);
	EndIf;	
	Return ColumnsToCompare;

EndFunction

Function SequenceSensitiveToCompare(Val RowsCollection1, Val RowsCollection2, Val ColumnsToCompare)
	
	CollectionType = TypeOf(RowsCollection1);
	ArraysCompared = (CollectionType = Type("Array") Or CollectionType = Type("FixedArray"));
	
	// 
	Collection1RowNumber = 0;
	For Each CollectionRow1 In RowsCollection1 Do
		// 
		Collection2RowNumber = 0;
		HasCollection2Rows = False;
		For Each CollectionRow2 In RowsCollection2 Do
			HasCollection2Rows = True;
			If Collection2RowNumber = Collection1RowNumber Then
				Break;
			EndIf;
			Collection2RowNumber = Collection2RowNumber + 1;
		EndDo;
		If Not HasCollection2Rows Then
			// 
			Return False;
		EndIf;
		// 
		If ArraysCompared Then
			If CollectionRow1 <> CollectionRow2 Then
				Return False;
			EndIf;
		Else
			For Each ColumnName In ColumnsToCompare Do
				If CollectionRow1[ColumnName] <> CollectionRow2[ColumnName] Then
					Return False;
				EndIf;
			EndDo;
		EndIf;
		Collection1RowNumber = Collection1RowNumber + 1;
	EndDo;
	
	Collection1RowCount = Collection1RowNumber;
	
	// 
	Collection2RowCount = 0;
	For Each CollectionRow2 In RowsCollection2 Do
		Collection2RowCount = Collection2RowCount + 1;
	EndDo;
	
	//  
	// 
	If Collection1RowCount = 0 Then
		For Each CollectionRow2 In RowsCollection2 Do
			Return False;
		EndDo;
		Collection2RowCount = 0;
	EndIf;
	
	// 
	If Collection1RowCount <> Collection2RowCount Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

Function SequenceIgnoreSensitiveToCompare(Val RowsCollection1, Val RowsCollection2, Val ColumnsToCompare)
	
	// 
	//  
	//  
	
	FilterRows = New ValueTable;
	FilterParameters = New Structure;
	For Each ColumnName In ColumnsToCompare Do
		FilterRows.Columns.Add(ColumnName);
		FilterParameters.Insert(ColumnName);
	EndDo;
	
	HasCollection1Rows = False;
	For Each FIlterRow In RowsCollection1 Do
		
		FillPropertyValues(FilterParameters, FIlterRow);
		If FilterRows.FindRows(FilterParameters).Count() > 0 Then
			// 
			Continue;
		EndIf;
		FillPropertyValues(FilterRows.Add(), FIlterRow);
		
		// 
		Collection1RowsFound = 0;
		For Each CollectionRow1 In RowsCollection1 Do
			RowFits = True;
			For Each ColumnName In ColumnsToCompare Do
				If CollectionRow1[ColumnName] <> FIlterRow[ColumnName] Then
					RowFits = False;
					Break;
				EndIf;
			EndDo;
			If RowFits Then
				Collection1RowsFound = Collection1RowsFound + 1;
			EndIf;
		EndDo;
		
		// 
		Collection2RowsFound = 0;
		For Each CollectionRow2 In RowsCollection2 Do
			RowFits = True;
			For Each ColumnName In ColumnsToCompare Do
				If CollectionRow2[ColumnName] <> FIlterRow[ColumnName] Then
					RowFits = False;
					Break;
				EndIf;
			EndDo;
			If RowFits Then
				Collection2RowsFound = Collection2RowsFound + 1;
				//  
				// 
				If Collection2RowsFound > Collection1RowsFound Then
					Return False;
				EndIf;
			EndIf;
		EndDo;
		
		// 
		If Collection1RowsFound <> Collection2RowsFound Then
			Return False;
		EndIf;
		
		HasCollection1Rows = True;
		
	EndDo;
	
	//  
	// 
	If Not HasCollection1Rows Then
		For Each CollectionRow2 In RowsCollection2 Do
			Return False;
		EndDo;
	EndIf;
	
	// 
	For Each CollectionRow2 In RowsCollection2 Do
		FillPropertyValues(FilterParameters, CollectionRow2);
		If FilterRows.FindRows(FilterParameters).Count() = 0 Then
			Return False;
		EndIf;
	EndDo;
	Return True;
	
EndFunction		

Function CompareArrays(Val Array1, Val Array2)
	
	If Array1.Count() <> Array2.Count() Then
		Return False;
	EndIf;
	
	For Each Item In Array1 Do
		If Array2.Find(Item) = Undefined Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction		

Procedure CheckFixedData(Data, DataInFixedTypeValue = False)
	
	DataType = TypeOf(Data);
	TypesComposition = New TypeDescription(
		"ValueStorage,
		|FixedArray,
		|FixedStructure,
		|FixedMap");
	
	If TypesComposition.ContainsType(DataType) Then
		Return;
	EndIf;
	
	If DataInFixedTypeValue Then
		
	TypesComposition = New TypeDescription(
		"Boolean,String,Number,Date,
		|Undefined,UUID,Null,Type,
		|ErrorReportingMode,
		|ValueStorage,CommonModule,MetadataObject,
		|XDTOValueType,XDTOObjectType,
		|CollaborationSystemConversationID");
		
		If TypesComposition.ContainsType(DataType)
		 Or IsReference(DataType) Then
			
			Return;
		EndIf;
	EndIf;
	
	Raise(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invalid value of parameter ""%1"" in function ""%2"". Data of type ""%3"" cannot be immutable.';"),
		"Data", "Common.FixedData", String(DataType)),
		ErrorCategory.ConfigurationError);
	
EndProcedure

Function StringSizeInBytes(Val String)
	
	Return GetBinaryDataFromString(String, "UTF-8").Size();

EndFunction

#Region CopyRecursive

Function CopyStructure(SourceStructure, FixData)
	
	ResultingStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultingStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceStructure) = Type("FixedStructure") Then 
		
		Return New FixedStructure(ResultingStructure);
	EndIf;
	
	Return ResultingStructure;
	
EndFunction

Function CopyMap(SourceMap, FixData)
	
	ResultingMap = New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultingMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceMap) = Type("FixedMap") Then 
		Return New FixedMap(ResultingMap);
	EndIf;
	
	Return ResultingMap;
	
EndFunction

Function CopyArray(SourceArray1, FixData)
	
	ResultingArray = New Array;
	
	For Each Item In SourceArray1 Do
		ResultingArray.Add(CopyRecursive(Item, FixData));
	EndDo;
	
	If FixData = True 
		Or FixData = Undefined
		And TypeOf(SourceArray1) = Type("FixedArray") Then 
		Return New FixedArray(ResultingArray);
	EndIf;
	
	Return ResultingArray;
	
EndFunction

Function CopyValueList(SourceList, FixData)
	
	ResultingList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultingList.Add(
			CopyRecursive(ListItem.Value, FixData), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultingList;
	
EndFunction

Procedure CopyValuesFromValTable(ValueTable, FixData)
	For Each ValueTableRow In ValueTable Do
		For Each Column In ValueTable.Columns Do
			ValueTableRow[Column.Name] = CopyRecursive(ValueTableRow[Column.Name], FixData);
		EndDo;
	EndDo;
EndProcedure

Procedure CopyValuesFromValTreeRow(ValTreeRows, FixData);
	For Each ValueTreeRow In ValTreeRows Do
		For Each Column In ValueTreeRow.Owner().Columns Do
			ValueTreeRow[Column.Name] = CopyRecursive(ValueTreeRow[Column.Name], FixData);
		EndDo;
		CopyValuesFromValTreeRow(ValueTreeRow.Rows, FixData);
	EndDo;
EndProcedure

#EndRegion

#EndRegion

#Region Metadata

Procedure CheckMetadataObjectExists(FullName)
	
	If MetadataObjectByFullName(FullName) = Undefined Then 
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Non-existing metadata object type: ""%1"".';"), FullName),
			ErrorCategory.ConfigurationError);
	EndIf;
	
EndProcedure

#EndRegion

#Region SettingsStorage

Procedure StorageSave(StorageManager, ObjectKey, SettingsKey, Settings,
			SettingsDescription, UserName, RefreshReusableValues)
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	StorageManager.Save(ObjectKey, SettingsKey(SettingsKey), Settings,
		SettingsDescription, UserName);
	
	If RefreshReusableValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

Function StorageLoad(StorageManager, ObjectKey, SettingsKey, DefaultValue,
			SettingsDescription, UserName)
	
	Result = Undefined;
	
	If AccessRight("SaveUserData", Metadata) Then
		Result = StorageManager.Load(ObjectKey, SettingsKey(SettingsKey),
			SettingsDescription, UserName);
	EndIf;
	
	If Result = Undefined Then
		Result = DefaultValue;
	Else
		SetPrivilegedMode(True);
		If ClearNonExistentRefs(Result) Then
			Result = DefaultValue;
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

// Deletes links from the passed collection that refer to non-existent data in the information database.
// Does not clear the passed value if a nonexistent reference is passed in it, but returns False. 
//
// Parameters:
//   Value - AnyRef
//            - Arbitrary - 
//
// Returns: 
//   Boolean - 
//            
//
Function ClearNonExistentRefs(Value)
	
	Type = TypeOf(Value);
	If Type = Type("Undefined")
		Or Type = Type("Boolean")
		Or Type = Type("String")
		Or Type = Type("Number")
		Or Type = Type("Date") Then // 
		
		Return False; // 
		
	ElsIf Type = Type("Array") Then
		
		Count = Value.Count();
		For Number = 1 To Count Do
			ReverseIndex = Count - Number;
			// 
			If ClearNonExistentRefs(Value[ReverseIndex]) Then
				Value.Delete(ReverseIndex);
			EndIf;
		EndDo;
		
		Return False; // 
		
	ElsIf Type = Type("Structure")
		Or Type = Type("Map") Then
		
		For Each KeyAndValue In Value Do
			// 
			If ClearNonExistentRefs(KeyAndValue.Value) Then
				Value.Insert(KeyAndValue.Key, Undefined);
			EndIf;
		EndDo;
		
		Return False; // 
		
	ElsIf Documents.AllRefsType().ContainsType(Type)
		Or Catalogs.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type) Then
		// 
		
		If Value.IsEmpty() Then
			Return False; // 
		EndIf;
		Return ObjectAttributeValue(Value, "Ref") = Undefined;
		
	Else
		Return False; // 
	EndIf;
	
EndFunction

Procedure StorageDelete(StorageManager, ObjectKey, SettingsKey, UserName)
	
	If AccessRight("SaveUserData", Metadata) Then
		StorageManager.Delete(ObjectKey, SettingsKey(SettingsKey), UserName);
	EndIf;
	
EndProcedure

// Returns a string of the settings key that does not exceed the allowed length of 128 characters.
// If the specified string exceeds 128, then
// the 32-character MD5 hash sum is added instead of characters over 96 characters.
//
// Parameters:
//  String - String -  a string of any length.
//
// Returns:
//  String - 
//
Function SettingsKey(Val String)
	Return TrimStringUsingChecksum(String, 128);
EndFunction

#EndRegion

#Region SecureStorage

Function DataFromSecureStorage(Owners, Keys, SharedData)
	
	NameOfTheSecureDataStore = "InformationRegister.SafeDataStorage";
	If DataSeparationEnabled() And SeparatedDataUsageAvailable() And SharedData <> True Then
		NameOfTheSecureDataStore = "InformationRegister.SafeDataAreaDataStorage";
	EndIf;
	
	QueryText =
		"SELECT
		|	SafeDataStorage.Owner AS DataOwner,
		|	SafeDataStorage.Data AS Data
		|FROM
		|	#NameOfTheSecureDataStore AS SafeDataStorage
		|WHERE
		|	SafeDataStorage.Owner IN (&Owners)";
	
	QueryText = StrReplace(QueryText, "#NameOfTheSecureDataStore", NameOfTheSecureDataStore);
	Query = New Query(QueryText);
	Query.SetParameter("Owners", Owners);
	QueryResult = Query.Execute().Select();
	
	Result = New Map(); 
	
	KeyDataSet = ?(ValueIsFilled(Keys) And StrFind(Keys, ","), New Structure(Keys), Undefined);
	For Each DataOwner In Owners Do
		Result.Insert(DataOwner, KeyDataSet);
	EndDo;
	
	While QueryResult.Next() Do
		
		OwnerData = New Structure(Keys);
		
		If ValueIsFilled(QueryResult.Data) Then
			
			SavedData = QueryResult.Data.Get();
			If ValueIsFilled(SavedData) Then
				
				If ValueIsFilled(Keys) Then
					DataOwner = Result[QueryResult.DataOwner];
					FillPropertyValues(OwnerData, SavedData);
				Else
					OwnerData = SavedData;
				EndIf;
				
				If Keys <> Undefined
					And OwnerData <> Undefined
					And OwnerData.Count() = 1 Then
						TheValueForTheKey = ?(OwnerData.Property(Keys), OwnerData[Keys], Undefined);
						Result.Insert(QueryResult.DataOwner, TheValueForTheKey);
				Else
					Result.Insert(QueryResult.DataOwner, OwnerData);
				EndIf;
				
			EndIf;
			
		EndIf;
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region ExternalCodeSecureExecution

// Verifies that the passed procedure name is the name of the configuration export procedure.
// It can be used to check that the passed string does not contain an arbitrary algorithm
// in the built-in 1C language:Enterprises, before using it in statements, Execute and Calculate
// the configuration code when using them to dynamically call methods.
//
// If the passed string is not the name of the configuration procedure, an exception is thrown.
//
// It is intended to be called from see the procedure to perform the Configuration method.
//
// Parameters:
//   ProcedureName - String -  name of the export procedure to check.
//
Procedure CheckConfigurationProcedureName(Val ProcedureName)
	
	NameParts = StrSplit(ProcedureName, ".");
	If NameParts.Count() <> 2 And NameParts.Count() <> 3 Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Invalid format of %1 parameter (passed value: ""%2"") in %3.';"), 
			"ProcedureName", ProcedureName, "Common.ExecuteConfigurationMethod"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	ObjectName = NameParts[0];
	If NameParts.Count() = 2 And Metadata.CommonModules.Find(ObjectName) = Undefined Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Incorrect format of parameter %1 (passed value: ""%2"") in %3:
				|Common module ""%4"" does not exist.';"),
			"ProcedureName", ProcedureName, "Common.ExecuteConfigurationMethod", ObjectName),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	If NameParts.Count() = 3 Then
		FullObjectName = NameParts[0] + "." + NameParts[1];
		Try
			Manager = ObjectManagerByName(FullObjectName);
		Except
			Manager = Undefined;
		EndTry;
		If Manager = Undefined Then
			Raise(StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Incorrect format of parameter %1 (passed value: ""%2"") in %3:
				           |Object manager ""%4"" does not exist.';"),
				"ProcedureName", ProcedureName, "Common.ExecuteConfigurationMethod", FullObjectName),
				ErrorCategory.ConfigurationError);
		EndIf;
	EndIf;
	
	ObjectMethodName = NameParts[NameParts.UBound()];
	TempStructure = New Structure;
	Try
		// 
		// 
		TempStructure.Insert(ObjectMethodName);
	Except
		WriteLogEvent(NStr("en = 'Executing method in safe mode';", DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Incorrect format of parameter %1 (passed value: ""%2"") in %3:
			           |Name of method ""%4"" does not meet the requirements of procedure and function name formation.';"),
			"ProcedureName", ProcedureName, "Common.ExecuteConfigurationMethod", ObjectMethodName),
			ErrorCategory.ConfigurationError);
	EndTry;
	
EndProcedure

// Returns the object Manager by name.
// Restriction: business process route points are not processed.
//
// Parameters:
//  Name - String -  name for example, "Directory", "Directories", " Directory.Companies".
//
// Returns:
//  CatalogsManager
//  Referencemanager
//  Documentmanager
//  Document
//  Manager ...
//
Function ObjectManagerByName(Name)
	Var MOClass, MetadataObjectName1, Manager;
	
	NameParts = StrSplit(Name, ".");
	
	If NameParts.Count() > 0 Then
		MOClass = Upper(NameParts[0]);
	EndIf;
	
	If NameParts.Count() > 1 Then
		MetadataObjectName1 = NameParts[1];
	EndIf;
	
	If      MOClass = "EXCHANGEPLAN"
	 Or      MOClass = "EXCHANGEPLANS" Then
		Manager = ExchangePlans;
		
	ElsIf MOClass = "CATALOG"
	      Or MOClass = "CATALOGS" Then
		Manager = Catalogs;
		
	ElsIf MOClass = "DOCUMENT"
	      Or MOClass = "DOCUMENTS" Then
		Manager = Documents;
		
	ElsIf MOClass = "DOCUMENTJOURNAL"
	      Or MOClass = "DOCUMENTJOURNALS" Then
		Manager = DocumentJournals;
		
	ElsIf MOClass = "ENUM"
	      Or MOClass = "ENUMS" Then
		Manager = Enums;
		
	ElsIf MOClass = "CommonModule"
	      Or MOClass = "COMMONMODULES" Then
		
		Return CommonModule(MetadataObjectName1);
		
	ElsIf MOClass = "REPORT"
	      Or MOClass = "REPORTS" Then
		Manager = Reports;
		
	ElsIf MOClass = "DATAPROCESSOR"
	      Or MOClass = "DATAPROCESSORS" Then
		Manager = DataProcessors;
		
	ElsIf MOClass = "CHARTOFCHARACTERISTICTYPES"
	      Or MOClass = "CHARTSOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf MOClass = "CHARTOFACCOUNTS"
	      Or MOClass = "CHARTSOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
		
	ElsIf MOClass = "CHARTOFCALCULATIONTYPES"
	      Or MOClass = "ChartOfCalculationTypes" Then
		Manager = ChartsOfCalculationTypes;
		
	ElsIf MOClass = "INFORMATIONREGISTER"
	      Or MOClass = "INFORMATIONREGISTERS" Then
		Manager = InformationRegisters;
		
	ElsIf MOClass = "ACCUMULATIONREGISTER"
	      Or MOClass = "ACCUMULATIONREGISTERS" Then
		Manager = AccumulationRegisters;
		
	ElsIf MOClass = "ACCOUNTINGREGISTER"
	      Or MOClass = "ACCOUNTINGREGISTERS" Then
		Manager = AccountingRegisters;
		
	ElsIf MOClass = "CALCULATIONREGISTER"
	      Or MOClass = "CALCULATIONREGISTERS" Then
		
		If NameParts.Count() < 3 Then
			// 
			Manager = CalculationRegisters;
		Else
			SubordinateMOClass = Upper(NameParts[2]);
			If NameParts.Count() > 3 Then
				SubordinateMOName = NameParts[3];
			EndIf;
			If SubordinateMOClass = "RECALCULATION"
			 Or SubordinateMOClass = "RECALCULATIONS" Then
				// Recalculation
				Try
					Manager = CalculationRegisters[MetadataObjectName1].Recalculations;
					MetadataObjectName1 = SubordinateMOName;
				Except
					Manager = Undefined;
				EndTry;
			EndIf;
		EndIf;
		
	ElsIf MOClass = "BUSINESSPROCESS"
	      Or MOClass = "BUSINESSPROCESSES" Then
		Manager = BusinessProcesses;
		
	ElsIf MOClass = "TASK"
	      Or MOClass = "TASKS" Then
		Manager = Tasks;
		
	ElsIf MOClass = "CONSTANT"
	      Or MOClass = "CONSTANTS" Then
		Manager = Constants;
		
	ElsIf MOClass = "SEQUENCE"
	      Or MOClass = "SEQUENCES" Then
		Manager = Sequences;
	EndIf;
	
	If Manager <> Undefined Then
		If ValueIsFilled(MetadataObjectName1) Then
			Try
				Return Manager[MetadataObjectName1];
			Except
				Manager = Undefined;
			EndTry;
		Else
			Return Manager;
		EndIf;
	EndIf;
	
	Raise(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invalid value of parameter ""%1"" in ""%2"". Manager for object ""%3"" doesn''t exist.';"), Name),
		"Name", "Common.ObjectManagerByName", ErrorCategory.ConfigurationError);
	
EndFunction

// Call the export function by name with the configuration privilege level.
// When security profiles are enabled, the Run () operator is invoked
// by switching to safe mode with the security profile used for the information base
// (unless a different safe mode was set higher up the stack).
//
// Parameters:
//  MethodName  - String -  name of the export function in the format
//                       <object name>.< procedure name>, where <object name> is
//                       a General module or object Manager module.
//  Parameters  - Array -  parameters are passed to the <Methodname> function
//                        in the order of array elements.
//
// Returns:
//  Arbitrary - 
//
Function CallConfigurationFunction(Val MethodName, Val Parameters = Undefined) Export
	
	CheckConfigurationProcedureName(MethodName);
	
	If SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If ModuleSafeModeManager.UseSecurityProfiles()
			And Not ModuleSafeModeManager.SafeModeSet() Then
			
			InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
			If ValueIsFilled(InfobaseProfile) Then
				
				SetSafeMode(InfobaseProfile);
				If SafeMode() = True Then
					SetSafeMode(False);
				EndIf;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined And Parameters.Count() > 0 Then
		For IndexOf = 0 To Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + XMLString(IndexOf) + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Return Eval(MethodName + "(" + ParametersString + ")"); // 
	
EndFunction

// Call the export function of an embedded language object by name.
// When security profiles are enabled, the Run () operator is invoked
// by switching to safe mode with the security profile used for the information base
// (unless a different safe mode was set higher up the stack).
//
// Parameters:
//  Object    - Arbitrary -  object of the built-in 1C language:An object containing methods (for example, a processing Object).
//  MethodName - String       -  name of the export function of the processing object module.
//  Parameters - Array       -  parameters are passed to the <Methodname> function
//                             in the order of array elements.
//
// Returns:
//  Arbitrary - 
//
Function CallObjectFunction(Val Object, Val MethodName, Val Parameters = Undefined) Export
	
	// 
	Try
		Test = New Structure;
		Test.Insert(MethodName, MethodName);
	Except
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Incorrect value of parameter %1 in %3: %2.';"), 
			"MethodName", MethodName, "Common.ExecuteObjectMethod"),
			ErrorCategory.ConfigurationError);
	EndTry;
	
	If SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		ModuleSafeModeManager = CommonModule("SafeModeManager");
		If ModuleSafeModeManager.UseSecurityProfiles()
			And Not ModuleSafeModeManager.SafeModeSet() Then
			
			ModuleSafeModeManager = CommonModule("SafeModeManager");
			InfobaseProfile = ModuleSafeModeManager.InfobaseSecurityProfile();
			
			If ValueIsFilled(InfobaseProfile) Then
				
				SetSafeMode(InfobaseProfile);
				If SafeMode() = True Then
					SetSafeMode(False);
				EndIf;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	ParametersString = "";
	If Parameters <> Undefined And Parameters.Count() > 0 Then
		For IndexOf = 0 To Parameters.UBound() Do 
			ParametersString = ParametersString + "Parameters[" + XMLString(IndexOf) + "],";
		EndDo;
		ParametersString = Mid(ParametersString, 1, StrLen(ParametersString) - 1);
	EndIf;
	
	Return Eval("Object." + MethodName + "(" + ParametersString + ")"); // 
	
EndFunction

#EndRegion

#Region AddIns

Procedure CheckTheLocationOfTheComponent(Id, Location)
	
	If TemplateExists(Location) Then
		Return;
	EndIf;
	
	If SubsystemExists("StandardSubsystems.AddIns") Then
		ModuleAddInsInternal = CommonModule("AddInsInternal");
		ModuleAddInsInternal.CheckTheLocationOfTheComponent(Id, Location);
		Return;
	EndIf;
	Raise(StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'When attaching an add-in ""%2"", non-existent template ""%1"" is specified.';"),
			Location, Id),
		ErrorCategory.ConfigurationError);
	
EndProcedure

Function TemplateAddInCompatibilityError(Location)
	
	If Not SubsystemExists("StandardSubsystems.AddIns") Then
		Return "";
	EndIf;
	
	ModuleAddInsInternal = CommonModule("AddInsInternal");
	
	Return ModuleAddInsInternal.TemplateAddInCompatibilityError(
		Location);
	
EndFunction

Function SystemInformationForLogging()
	
	SystemInfo = New SystemInfo;
	
	Return Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '1C:Enterprise: %1
		           |Type: %2
		           |OS version: %3
		           |CPU: %4
		           |RAM: %5';",
		           DefaultLanguageCode()),
		SystemInfo.AppVersion,
		SystemInfo.PlatformType,
		SystemInfo.OSVersion,
		SystemInfo.Processor,
		SystemInfo.RAM);
	
EndFunction

#EndRegion

#Region CurrentEnvironment

Function BuildNumberForTheCurrentPlatformVersion(AssemblyNumbersAsAString)
	
	AssemblyNumbers = StrSplit(AssemblyNumbersAsAString, ";", True);
	
	BuildsByVersion = New Map;
	For Each BuildNumber In AssemblyNumbers Do
		VersionNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(BuildNumber);
		BuildsByVersion.Insert(TrimAll(VersionNumber), TrimAll(BuildNumber));
	EndDo;
	
	SystemInfo = New SystemInfo;
	CurrentVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
	
	Result = BuildsByVersion[CurrentVersion];
	If Not ValueIsFilled(Result) Then
		Result = AssemblyNumbers[0];
	EndIf;
	
	Return Result;
	
EndFunction

// 
// 
// 
// 
//
Function MinPlatformVersion() Export // 
	
	CompatibilityModeVersion = CompatibilityModeVersion();
	MinPlatformVersions = StandardSubsystemsServer.Min1CEnterpriseVersionForUse();
	FoundVersion = MinPlatformVersions.FindByValue(CompatibilityModeVersion);
	
	If FoundVersion = Undefined Then
		FoundVersion = MinPlatformVersions[MinPlatformVersions.Count() - 1];
	EndIf;
	
	Return FoundVersion.Presentation;
	
EndFunction

Function CompatibilityModeVersion() Export
	
	SystemInfo = New SystemInfo();
	CompatibilityMode = Metadata.CompatibilityMode;
	
	If CompatibilityMode = Metadata.ObjectProperties.CompatibilityMode.DontUse Then
		CompatibilityModeVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(SystemInfo.AppVersion);
	Else
		CompatibilityModeVersion = StrConcat(StrSplit(CompatibilityMode, 
			StrConcat(StrSplit(CompatibilityMode, "1234567890", False), ""), False), ".");
	EndIf;
	
	Return CompatibilityModeVersion;
	
EndFunction

// 
//
// Parameters:
//  Min - String - 
//  Recommended - String - 
//
// Returns:
//  Boolean - 
//
Function IsMinRecommended1CEnterpriseVersionInvalid(Min, Recommended)
	
	// 
	If IsBlankString(Min) Then
		Return True;
	EndIf;
	
	// 
	// 
	MinimalSSL = BuildNumberForTheCurrentPlatformVersion(MinPlatformVersion());
	If Not IsVersionOfProtectedComplexITSystem(Min)
		And CommonClientServer.CompareVersions(MinimalSSL, Min) > 0 Then
		Return True;
	EndIf;
	
	// 
	Return Not IsBlankString(Min)
		And Not IsBlankString(Recommended)
		And CommonClientServer.CompareVersions(Min, Recommended) > 0;
	
EndFunction

Function InvalidPlatformVersions() Export
	
	Return "";
	
EndFunction

Function IsVersionOfProtectedComplexITSystem(Version)
	
	Versions = StandardSubsystemsServer.SecureSoftwareSystemVersions();
	Return Versions.Find(Version) <> Undefined;
	
EndFunction

// 
Procedure ClarifyPlatformVersion(CommonParameters)
	
	SystemInfo = New SystemInfo;
	NewBuild = StandardSubsystemsServer.ReplacementVersionForRevoked1CEnterprise(SystemInfo.AppVersion);
	If Not ValueIsFilled(NewBuild) Then
		NewRecommendedBuild = StandardSubsystemsServer.ReplacementVersionForRevoked1CEnterprise(CommonParameters.MinPlatformVersion);
		If ValueIsFilled(NewRecommendedBuild) Then
			MinBuild = BuildNumberForTheCurrentPlatformVersion(MinPlatformVersion());
			CommonParameters.MinPlatformVersion = MinBuild;
			CommonParameters.MinPlatformVersion1 = MinBuild;
			If CommonClientServer.CompareVersions(CommonParameters.RecommendedPlatformVersion, NewRecommendedBuild) < 0 Then
				CommonParameters.RecommendedPlatformVersion = NewRecommendedBuild;
			EndIf;
		EndIf;
	ElsIf CommonClientServer.CompareVersions(CommonParameters.MinPlatformVersion, NewBuild) < 0 Then
		CommonParameters.RecommendedPlatformVersion = NewBuild;
		CommonParameters.MinPlatformVersion = NewBuild;
		CommonParameters.MinPlatformVersion1 = NewBuild;
		CommonParameters.MustExit = True;
	EndIf;
	
EndProcedure


#EndRegion

#EndRegion

#EndIf
