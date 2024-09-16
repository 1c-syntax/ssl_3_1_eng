///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// 
//
// Parameters:
//  FullName - See PersonsClientServerLocalization.OnDefineFullNameComponents.FullName
//  NameFormat - See PersonsClientServerLocalization.OnDefineFullNameComponents.NameFormat
//	
// Returns:
//   See PersonsClientServerLocalization.OnDefineFullNameComponents.Result
//
Function NameParts(FullName, Val NameFormat = "") Export
	
	Result = New Structure;
	
	PersonsClientServerLocalization.OnDefineFullNameComponents(FullName, NameFormat, Result);
	If ValueIsFilled(Result) Then
		Return Result;
	EndIf;
	
	Result = New Structure;
	Result.Insert("LastName", "");
	Result.Insert("Name", "");

	If Not ValueIsFilled(FullName) Then
		Return Result;
	EndIf;
	
	If Not ValueIsFilled(FullName) Then
		Return Result;
	EndIf;

	IsNameComesFirst = NameFormat = "Name,LastName" Or NameFormat = "";
	NameParts = StrSplit(FullName, " ", False); 
	
	If IsNameComesFirst Then
		If NameParts.Count() > 1 Then
			Result.LastName = NameParts[NameParts.UBound()];
			NameParts.Delete(NameParts.UBound());
		EndIf;
	
		Result.Name = StrConcat(NameParts, " ");
	Else
		If NameParts.Count() >= 1 Then
			Result.LastName = NameParts[0];
			NameParts.Delete(0);
		EndIf;
	
		Result.Name = StrConcat(NameParts, " ");
	EndIf;
	
	Return Result;
	
EndFunction

// 
//
// Parameters:
//  FullName - See PersonsClientServerLocalization.OnDefineSurnameAndInitials.FullName
//  FullNameFormat - See PersonsClientServerLocalization.OnDefineSurnameAndInitials.FullNameFormat
//  IsInitialsComeFirst - See PersonsClientServerLocalization.OnDefineSurnameAndInitials.IsInitialsComeFirst
//
// Returns:
//   See PersonsClientServerLocalization.OnDefineSurnameAndInitials.Result
//
Function InitialsAndLastName(Val FullName, Val FullNameFormat = "", Val IsInitialsComeFirst = False) Export
	
	Result = "";
	
	PersonsClientServerLocalization.OnDefineSurnameAndInitials(FullName, FullNameFormat, IsInitialsComeFirst, Result);
	If ValueIsFilled(Result) Or Not ValueIsFilled(FullName) Then
		Return Result;
	EndIf;
	
	If TypeOf(FullName) = Type("String") Then
		FullName = NameParts(FullName);
	EndIf;
	
	LastName = FullName.LastName;
	Name = FullName.Name;
	
	If IsBlankString(Name) Then
		Return LastName;
	EndIf;
	
	If FullNameFormat = "Name,LastName" Then
		Template = "%2. %1";
	Else
		Template = "%1 %2.";
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(Template, LastName, Left(Name, 1));
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// 
// 
// 
//
// Parameters:
//  LastFirstName - String - 
//  IsOnlyNationalScriptLetters - Boolean - 
//
// Returns:
//  Boolean - 
//
Function FullNameWrittenCorrectly(Val LastFirstName, IsOnlyNationalScriptLetters = False) Export
	
	CheckResult = True;
	PersonsClientServerLocalization.FullNameWrittenCorrectly(LastFirstName, IsOnlyNationalScriptLetters, CheckResult);
	
	Return CheckResult;
	
EndFunction

#EndRegion

#EndRegion
