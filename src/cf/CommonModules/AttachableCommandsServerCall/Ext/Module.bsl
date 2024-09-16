///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns a description of the command by the name of the form element.
Function CommandDetails(CommandNameInForm, SettingsAddress) Export
	Return AttachableCommands.CommandDetails(CommandNameInForm, SettingsAddress);
EndFunction

// Analyzes the array of documents to determine whether they have been completed and whether they have the rights to conduct them.
Function DocumentsInfo(ReferencesArrray) Export
	Result = New Structure;
	Result.Insert("Unposted", Common.CheckDocumentsPosting(ReferencesArrray));
	Result.Insert("HasRightToPost", StandardSubsystemsServer.HasRightToPost(Result.Unposted));
	Return Result;
EndFunction

#EndRegion
