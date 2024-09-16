///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sets the full-text search mode
// Performs:
//   - changes the mode of the platform full-text search engine
//   - setting the value to a constant use full-text Search
//   - changes the value of the use full text Search function option
//   - changes the mode of routine task Updatingindexappd
//   - changes the mode of routine task Mergingindexappd
//   - changes the mode of routine task of extracting The text of the subsystem for working with Files
//
Function SetFullTextSearchMode(UseFullTextSearch) Export
	
	If Not Users.IsFullUser(,, False) Then
		Raise(NStr("en = 'Insufficient rights to perform the operation.';"), ErrorCategory.AccessViolation);
	EndIf;
	
	Try
		Constants.UseFullTextSearch.Set(UseFullTextSearch);	
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// See FullTextSearchServer.UseSearchFlagValue
Function UseSearchFlagValue() Export

	Return FullTextSearchServer.UseSearchFlagValue();

EndFunction

#EndRegion

