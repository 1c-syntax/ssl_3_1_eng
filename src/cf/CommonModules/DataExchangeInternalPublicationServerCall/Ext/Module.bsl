///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function SettingFlagShouldMutePromptToMigrateToWebService(SettingObject1, Value = Undefined) Export
	
	If TypeOf(SettingObject1) = Type("String") Then
		Var_Key = "ShouldMutePromptToMigrateToWebService" + SettingObject1;
	Else
		Var_Key = "ShouldMutePromptToMigrateToWebService" + SettingObject1.UUID();
	EndIf;
	
	If Value = Undefined Then
		// Read
		Return Common.CommonSettingsStorageLoad("ApplicationSettings", Var_Key, False,, UserName());
	EndIf;
	
	SettingsDescription = NStr("en = 'Do not offer to switch to a web service';");
	
	// Record
	Common.CommonSettingsStorageSave("ApplicationSettings", Var_Key, Value, SettingsDescription, UserName());
	
EndFunction

#EndRegion