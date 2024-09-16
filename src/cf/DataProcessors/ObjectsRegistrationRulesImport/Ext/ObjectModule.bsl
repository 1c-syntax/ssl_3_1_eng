///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var Registration Export; // 
Var ObjectsRegistrationRules Export; // 
Var FlagErrors Export; // 

Var StringType;
Var BooleanType;
Var NumberType;
Var DateType;

Var BlankDateValue1;
Var FilterByExchangePlanPropertiesTreePattern;  // 
                                                // 
Var FilterByObjectPropertiesTreePattern;      // 
Var BooleanRootPropertiesGroupValue; // 
Var ErrorsMessages; // 

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Parses an XML file with registration rules. Fills in collection values based on file data;
// Prepares the read-out rules for the PRO player ("compilation" of rules).
//
// Parameters:
//  FileName         - String -  the full name of the file in the local file system that contains the rules.
//  InformationOnly - Boolean -  a sign that you need to read only the file header and information about the rules;
//                              (the default value is False).
//
Procedure ImportRules(Val FileName, InformationOnly = False) Export
	
	FlagErrors = False;
	
	If IsBlankString(FileName) Then
		ReportProcessingError(4);
		Return;
	EndIf;
	
	// 
	Registration                             = RecordInitialization();
	ObjectsRegistrationRules              = DataProcessors.ObjectsRegistrationRulesImport.ORRTableInitialization();
	FilterByExchangePlanPropertiesTreePattern = DataProcessors.ObjectsRegistrationRulesImport.FilterByExchangePlanPropertiesTableInitialization();
	FilterByObjectPropertiesTreePattern     = DataProcessors.ObjectsRegistrationRulesImport.FilterByObjectPropertiesTableInitialization();
	
	// 
	Try
		LoadRecordFromFile(FileName, InformationOnly);
	Except
		
		// 
		ReportProcessingError(2, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		
	EndTry;
	
	// 
	If FlagErrors Then
		Return;
	EndIf;
	
	If InformationOnly Then
		Return;
	EndIf;
	
	// 
	
	For Each ORR In ObjectsRegistrationRules Do
		
		PrepareRecordRuleByExchangePlanProperties(ORR);
		
		PrepareRegistrationRuleByObjectProperties(ORR);
		
	EndDo;
	
	ObjectsRegistrationRules.FillValues(Registration.ExchangePlanName, "ExchangePlanName");
	
EndProcedure

// Prepares a string with information about rules based on the read data from the XML file.
//
// Returns:
//   String - 
//
Function RulesInformation() Export
	
	// 
	InfoString = "";
	
	If FlagErrors Then
		Return InfoString;
	EndIf;
	
	InfoString = NStr("en = 'Object registration rules in this infobase (%1) created on %2';");
	
	Return StringFunctionsClientServer.SubstituteParametersToString(InfoString,
		GetConfigurationPresentationFromRegistrationRules(),
		Format(Registration.CreationDateTime, "DLF=DD"));
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure LoadRecordFromFile(FileName, InformationOnly)
	
	// 
	Try
		Rules = New XMLReader();
		Rules.OpenFile(FileName);
		Rules.Read();
	Except
		Rules = Undefined;
		ReportProcessingError(1, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return;
	EndTry;
	
	Try
		LoadRecord(Rules, InformationOnly);
	Except
		ReportProcessingError(2, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
	Rules.Close();
	Rules = Undefined;
	
EndProcedure

// Loads the registration rules according to the format.
//
// Parameters:
//  
Procedure LoadRecord(Rules, InformationOnly)
	
	If Not ((Rules.LocalName = "RecordRules") 
		And (Rules.NodeType = XMLNodeType.StartElement)) Then
		
		// 
		ReportProcessingError(3);
		
		Return;
		
	EndIf;
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		NodeType = Rules.NodeType;
		
		// 
		If NodeName = "FormatVersion" Then
			
			Registration.FormatVersion = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "ID" Then
			
			Registration.ID = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "Description" Then
			
			Registration.Description = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "CreationDateTime" Then
			
			Registration.CreationDateTime = deElementValue(Rules, DateType);
			
		ElsIf NodeName = "ExchangePlan" Then
			
			// 
			Registration.ExchangePlanName = deAttribute(Rules, StringType, "Name");
			
			Registration.ExchangePlan = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "Comment" Then
			
			Registration.Comment = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "Configuration" Then
			
			// 
			Registration.PlatformVersion     = deAttribute(Rules, StringType, "PlatformVersion");
			Registration.ConfigurationVersion  = deAttribute(Rules, StringType, "ConfigurationVersion");
			Registration.ConfigurationSynonym = deAttribute(Rules, StringType, "ConfigurationSynonym");
			
			//  the name of the configuration
			Registration.Configuration = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "ObjectsRegistrationRules" Then
			
			If InformationOnly Then
				
				Break; // 
				
			Else
				
				// 
				CheckExchangePlanExists();
				
				If FlagErrors Then
					Break; // 
				EndIf;
				
				ImportRegistrationRules(Rules);
				
			EndIf;
			
		ElsIf (NodeName = "RecordRules") And (NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Loads the registration rules in accordance with the format of the exchange rules.
//
// Parameters:
//  Rules - XMLReader -  an object of the ReadXml type.
//
Procedure ImportRegistrationRules(Rules)
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		
		If NodeName = "Rule" Then
			
			LoadRecordRule(Rules);
			
		ElsIf NodeName = "Group" Then
			
			LoadRecordRuleGroup(Rules);
			
		ElsIf (NodeName = "ObjectsRegistrationRules") And (Rules.NodeType = XMLNodeType.EndElement) Then
			
			Break;
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//   RulesTable - ValueTable -  table of registration rules.
// 
Function NewRegistrationRule(RulesTable)
	
	Return RulesTable.Add();
	
EndFunction

// Performs a download of the rules for registration of objects.
//
// Parameters:
//  Rules  - XMLReader -  an object of the ReadXml type.
//
Procedure LoadRecordRule(Rules)
	
	// 
	Disconnect = deAttribute(Rules, BooleanType, "Disconnect");
	If Disconnect Then
		deSkip(Rules);
		Return;
	EndIf;
	
	// 
	Valid = deAttribute(Rules, BooleanType, "Valid");
	If Not Valid Then
		deSkip(Rules);
		Return;
	EndIf;
	
	NewRow = NewRegistrationRule(ObjectsRegistrationRules);
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		
		If NodeName = "SettingObject1" Then
			
			NewRow.SettingObject1 = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "MetadataObjectName3" Then
			
			NewRow.MetadataObjectName3 = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "ExportModeAttribute" Then
			
			NewRow.FlagAttributeName = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "FilterByExchangePlanProperties" Then
			
			// 
			NewRow.FilterByExchangePlanProperties = FilterByExchangePlanPropertiesTreePattern.Copy();
			
			LoadFilterByExchangePlanPropertiesTree(Rules, NewRow.FilterByExchangePlanProperties);
			
		ElsIf NodeName = "FilterByObjectProperties" Then
			
			// 
			NewRow.FilterByObjectProperties = FilterByObjectPropertiesTreePattern.Copy();
			
			LoadFilterByObjectPropertiesTree(Rules, NewRow.FilterByObjectProperties);
			
		ElsIf NodeName = "BeforeProcess" Then
			
			NewRow.BeforeProcess = deElementValue(Rules, StringType);
			
			NewRow.HasBeforeProcessHandler = Not IsBlankString(NewRow.BeforeProcess);
			
		ElsIf NodeName = "OnProcess" Then
			
			NewRow.OnProcess = deElementValue(Rules, StringType);
			
			NewRow.HasOnProcessHandler = Not IsBlankString(NewRow.OnProcess);
			
		ElsIf NodeName = "OnProcessAdditional" Then
			
			NewRow.OnProcessAdditional = deElementValue(Rules, StringType);
			
			NewRow.HasOnProcessHandlerAdditional = Not IsBlankString(NewRow.OnProcessAdditional);
			
		ElsIf NodeName = "AfterProcess" Then
			
			NewRow.AfterProcess = deElementValue(Rules, StringType);
			
			NewRow.HasAfterProcessHandler = Not IsBlankString(NewRow.AfterProcess);
			
		ElsIf (NodeName = "Rule") And (Rules.NodeType = XMLNodeType.EndElement) Then
			
			Break;
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  Rules - XMLReader -  an object of the ReadXml type.
//  ValueTree - ValueTree -  tree rules for the registration of the object.
//
Procedure LoadFilterByExchangePlanPropertiesTree(Rules, ValueTree) Export
	
	VTRows = ValueTree.Rows;
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		NodeType = Rules.NodeType;
		
		If NodeName = "FilterElement" Then
			
			LoadExchangePlanFilterItem(Rules, VTRows.Add());
			
		ElsIf NodeName = "Group" Then
			
			LoadExchangePlanFilterItemGroup(Rules, VTRows.Add());
			
		ElsIf (NodeName = "FilterByExchangePlanProperties") And (NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//  Rules - XMLReader -  an object of the ReadXml type.
//  ValueTree - ValueTree -  tree rules for the registration of the object.
//
Procedure LoadFilterByObjectPropertiesTree(Rules, ValueTree) Export
	
	VTRows = ValueTree.Rows;
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		NodeType = Rules.NodeType;
		
		If NodeName = "FilterElement" Then
			
			LoadObjectFilterItem(Rules, VTRows.Add());
			
		ElsIf NodeName = "Group" Then
			
			LoadObjectFilterItemGroup(Rules, VTRows.Add());
			
		ElsIf (NodeName = "FilterByObjectProperties") And (NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Re-download rules of registration of the object by property.
//
// Parameters:
// 
Procedure LoadExchangePlanFilterItem(Rules, NewRow)
	
	NewRow.IsFolder = False;
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		NodeType = Rules.NodeType;
		
		If NodeName = "ObjectProperty1" Then
			
			If NewRow.IsConstantString Then
				
				NewRow.ConstantValue = deElementValue(Rules, Type(NewRow.ObjectPropertyType));
				
			Else
				
				NewRow.ObjectProperty1 = deElementValue(Rules, StringType);
				
			EndIf;
			
		ElsIf NodeName = "ExchangePlanProperty" Then
			
			// 
			// 
			// 
			// 
			// 
			FullPropertyDescription = deElementValue(Rules, StringType);
			
			ExchangePlanTabularSectionName = "";
			
			FirstBracketPosition = StrFind(FullPropertyDescription, "[");
			
			If FirstBracketPosition <> 0 Then
				
				SecondBracketPosition = StrFind(FullPropertyDescription, "]");
				
				ExchangePlanTabularSectionName = Mid(FullPropertyDescription, FirstBracketPosition + 1, SecondBracketPosition - FirstBracketPosition - 1);
				
				FullPropertyDescription = Mid(FullPropertyDescription, SecondBracketPosition + 2);
				
			EndIf;
			
			NewRow.NodeParameter                = FullPropertyDescription;
			NewRow.NodeParameterTabularSection = ExchangePlanTabularSectionName;
			
		ElsIf NodeName = "ComparisonType" Then
			
			NewRow.ComparisonType = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "IsConstantString" Then
			
			NewRow.IsConstantString = deElementValue(Rules, BooleanType);
			
		ElsIf NodeName = "ObjectPropertyType" Then
			
			NewRow.ObjectPropertyType = deElementValue(Rules, StringType);
			
		ElsIf (NodeName = "FilterElement") And (NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Re-download rules of registration of the object by property.
//
// Parameters:
// 
Procedure LoadObjectFilterItem(Rules, NewRow)
	
	NewRow.IsFolder = False;
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		NodeType = Rules.NodeType;
		
		If NodeName = "ObjectProperty1" Then
			
			NewRow.ObjectProperty1 = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "ConstantValue" Then
			
			If IsBlankString(NewRow.FilterItemKind) Then
				
				NewRow.FilterItemKind = DataExchangeServer.FilterItemPropertyConstantValue();
				
			EndIf;
			
			If NewRow.FilterItemKind = DataExchangeServer.FilterItemPropertyConstantValue() Then
				
				// 
				NewRow.ConstantValue = deElementValue(Rules, Type(NewRow.ObjectPropertyType));
				
			ElsIf NewRow.FilterItemKind = DataExchangeServer.FilterItemPropertyValueAlgorithm() Then
				
				NewRow.ConstantValue = deElementValue(Rules, StringType); // String
				
			Else
				
				NewRow.ConstantValue = deElementValue(Rules, StringType); // String
				
			EndIf;
			
		ElsIf NodeName = "ComparisonType" Then
			
			NewRow.ComparisonType = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "ObjectPropertyType" Then
			
			NewRow.ObjectPropertyType = deElementValue(Rules, StringType);
			
		ElsIf NodeName = "Kind" Then
			
			NewRow.FilterItemKind = deElementValue(Rules, StringType);
			
		ElsIf (NodeName = "FilterElement") And (NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// It uploads a group of rules of registration of the object by property.
//
// Parameters:
//  Rules  - XMLReader -  an object of the ReadXml type.
//  NewRow - ValueTreeRow -  string tree rules for the registration of the object.
//
Procedure LoadExchangePlanFilterItemGroup(Rules, NewRow)
	
	NewRow.IsFolder = True;
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		NodeType = Rules.NodeType;
		
		If NodeName = "FilterElement" Then
			
			LoadExchangePlanFilterItem(Rules, NewRow.Rows.Add());
		
		ElsIf (NodeName = "Group") And (NodeType = XMLNodeType.StartElement) Then
			
			LoadExchangePlanFilterItemGroup(Rules, NewRow.Rows.Add());
			
		ElsIf NodeName = "BooleanGroupValue" Then
			
			NewRow.BooleanGroupValue = deElementValue(Rules, StringType);
			
		ElsIf (NodeName = "Group") And (NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;

EndProcedure

// It uploads a group of rules of registration of the object by property.
//
// Parameters:
//  Rules  - XMLReader -  an object of the ReadXml type.
//  NewRow - ValueTreeRow -  string tree rules for the registration of the object.
//
Procedure LoadObjectFilterItemGroup(Rules, NewRow)
	
	NewRow.IsFolder = True;
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		NodeType = Rules.NodeType;
		
		If NodeName = "FilterElement" Then
			
			LoadObjectFilterItem(Rules, NewRow.Rows.Add());
		
		ElsIf (NodeName = "Group") And (NodeType = XMLNodeType.StartElement) Then
			
			LoadObjectFilterItemGroup(Rules, NewRow.Rows.Add());
			
		ElsIf NodeName = "BooleanGroupValue" Then
			
			BooleanGroupValue = deElementValue(Rules, StringType);
			
			NewRow.IsANDOperator = (BooleanGroupValue = "And");
			
		ElsIf (NodeName = "Group") And (NodeType = XMLNodeType.EndElement) Then
			
			Break; // 
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;

EndProcedure

Procedure LoadRecordRuleGroup(Rules)
	
	While Rules.Read() Do
		
		NodeName = Rules.LocalName;
		
		If NodeName = "Rule" Then
			
			LoadRecordRule(Rules);
			
		ElsIf NodeName = "Group" And Rules.NodeType = XMLNodeType.StartElement Then
			
			LoadRecordRuleGroup(Rules);
			
		ElsIf NodeName = "Group" And Rules.NodeType = XMLNodeType.EndElement Then
		
			Break;
			
		Else
			
			deSkip(Rules);
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure PrepareRecordRuleByExchangePlanProperties(ORR) Export
	
	EmptyRule = (ORR.FilterByExchangePlanProperties.Rows.Count() = 0);
	
	ObjectProperties = New Structure;
	
	FieldSelectionText = "SELECT DISTINCT ExchangePlanMainTable.Ref AS Ref";
	
	// 
	DataTable = ORRData(ORR.FilterByExchangePlanProperties.Rows);
	
	TableDataText = GetDataTablesTextForORR(DataTable);
	
	If EmptyRule Then
		
		ConditionText = "True";
		
	Else
		
		ConditionText = GetPropertyGroupConditionText(ORR.FilterByExchangePlanProperties.Rows, BooleanRootPropertiesGroupValue, 0, ObjectProperties);
		
	EndIf;
	
	QueryText = FieldSelectionText + Chars.LF 
	             + "FROM"  + Chars.LF + TableDataText + Chars.LF // @query-part
	             + "WHERE" + Chars.LF + ConditionText
	             + Chars.LF + "[MandatoryConditions]";
	//
	
	// 
	ORR.QueryText    = QueryText;
	ORR.ObjectProperties = ObjectProperties;
	ORR.ObjectPropertiesAsString = GetObjectPropertiesAsString(ObjectProperties);
	
EndProcedure

Function GetPropertyGroupConditionText(GroupProperties, BooleanGroupValue, Val Offset, ObjectProperties)
	
	OffsetString = "";
	
	// 
	For IterationNumber = 0 To Offset Do
		OffsetString = OffsetString + " ";
	EndDo;
	
	ConditionText = "";
	
	For Each RecordRuleByProperty In GroupProperties Do
		
		If RecordRuleByProperty.IsFolder Then
			
			ConditionPrefix = ?(IsBlankString(ConditionText), "", Chars.LF + OffsetString + BooleanGroupValue + " ");
			
			ConditionText = ConditionText + ConditionPrefix + GetPropertyGroupConditionText(RecordRuleByProperty.Rows, RecordRuleByProperty.BooleanGroupValue, Offset + 10, ObjectProperties);
			
		Else
			
			ConditionPrefix = ?(IsBlankString(ConditionText), "", Chars.LF + OffsetString + BooleanGroupValue + " ");
			
			ConditionText = ConditionText + ConditionPrefix + GetPropertyConditionText(RecordRuleByProperty, ObjectProperties);
			
		EndIf;
		
	EndDo;
	
	ConditionText = "(" + ConditionText + Chars.LF 
				 + OffsetString + ")";
	
	Return ConditionText;
	
EndFunction

Function GetDataTablesTextForORR(DataTable)
	
	TableDataText = "ExchangePlan." + Registration.ExchangePlanName + " AS ExchangePlanMainTable";
	
	For Each TableRow In DataTable Do
		
		TableSynonym = Registration.ExchangePlanName + TableRow.Name;
		
		TableDataText = TableDataText + Chars.LF + Chars.LF + "LEFT JOIN" + Chars.LF
		                 + "ExchangePlan." + Registration.ExchangePlanName + "." + TableRow.Name + " AS " + TableSynonym + "" + Chars.LF
		                 + "On ExchangePlanMainTable.Ref = " + TableSynonym + ".Ref";
		
	EndDo;
	
	Return TableDataText;
	
EndFunction

Function ORRData(GroupProperties)
	
	DataTable = New ValueTable;
	DataTable.Columns.Add("Name");
	
	For Each RecordRuleByProperty In GroupProperties Do
		
		If RecordRuleByProperty.IsFolder Then
			
			// 
			GroupDataTable = ORRData(RecordRuleByProperty.Rows);
			
			// 
			For Each GroupTableRow In GroupDataTable Do
				
				FillPropertyValues(DataTable.Add(), GroupTableRow);
				
			EndDo;
			
		Else
			
			TableName = RecordRuleByProperty.NodeParameterTabularSection;
			
			// 
			If Not IsBlankString(TableName) Then
				
				TableRow = DataTable.Add();
				TableRow.Name = TableName;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// 
	DataTable.GroupBy("Name");
	
	Return DataTable;
	
EndFunction

Function GetPropertyConditionText(Rule, ObjectProperties)
	
	RuleComparisonKind = Rule.ComparisonType;
	
	// 
	// 
	// 
	InvertComparisonType(RuleComparisonKind);
	
	TextOperator = GetCompareOperatorText(RuleComparisonKind);
	
	TableSynonym = ?(IsBlankString(Rule.NodeParameterTabularSection),
	                              "ExchangePlanMainTable",
	                               Registration.ExchangePlanName + Rule.NodeParameterTabularSection);
	//
	
	// 
	//
	// Example:
	// 
	// 
	
	If Rule.IsConstantString Then
		
		ConstantValueType = TypeOf(Rule.ConstantValue);
		
		If ConstantValueType = BooleanType Then // Boolean
			
			QueryParameterLiteral = Format(Rule.ConstantValue, "BF= False; BT=Истина");
			
		ElsIf ConstantValueType = NumberType Then // Number
			
			QueryParameterLiteral = Format(Rule.ConstantValue, "NDS=.; NZ=0; NG=0; NN=1");
			
		ElsIf ConstantValueType = DateType Then // Date
			
			YearString     = Format(Year(Rule.ConstantValue),     "NZ=0; NG=0");
			MonthString   = Format(Month(Rule.ConstantValue),   "NZ=0; NG=0");
			DayString    = Format(Day(Rule.ConstantValue),    "NZ=0; NG=0");
			HourString     = Format(Hour(Rule.ConstantValue),     "NZ=0; NG=0");
			MinuteString  = Format(Minute(Rule.ConstantValue),  "NZ=0; NG=0");
			SecondString = Format(Second(Rule.ConstantValue), "NZ=0; NG=0");
			
			QueryParameterLiteral = "DATETIME("
			+ YearString + ","
			+ MonthString + ","
			+ DayString + ","
			+ HourString + ","
			+ MinuteString + ","
			+ SecondString
			+ ")";
			
		Else // String
			
			// 
			QueryParameterLiteral = """" + Rule.ConstantValue + """";
			
		EndIf;
		
	Else
		
		ObjectPropertyKey = StrReplace(Rule.ObjectProperty1, ".", "_");
		
		QueryParameterLiteral = "&ObjectProperty1_" + ObjectPropertyKey + "";
		
		ObjectProperties.Insert(ObjectPropertyKey, Rule.ObjectProperty1);
		
	EndIf;
	
	ConditionText = TableSynonym + "." + Rule.NodeParameter + " " + TextOperator + " " + QueryParameterLiteral;
	
	Return ConditionText;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure PrepareRegistrationRuleByObjectProperties(ORR)
	
	ORR.RuleByObjectPropertiesEmpty = (ORR.FilterByObjectProperties.Rows.Count() = 0);
	
	// 
	If ORR.RuleByObjectPropertiesEmpty Then
		Return;
	EndIf;
	
	ObjectProperties = New Structure;
	
	FillObjectPropertyStructure(ORR.FilterByObjectProperties, ObjectProperties);
	
EndProcedure

Procedure FillObjectPropertyStructure(ValueTree, ObjectProperties)
	
	For Each TreeRow In ValueTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			FillObjectPropertyStructure(TreeRow, ObjectProperties);
			
		Else
			
			TreeRow.ObjectPropertyKey = StrReplace(TreeRow.ObjectProperty1, ".", "_");
			
			ObjectProperties.Insert(TreeRow.ObjectPropertyKey, TreeRow.ObjectProperty1);
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Procedure ReportProcessingError(Code = -1, ErrorDescription = "")
	
	// 
	FlagErrors = True;
	
	If ErrorsMessages = Undefined Then
		ErrorsMessages = InitMessages();
	EndIf;
	
	MessageString = ErrorsMessages[Code];
	
	MessageString = ?(MessageString = Undefined, "", MessageString);
	
	If Not IsBlankString(ErrorDescription) Then
		
		MessageString = MessageString + Chars.LF + ErrorDescription;
		
	EndIf;
	
	WriteLogEvent(EventLogMessageKey(), EventLogLevel.Error,,, MessageString);
	
EndProcedure

Procedure InvertComparisonType(Var_ComparisonType)
	
	If      Var_ComparisonType = "Greater"         Then Var_ComparisonType = "Less";
	ElsIf Var_ComparisonType = "GreaterOrEqual" Then Var_ComparisonType = "LessOrEqual";
	ElsIf Var_ComparisonType = "Less"         Then Var_ComparisonType = "Greater";
	ElsIf Var_ComparisonType = "LessOrEqual" Then Var_ComparisonType = "GreaterOrEqual";
	EndIf;
	
EndProcedure

Procedure CheckExchangePlanExists()
	
	If TypeOf(Registration) <> Type("Structure") Then
		
		ReportProcessingError(0);
		Return;
		
	EndIf;
	
	If Registration.ExchangePlanName <> ExchangePlanNameForImport Then
		
		ErrorDescription = NStr("en = 'The exchange plan name specified in the registration rules (%1) does not match the exchange plan name whose data is imported (%2)';");
		ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(ErrorDescription, Registration.ExchangePlanName, ExchangePlanNameForImport);
		ReportProcessingError(5, ErrorDescription);
		
	EndIf;
	
EndProcedure

Function GetCompareOperatorText(Val Var_ComparisonType = "Equal")
	
	// 
	TextOperator = "=";
	
	If      Var_ComparisonType = "Equal"          Then TextOperator = "=";
	ElsIf Var_ComparisonType = "NotEqual"        Then TextOperator = "<>";
	ElsIf Var_ComparisonType = "Greater"         Then TextOperator = ">";
	ElsIf Var_ComparisonType = "GreaterOrEqual" Then TextOperator = ">=";
	ElsIf Var_ComparisonType = "Less"         Then TextOperator = "<";
	ElsIf Var_ComparisonType = "LessOrEqual" Then TextOperator = "<=";
	EndIf;
	
	Return TextOperator;
EndFunction

Function GetConfigurationPresentationFromRegistrationRules()
	
	ConfigurationName = "";
	Registration.Property("ConfigurationSynonym", ConfigurationName);
	
	If Not ValueIsFilled(ConfigurationName) Then
		Return "";
	EndIf;
	
	AccurateVersion = "";
	Registration.Property("ConfigurationVersion", AccurateVersion);
	
	If ValueIsFilled(AccurateVersion) Then
		
		AccurateVersion = CommonClientServer.ConfigurationVersionWithoutBuildNumber(AccurateVersion);
		
		ConfigurationName = ConfigurationName + " version " + AccurateVersion;
		
	EndIf;
	
	Return ConfigurationName;
		
EndFunction

Function GetObjectPropertiesAsString(ObjectProperties)
	
	Result = "";
	
	For Each Item In ObjectProperties Do
		
		Result = Result + Item.Value + " AS " + Item.Key + ", ";
		
	EndDo;
	
	// 
	StringFunctionsClientServer.DeleteLastCharInString(Result, 2);
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Reads the attribute value by name from the specified object, and converts the value
// to the specified primitive type.
//
// Parameters:
//   Object      - XMLReader -  an object positioned at the beginning of the element whose
//                 attribute you want to get.
//   Type         - Type -  attribute type.
//   Name         - String -  attribute name.
//
// Returns:
//   Arbitrary - 
//
Function deAttribute(Object, Type, Name)
	
	ValueStr = TrimR(Object.GetAttribute(Name));
	
	If Not IsBlankString(ValueStr) Then
		
		Return XMLValue(Type, ValueStr);
		
	Else
		If Type = StringType Then
			Return "";
			
		ElsIf Type = BooleanType Then
			Return False;
			
		ElsIf Type = NumberType Then
			Return 0;
			
		ElsIf Type = DateType Then
			Return BlankDateValue1;
			
		EndIf;
	EndIf;
	
EndFunction

// Reads the text of the element and converts the value to the specified type.
//
// Parameters:
//  Object           - XMLReader -  the object to read from.
//  Type              - Type -  the type of value to get.
//  SearchByProperty - String -  for reference types, you can specify a property
//                     to search for the object by: "Code", "Name", <Requestname>, "Name" (predefined value).
//
// Returns:
//   Arbitrary - 
//
Function deElementValue(Object, Type, SearchByProperty="")

	Value = "";
	Name      = Object.LocalName;

	While Object.Read() Do
		
		NodeName = Object.LocalName;
		NodeType = Object.NodeType;
		
		If NodeType = XMLNodeType.Text Then
			
			Value = TrimR(Object.Value);
			
		ElsIf (NodeName = Name) And (NodeType = XMLNodeType.EndElement) Then
			
			Break;
			
		Else
			
			Return Undefined;
			
		EndIf;
	EndDo;
	
	Return XMLValue(Type, Value)
	
EndFunction

// Skips xml nodes to the end of the specified element (by default, the current one).
//
// Parameters:
//  Object   - an object of the ReadXml type.
//  Name      - name of the node to skip elements to the end of.
//
Procedure deSkip(Object, Name = "")
	
	AttachmentsCount = 0; // 
	
	If IsBlankString(Name) Then
	
		Name = Object.LocalName;
	
	EndIf;
	
	While Object.Read() Do
		
		NodeName = Object.LocalName;
		NodeType = Object.NodeType;
		
		If NodeName = Name Then
			
			If NodeType = XMLNodeType.EndElement Then
				
				If AttachmentsCount = 0 Then
					Break;
				Else
					AttachmentsCount = AttachmentsCount - 1;
				EndIf;
				
			ElsIf NodeType = XMLNodeType.StartElement Then
				
				AttachmentsCount = AttachmentsCount + 1;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

Function EventLogMessageKey()
	
	Return DataExchangeServer.DataExchangeRulesImportEventLogEvent();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Initializes processing details and module variables.
//
// Parameters:
//  No.
// 
Procedure InitAttributesAndModuleVariables()
	
	FlagErrors = False;
	
	// Types
	StringType            = Type("String");
	BooleanType            = Type("Boolean");
	NumberType             = Type("Number");
	DateType              = Type("Date");
	
	BlankDateValue1 = Date('00010101');
	
	BooleanRootPropertiesGroupValue = "And"; // 
	
EndProcedure

// Initializes the registration structure.
//
// Parameters:
//  No.
// 
Function RecordInitialization()
	
	Registration = New Structure;
	Registration.Insert("FormatVersion",       "");
	Registration.Insert("ID",                  "");
	Registration.Insert("Description",        "");
	Registration.Insert("CreationDateTime",   BlankDateValue1);
	Registration.Insert("ExchangePlan",          "");
	Registration.Insert("ExchangePlanName",      "");
	Registration.Insert("Comment",         "");
	
	// 
	Registration.Insert("PlatformVersion",     "");
	Registration.Insert("ConfigurationVersion",  "");
	Registration.Insert("ConfigurationSynonym", "");
	Registration.Insert("Configuration",        "");
	
	Return Registration;
	
EndFunction

// Initializes a variable containing matches of message codes to their descriptions.
//
// Parameters:
//  No.
// 
Function InitMessages()
	
	Messages = New Map;
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	Messages.Insert(0, NStr("en = 'Internal error';", DefaultLanguageCode));
	Messages.Insert(1, NStr("en = 'Cannot open the exchange rules file.';", DefaultLanguageCode));
	Messages.Insert(2, NStr("en = 'Cannot load the exchange rules.';", DefaultLanguageCode));
	Messages.Insert(3, NStr("en = 'Exchange rule format error';", DefaultLanguageCode));
	Messages.Insert(4, NStr("en = 'Cannot get the exchange rules file.';", DefaultLanguageCode));
	Messages.Insert(5, NStr("en = 'The registration rules are not intended for the current exchange plan.';", DefaultLanguageCode));
	
	Return Messages;
	
EndFunction

#EndRegion

#Region Initialize

InitAttributesAndModuleVariables();

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf