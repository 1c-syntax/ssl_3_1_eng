///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Determines the version of the 1C application:The company that is required to operate
// an Autonomous workplace. This version of the application must be installed on the user's local computer.
// If the return value of the function is not set, the
// default value will be used as the required application version: the first three digits of the version of the current application
// located on the Internet, for example, "8.3.3".
// Used in the offline workplace creation assistant.
//
// Parameters:
//  Version - String -  version of the required 1C application:Enterprises in the format
//	                  " < main version>.<younger version>.<release>.<additional release number>".
//	                  For example, "8.3.3.715".
//
Procedure OnDefineRequiredApplicationVersion(Version) Export
	
EndProcedure

// Called when the user starts creating an offline workplace.
// Event handlers can implement additional checks for the possibility
// of creating an Autonomous workplace (if it is not possible, an exception is generated).
//
Procedure OnCreateStandaloneWorkstation() Export
	
EndProcedure

#EndRegion