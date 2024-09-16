///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
//
// Returns:
//   See Users.GenerateUserSelectionData
//
Function GenerateUserSelectionData(Val Text,
                                             Val IncludeGroups = True,
                                             Val IncludeExternalUsers = Undefined,
                                             Val NoUsers = False) Export
	
	Return Users.GenerateUserSelectionData(
		Text,
		IncludeGroups,
		IncludeExternalUsers,
		NoUsers);
	
EndFunction

Function AccessRightsAnalysisReportDetailsParameters(DetailsDataAddress, Details) Export
	
	Return Reports.AccessRightsAnalysis.DetailsParameters(DetailsDataAddress, Details);
	
EndFunction

#EndRegion


#Region Private

Function ShortcutUseDestinationKey(Val PurposeUseKey) Export
	
	If StrLen(PurposeUseKey) <= 128 Then
		Return PurposeUseKey;
	EndIf;
	
	HashLength = 33;
	Balance = Mid(PurposeUseKey, 129 - HashLength);
	Begin = Left(PurposeUseKey, 128 - HashLength);
	
	Hashing = New DataHashing(HashFunction.MD5);
	Hashing.Append(Balance);
	StringHash = GetHexStringFromBinaryData(Hashing.HashSum);
	
	Return Begin + "_" + StringHash;
	
EndFunction

#EndRegion