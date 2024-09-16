///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region InfobaseData

////////////////////////////////////////////////////////////////////////////////
// 

// Checks for references to the object in the database.
// When called in an undivided session, it does not detect links in split areas.
//
// See Common.RefsToObjectFound
//
// Parameters:
//  RefOrRefArray - AnyRef
//                        - Array - 
//  SearchInInternalObjects - Boolean -  if True,
//      the link search exceptions set during configuration development will not be taken into account.
//      About the deletion of search links read more
//      See CommonOverridable.OnAddReferenceSearchExceptions
//
// Returns:
//  Boolean - 
//
Function RefsToObjectFound(Val RefOrRefArray, Val SearchInInternalObjects = False) Export
	
	Return Common.RefsToObjectFound(RefOrRefArray, SearchInInternalObjects);
	
EndFunction

// Checks the status of the submitted documents and returns
// those that were not processed.
//
// See Common.CheckDocumentsPosting
//
// Parameters:
//  Var_Documents - Array -  documents that need to be checked for their status.
//
// Returns:
//  Array - 
//
Function CheckDocumentsPosting(Val Var_Documents) Export
	
	Return Common.CheckDocumentsPosting(Var_Documents);
	
EndFunction

// Attempts to process documents.
//
// See Common.PostDocuments
//
// Parameters:
//  Var_Documents - See Common.PostDocuments.Documents
//
// Returns:
//   See Common.PostDocuments
//
Function PostDocuments(Var_Documents) Export
	
	Return Common.PostDocuments(Var_Documents);
	
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
// See Common.CommonSettingsStorageSave
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
	
	Common.CommonSettingsStorageSave(
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
// See Common.CommonSettingsStorageSaveArray
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
Procedure CommonSettingsStorageSaveArray(MultipleSettings, RefreshReusableValues = False) Export
	
	Common.CommonSettingsStorageSaveArray(MultipleSettings, RefreshReusableValues);
	
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
// See Common.CommonSettingsStorageLoad
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
			SettingsDescription = Undefined,
			UserName = Undefined) Export
	
	Return Common.CommonSettingsStorageLoad(
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
// See Common.CommonSettingsStorageDelete
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
	
	Common.CommonSettingsStorageDelete(ObjectKey, SettingsKey, UserName);
	
EndProcedure

// Saves the setting to the system settings store, as the platform's Save method
// for the standard storage object Configuremanager, but with support for the settings key length
// of more than 128 characters by hashing the part that exceeds 96 characters.
// If you do not have the right to save the user's Data, saving is skipped without an error.
//
// See Common.SystemSettingsStorageSave
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
	
	Common.SystemSettingsStorageSave(
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
// - analysis of values in Array, Structure, and Match data is performed recursively
//
// See Common.SystemSettingsStorageLoad
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
			SettingsDescription = Undefined,
			UserName = Undefined) Export
	
	Return Common.SystemSettingsStorageLoad(
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
// See Common.SystemSettingsStorageDelete
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
	
	Common.SystemSettingsStorageDelete(ObjectKey, SettingsKey, UserName);
	
EndProcedure

// Saves the configuration in the form data settings store, as the Save platform method
// , for standard Storagesconfigurationmanager or Storagesconfigurationmanager objects.< Storage name>,
// but with support for a configuration key length of more than 128 characters by hashing the part
// that exceeds 96 characters.
// If you do not have the right to save the user's Data, saving is skipped without an error.
//
// See Common.FormDataSettingsStorageSave
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
	
	Common.FormDataSettingsStorageSave(
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
// See Common.FormDataSettingsStorageLoad
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
			SettingsDescription = Undefined,
			UserName = Undefined) Export
	
	Return Common.FormDataSettingsStorageLoad(
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
// See Common.FormDataSettingsStorageDelete
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
	
	Common.FormDataSettingsStorageDelete(ObjectKey, SettingsKey, UserName);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region Styles

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonClient.StyleColor
Function StyleColor(Val StyleColorName) Export
	
	Return StyleColors[StyleColorName];
	
EndFunction

// See CommonClient.StyleFont
Function StyleFont(Val StyleFontName) Export
	
	Return StyleFonts[StyleFontName];
	
EndFunction

#EndRegion

#EndRegion
