///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Returns the connection mode of the external module.
//
// Parameters:
//  ProgramModule - AnyRef -  the link corresponding to the software module for which
//    the connection mode is requested.
//
// Returns:
//   String - 
//  
//
Function ExternalModuleAttachmentMode(Val ProgramModule) Export
	
	If SafeModeManager.SafeModeSet() Then
		// 
		// 
		Return SafeMode();
	EndIf;
		
	SetPrivilegedMode(True);
	
	ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
	Query = New Query(
		"SELECT
		|	ExternalModulesAttachmentModes.SafeMode
		|FROM
		|	InformationRegister.ExternalModulesAttachmentModes AS ExternalModulesAttachmentModes
		|WHERE
		|	ExternalModulesAttachmentModes.ProgramModuleType = &ProgramModuleType
		|	AND ExternalModulesAttachmentModes.ModuleID = &ModuleID");
	
	Query.SetParameter("ProgramModuleType", ModuleProperties.Type);
	Query.SetParameter("ModuleID", ModuleProperties.Id);
	QuerySelection = Query.Execute().Select();
	If QuerySelection.Next() Then
		Result = QuerySelection.SafeMode;
	Else
		Result = Undefined;
	EndIf;
	
	SSLSubsystemsIntegration.OnAttachExternalModule(ProgramModule, Result);
	SafeModeManagerOverridable.OnAttachExternalModule(ProgramModule, Result);
	Return Result;
	
EndFunction

#EndRegion

#EndIf
