///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// Parameters:
//  Id - String
//  Version - String
//         - Undefined
//  ThePathToTheLayoutToSearchForTheLatestVersion - 
//
// Returns:
//   See AddInsInternal.SavedAddInInformation
//
Function SavedAddInInformation(Id, Version = Undefined, ThePathToTheLayoutToSearchForTheLatestVersion = Undefined) Export
	
	Result = AddInsInternal.SavedAddInInformation(Id, Version, ThePathToTheLayoutToSearchForTheLatestVersion);
	If Result.State = "FoundInStorage" Or Result.State = "FoundInSharedStorage" Then 
		Version = Result.Attributes.Version;
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'For ID %1 (version %2), add-in %3 (version %4) was received.
			|State: %5';"), 
			Id, ?(Version <> Undefined, Version, NStr("en = 'not specified';")), Result.Attributes.Description, 
			Result.Attributes.Version, Result.State);
		WriteLogEvent(NStr("en = 'Add-ins';", Common.DefaultLanguageCode()),
			EventLogLevel.Information,, Result.Ref, MessageText);
	Else
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Failed to receive an add-in for ID %1 (version %2).
			|State: %3';"),
			Id, ?(Version <> Undefined, Version, NStr("en = 'not specified';")), Result.State);
		WriteLogEvent(NStr("en = 'Add-ins';", Common.DefaultLanguageCode()),
			EventLogLevel.Warning,,, MessageText);
	EndIf;
	Return Result;
	
EndFunction

// Add-in file name to save to the file.
//
Function ComponentFileName(Ref) Export 
	
	Return Common.ObjectAttributeValue(Ref, "FileName");
	
EndFunction

#EndRegion

