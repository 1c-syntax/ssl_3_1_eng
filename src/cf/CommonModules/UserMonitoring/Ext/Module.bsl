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
//
// Returns:
//  Boolean
//
Function ShouldRegisterDataAccess() Export
	
	Return UserMonitoringInternal.ShouldRegisterDataAccess();
	
EndFunction

// 
// 
//
// Parameters:
//  ShouldRegisterDataAccess - Boolean
//
Procedure SetDataAccessRegistration(ShouldRegisterDataAccess) Export
	
	UserMonitoringInternal.SetDataAccessRegistration(ShouldRegisterDataAccess);
	
EndProcedure

// 
// 
//
// Returns:
//  Structure:
//    * Content - Array of EventLogAccessEventUseDescription
//    * Comments - Map of KeyAndValue:
//        * Key     - String - 
//        * Value - String - 
//    * GeneralComment - String - 
//   
Function RegistrationSettingsForDataAccessEvents() Export
	
	Return UserMonitoringInternal.RegistrationSettingsForDataAccessEvents();
	
EndFunction

// 
// 
//
// Parameters:
//  Settings - See RegistrationSettingsForDataAccessEvents
//
Procedure SetRegistrationSettingsForDataAccessEvents(Settings) Export
	
	UserMonitoringInternal.SetRegistrationSettingsForDataAccessEvents(Settings);
	
EndProcedure

#EndRegion
