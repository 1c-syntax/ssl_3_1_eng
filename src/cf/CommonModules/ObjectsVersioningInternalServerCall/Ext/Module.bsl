///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Sets the mode for storing the history of changes
// Performs:
//   - setting the value to the constant use versioning of Objects
//   - changes the value of the use object Versioning function option
//   
Function SetChangeHistoryStorageMode(StoreChangeHistory) Export
	
	If Not Users.IsFullUser(,, False) Then
		Raise(NStr("en = 'Insufficient rights to perform the operation.';"), ErrorCategory.AccessViolation);
	EndIf;
	
	Try
		Constants.UseObjectsVersioning.Set(StoreChangeHistory);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// (See ObjectsVersioning.StoreHistoryCheckBoxValue)
//
Function StoreHistoryCheckBoxValue() Export
	
	Return ObjectsVersioning.StoreHistoryCheckBoxValue();
	
EndFunction

#EndRegion

