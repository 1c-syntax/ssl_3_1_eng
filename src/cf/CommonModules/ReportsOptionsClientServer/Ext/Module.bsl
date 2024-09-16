///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// ID that is used for the home page in the report Variationsreadable module.
//
// Returns:
//   String - 
//
Function HomePageID() Export
	
	Return "Subsystems";
	
EndFunction

#EndRegion

#Region Internal

// Adds a Key to the Structure if it doesn't exist.
//
// Parameters:
//   Structure - Structure    -  augmented structure.
//   Var_Key      - String       -  property name.
//   Value  - Arbitrary -  the value of the property if it is not present in the structure.
//
Procedure AddKeyToStructure(Structure, Var_Key, Value = Undefined) Export
	If Not Structure.Property(Var_Key) Then
		Structure.Insert(Var_Key, Value);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// The full name of the subsystem.
Function FullSubsystemName() Export
	Return "StandardSubsystems.ReportsOptions";
EndFunction

// Turns the search string into an array of words with unique values, sorted in descending order of length.
Function ParseSearchStringIntoWordArray(SearchString) Export
	WordsAndTheirLength = New ValueList;
	StringLength = StrLen(SearchString);
	
	Word = "";
	WordLength = 0;
	QuotationMarkOpened = False;
	For CharacterNumber = 1 To StringLength Do
		CharCode = CharCode(SearchString, CharacterNumber);
		If CharCode = 34 Then // 
			QuotationMarkOpened = Not QuotationMarkOpened;
		ElsIf QuotationMarkOpened
			Or (CharCode >= 48 And CharCode <= 57) // Digits
			Or (CharCode >= 65 And CharCode <= 90) // 
			Or (CharCode >= 97 And CharCode <= 122) // 
			Or (CharCode >= 1040 And CharCode <= 1103) // CyrillicCharacters
			Or CharCode = 95 Then // 
			Word = Word + Char(CharCode);
			WordLength = WordLength + 1;
		ElsIf Word <> "" Then
			If WordsAndTheirLength.FindByValue(Word) = Undefined Then
				WordsAndTheirLength.Add(Word, Format(WordLength, "ND=3; NLZ="));
			EndIf;
			Word = "";
			WordLength = 0;
		EndIf;
	EndDo;
	
	If Word <> "" And WordsAndTheirLength.FindByValue(Word) = Undefined Then
		WordsAndTheirLength.Add(Word, Format(WordLength, "ND=3; NLZ="));
	EndIf;
	
	WordsAndTheirLength.SortByPresentation(SortDirection.Desc);
	
	Return WordsAndTheirLength.UnloadValues();
EndFunction

// Turns the report type into a string identifier.
Function ReportByStringType(Val ReportType, Val Report = Undefined) Export
	TypeOfReportType = TypeOf(ReportType);
	If TypeOfReportType = Type("String") Then
		Return ReportType;
	ElsIf TypeOfReportType = Type("EnumRef.ReportsTypes") Then
		If ReportType = PredefinedValue("Enum.ReportsTypes.BuiltIn") Then
			Return "BuiltIn";
		ElsIf ReportType = PredefinedValue("Enum.ReportsTypes.Extension") Then
			Return "Extension";
		ElsIf ReportType = PredefinedValue("Enum.ReportsTypes.Additional") Then
			Return "Additional";
		ElsIf ReportType = PredefinedValue("Enum.ReportsTypes.External") Then
			Return "External";
		Else
			Return Undefined;
		EndIf;
	Else
		If TypeOfReportType <> Type("Type") Then
			ReportType = TypeOf(Report);
		EndIf;
		If ReportType = Type("CatalogRef.MetadataObjectIDs") Then
			Return "BuiltIn";
		ElsIf ReportType = Type("CatalogRef.ExtensionObjectIDs") Then
			Return "Extension";
		ElsIf ReportType = Type("String") Then
			Return "External";
		Else
			Return "Additional";
		EndIf;
	EndIf;
EndFunction

#Region UserSettingsExchange

Function ApplyPassedSettingsActionName() Export 
	
	Return "ApplyPassedSettings";
	
EndFunction

#EndRegion

#EndRegion
