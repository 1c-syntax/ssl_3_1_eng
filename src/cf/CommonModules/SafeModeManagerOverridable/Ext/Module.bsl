///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Called when checking whether security profiles can be used.
//
// Parameters:
//  Cancel - Boolean -  if the configuration is not adapted to the use
//   of security profiles, the parameter value in this procedure must
//   be set to True.
//
Procedure OnCheckSecurityProfilesUsageAvailability(Cancel) Export
	
	
	
EndProcedure

// Called when checking whether security profiles can be configured.
//
// Parameters:
//  Cancel - Boolean -  if the use of security profiles is not available for the information database
//    , set this parameter to True.
//
Procedure OnCheckCanSetupSecurityProfiles(Cancel) Export
	
	
	
EndProcedure

// Called when enabling the use of security profiles for the information database.
//
Procedure OnEnableSecurityProfiles() Export
	
	
	
EndProcedure

// Fills in the list of requests for external permissions that must be provided
// when creating an information database or updating the program.
//
// Parameters:
//  PermissionsRequests - Array of See SafeModeManager.RequestToUseExternalResources
//
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
EndProcedure

// Called when creating a request for permissions to use external resources.
//
// Parameters:
//  ProgramModule - AnyRef -  a reference to an information database object that represents the software
//    module that is being requested for permissions,
//  Owner - AnyRef -  reference to an information database object that represents the owner of the requested
//    permissions to use external resources,
//  ReplacementMode - Boolean -  flag for replacing previously granted permissions by owner,
//  PermissionsToAdd - Array -  array of xdto Objects to add permissions to,
//  PermissionsToDelete - Array -  array of xdto Object permissions to delete,
//  StandardProcessing - Boolean -  flag for performing standard processing for creating a request to use
//    external resources.
//  Result - UUID -  the ID of the request (in that case, if inside the handler
//    the value of the standard Processing parameter is set to False).
//
Procedure OnRequestPermissionsToUseExternalResources(Val ProgramModule, Val Owner, Val ReplacementMode, 
	Val PermissionsToAdd, Val PermissionsToDelete, StandardProcessing, Result) Export
	
	
	
EndProcedure

// Called when requesting the creation of a security profile.
//
// Parameters:
//  ProgramModule - AnyRef -  a reference to an information database object that represents the software
//    module that is being requested for permissions,
//  StandardProcessing - Boolean -  flag for performing standard processing,
//  Result - UUID -  the ID of the request (in that case, if inside the handler
//    the value of the standard Processing parameter is set to False).
//
Procedure OnRequestToCreateSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	
	
EndProcedure

// Called when a request is made to delete a security profile.
//
// Parameters:
//  ProgramModule - AnyRef -  a reference to an information database object that represents the software
//    module that is being requested for permissions,
//  StandardProcessing - Boolean -  flag for performing standard processing,
//  Result - UUID -  the ID of the request (in that case, if inside the handler
//    the value of the standard Processing parameter is set to False).
//
Procedure OnRequestToDeleteSecurityProfile(Val ProgramModule, StandardProcessing, Result) Export
	
	
	
EndProcedure

// Called when an external module is connected. In the body of the handler procedure, you can change
// the safe mode in which the connection will be performed.
//
// Parameters:
//  ExternalModule - AnyRef -  reference to the information base object that represents
//    the external plug-in,
//  SafeMode - DefinedType.SafeMode -  safe mode in which the external
//    module will be connected to the information database. Can be changed within this procedure.
//
Procedure OnAttachExternalModule(Val ExternalModule, SafeMode) Export
	
	
	
EndProcedure

#EndRegion