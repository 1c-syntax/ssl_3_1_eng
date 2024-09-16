///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Deletes the information base prefix and the company prefix from the passed object Number string.
// The variable of the number Object must match the template: OOGG-XXX ... XX or GG-XXX...XX, where:
//    OO is the prefix of the company;
//    GG - prefix of the information base;
//    "- "separator;
//    XXX...XX is the number/code of the object.
// Non-significant prefix characters (the zero - "0" character) are also removed.
//
// Parameters:
//    ObjectNumber - String -  the number or code of the object from which you want to remove the prefixes.
//    DeleteCompanyPrefix - Boolean -  whether to delete the company prefix;
//                                         the default value is False.
//    DeleteInfobasePrefix - Boolean -  a sign of the removal of the prefix information base;
//                                                the default value is False.
//
// Returns:
//     String - 
//
// Example:
//    Delete object numberrefix ("0FGL-000001234", True, True) = " 000001234"
//    Delete the prefix of the object's number ("0FGL-000001234", False, True)   = "F-000001234"
//    Delete object numberrefixs ("0FGL-000001234", True, False) = " GL-000001234"
//    Delete object numberrefixs ("0FGL-000001234", False, False)     = "FGL-000001234"
//
Function DeletePrefixesFromObjectNumber(Val ObjectNumber, DeleteCompanyPrefix = False, DeleteInfobasePrefix = False) Export
	
	If Not NumberContainsStandardPrefix(ObjectNumber) Then
		Return ObjectNumber;
	EndIf;
	
	// 
	ObjectPrefix = "";
	
	NumberContainsFiveDigitPrefix = NumberContainsFiveDigitPrefix(ObjectNumber);
	
	If NumberContainsFiveDigitPrefix Then
		CompanyPrefix        = Left(ObjectNumber, 2);
		InfobasePrefix = Mid(ObjectNumber, 3, 2);
	Else
		CompanyPrefix = "";
		InfobasePrefix = Left(ObjectNumber, 2);
	EndIf;
	
	CompanyPrefix        = StringFunctionsClientServer.DeleteDuplicateChars(CompanyPrefix, "0");
	InfobasePrefix = StringFunctionsClientServer.DeleteDuplicateChars(InfobasePrefix, "0");
	
	// 
	If Not DeleteCompanyPrefix Then
		
		ObjectPrefix = ObjectPrefix + CompanyPrefix;
		
	EndIf;
	
	// 
	If Not DeleteInfobasePrefix Then
		
		ObjectPrefix = ObjectPrefix + InfobasePrefix;
		
	EndIf;
	
	If Not IsBlankString(ObjectPrefix) Then
		
		ObjectPrefix = ObjectPrefix + "-";
		
	EndIf;
	
	Return ObjectPrefix + Mid(ObjectNumber, ?(NumberContainsFiveDigitPrefix, 6, 4));
EndFunction

// Removes leading zeros from the object number.
// The variable of the number Object must match the template: OOGG-XXX ... XX or GG-XXX...XX, where.
// OO - prefix of the company;
// GG - prefix of the information base;
// "- "separator;
// XXX...XX is the number/code of the object.
//
// Parameters:
//    ObjectNumber - String -  the number or code of the object from which leading zeros are required.
// 
// Returns:
//     String - 
//
Function DeleteLeadingZerosFromObjectNumber(Val ObjectNumber) Export
	
	CustomPrefix = CustomPrefix(ObjectNumber);
	
	If NumberContainsStandardPrefix(ObjectNumber) Then
		
		If NumberContainsFiveDigitPrefix(ObjectNumber) Then
			Prefix = Left(ObjectNumber, 5);
			Number = Mid(ObjectNumber, 6 + StrLen(CustomPrefix));
		Else
			Prefix = Left(ObjectNumber, 3);
			Number = Mid(ObjectNumber, 4 + StrLen(CustomPrefix));
		EndIf;
		
	Else
		
		Prefix = "";
		Number = Mid(ObjectNumber, 1 + StrLen(CustomPrefix));
		
	EndIf;
	
	// 
	Number = StringFunctionsClientServer.DeleteDuplicateChars(Number, "0");
	
	Return Prefix + CustomPrefix + Number;
EndFunction

// Removes all user prefixes from the object number (all non-numeric characters).
// The variable of the number Object must match the template: OOGG-XXX ... XX or GG-XXX...XX, where.
// OO - prefix of the company;
// GG - prefix of the information base;
// "- "separator;
// XXX...XX is the number/code of the object.
//
// Parameters:
//     ObjectNumber - String -  the number or code of the object from which leading zeros are required.
// 
// Returns:
//     String - 
//
Function DeleteCustomPrefixesFromObjectNumber(Val ObjectNumber) Export
	
	NumericCharactersString = "0123456789";
	
	If NumberContainsStandardPrefix(ObjectNumber) Then
		
		If NumberContainsFiveDigitPrefix(ObjectNumber) Then
			Prefix     = Left(ObjectNumber, 5);
			FullNumber = Mid(ObjectNumber, 6);
		Else
			Prefix     = Left(ObjectNumber, 3);
			FullNumber = Mid(ObjectNumber, 4);
		EndIf;
		
	Else
		
		Prefix     = "";
		FullNumber = ObjectNumber;
		
	EndIf;
	
	Number = "";
	
	For IndexOf = 1 To StrLen(FullNumber) Do
		
		Char = Mid(FullNumber, IndexOf, 1);
		
		If StrFind(NumericCharactersString, Char) > 0 Then
			Number = Mid(FullNumber, IndexOf);
			Break;
		EndIf;
		
	EndDo;
	
	Return Prefix + Number;
EndFunction

// Gets a custom prefix for the object number / code.
// The variable of the number Object must match the pattern: OOGG-AAH...XX or GG-AAH...XX, where.
// OO - prefix of the company;
// GG - prefix of the information base;
// "-" - separator;
// AA - user prefix;
// XX..XX - object number / code.
//
// Parameters:
//    ObjectNumber - String -  the number or code of the object from which you want to get a custom prefix.
// 
// Returns:
//     String - 
//
Function CustomPrefix(Val ObjectNumber) Export
	
	// 
	Result = "";
	
	If NumberContainsStandardPrefix(ObjectNumber) Then
		
		If NumberContainsFiveDigitPrefix(ObjectNumber) Then
			ObjectNumber = Mid(ObjectNumber, 6);
		Else
			ObjectNumber = Mid(ObjectNumber, 4);
		EndIf;
		
	EndIf;
	
	NumericCharactersString = "0123456789";
	
	For IndexOf = 1 To StrLen(ObjectNumber) Do
		
		Char = Mid(ObjectNumber, IndexOf, 1);
		
		If StrFind(NumericCharactersString, Char) > 0 Then
			Break;
		EndIf;
		
		Result = Result + Char;
		
	EndDo;
	
	Return Result;
EndFunction

// Gets the number of the document to print; prefixes and leading zeros are removed from the number.
// Function:
// discards the company prefix,
// discards the information base prefix (optional),
// discards user prefixes (optional),
// and deletes leading zeros in the object number.
//
// Parameters:
//    ObjectNumber - String -  the number or code of the object that is being converted for printing.
//    DeleteInfobasePrefix - Boolean -  indicates whether the database prefix is deleted.
//    DeleteCustomPrefix - Boolean -  indicates whether the user prefix is deleted.
//
// Returns:
//     String - 
//
Function NumberForPrinting(Val ObjectNumber, DeleteInfobasePrefix = False, DeleteCustomPrefix = False) Export
	
	// 
	StandardProcessing = True;
	
	ObjectsPrefixesClientServerOverridable.OnGetNumberForPrinting(ObjectNumber, StandardProcessing,
		DeleteInfobasePrefix, DeleteCustomPrefix);
	
	If StandardProcessing = False Then
		Return ObjectNumber;
	EndIf;
	// 
	
	ObjectNumber = TrimAll(ObjectNumber);
	
	// 
	If DeleteCustomPrefix Then
		
		ObjectNumber = DeleteCustomPrefixesFromObjectNumber(ObjectNumber);
		
	EndIf;
	
	// 
	ObjectNumber = DeleteLeadingZerosFromObjectNumber(ObjectNumber);
	
	// 
	ObjectNumber = DeletePrefixesFromObjectNumber(ObjectNumber, True, DeleteInfobasePrefix);
	
	Return ObjectNumber;
EndFunction

#EndRegion

#Region Private

Function NumberContainsStandardPrefix(Val ObjectNumber)
	
	SeparatorPosition = StrFind(ObjectNumber, "-");
	
	Return (SeparatorPosition = 3 Or SeparatorPosition = 5);
	
EndFunction

Function NumberContainsFiveDigitPrefix(Val ObjectNumber)
	
	Return StrFind(ObjectNumber, "-") = 5;
	
EndFunction

#EndRegion
