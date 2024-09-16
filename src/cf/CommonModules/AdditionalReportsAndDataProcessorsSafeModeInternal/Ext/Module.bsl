///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the security profile name template for the external module.
// The function must return the same value when called multiple times.
//
// Parameters:
//  ExternalModule - AnyRef -  a link to an external module.
//
// Returns:
//   String - 
//  
//
Function SecurityProfileNameTemplate(Val ExternalModule) Export
	
	Kind = Common.ObjectAttributeValue(ExternalModule, "Kind");
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		
		Return "AdditionalReport_%1"; // 
		
	Else
		
		Return "AdditionalDataProcessor_%1"; // 
		
	EndIf;
	
EndFunction

// Returns an icon displaying the external module.
//
// Parameters:
//  ExternalModule - AnyRef -  link to the external module
//
// Returns:
//   Picture
//
Function ExternalModuleIcon(Val ExternalModule) Export
	
	Kind = Common.ObjectAttributeValue(ExternalModule, "Kind");
	If Kind = Enums.AdditionalReportsAndDataProcessorsKinds.Report Or Kind = Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport Then
		
		Return PictureLib.Report;
		
	Else
		
		Return PictureLib.DataProcessor;
		
	EndIf;
	
EndFunction

// Returns a dictionary of views for the container's external modules.
//
// Returns:
//   Structure:
//   * Nominative - String -  representation of the external module type in the nominative case,
//   * Genitive - String -  representation of the external module type in the genitive case.
//
Function ExternalModuleContainerDictionary() Export
	
	Result = New Structure();
	
	Result.Insert("Nominative", NStr("en = 'Additional report or data processor';"));
	Result.Insert("Genitive", NStr("en = 'Additional report or data processor';"));
	
	Return Result;
	
EndFunction

// Returns an array of metadata reference objects that can be used
//  as a container for external modules.
//
// Returns:
//   Array of MetadataObject
//
Function ExternalModulesContainers() Export
	
	Result = New Array();
	Result.Add(Metadata.Catalogs.AdditionalReportsAndDataProcessors);
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See SSLSubsystemsIntegration.OnRegisterExternalModulesManagers
Procedure OnRegisterExternalModulesManagers(Managers) Export
	
	Managers.Add(AdditionalReportsAndDataProcessorsSafeModeInternal);
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	NewRequests = AdditionalDataProcessorsPermissionRequests();
	CommonClientServer.SupplementArray(PermissionsRequests, NewRequests);
	
EndProcedure

#EndRegion

#Region Private

Function AdditionalDataProcessorsPermissionRequests(Val FOValue = Undefined)
	
	If FOValue = Undefined Then
		FOValue = GetFunctionalOption("UseAdditionalReportsAndDataProcessors");
	EndIf;
	
	Result = New Array();
	
	QueryText =
		"SELECT DISTINCT
		|	AdditionalReportsAndPermissionProcessing.Ref AS Ref
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors.Permissions AS AdditionalReportsAndPermissionProcessing
		|WHERE
		|	AdditionalReportsAndPermissionProcessing.Ref.Publication <> &Publication";
	Query = New Query(QueryText);
	Query.SetParameter("Publication", Enums.AdditionalReportsAndDataProcessorsPublicationOptions.isDisabled);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		Object = Selection.Ref.GetObject();
		NewRequests = AdditionalDataProcessorPermissionRequests(Object, FOValue);
		CommonClientServer.SupplementArray(Result, NewRequests);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//   Object - CatalogObject.AdditionalReportsAndDataProcessors
//   FOValue - Boolean
//              - Undefined
//   DeletionMark - Boolean
// Returns:
//   Array
//
Function AdditionalDataProcessorPermissionRequests(Val Object, Val FOValue = Undefined, Val DeletionMark = Undefined)
	
	PermissionsInData = Object.Permissions.Unload();
	PermissionsToRequest = New Array();
	
	If FOValue = Undefined Then
		FOValue = GetFunctionalOption("UseAdditionalReportsAndDataProcessors");
	EndIf;
	
	If DeletionMark = Undefined Then
		DeletionMark = Object.DeletionMark;
	EndIf;
	
	ClearPermissions1 = False;
	
	If Not FOValue Then
		ClearPermissions1 = True;
	EndIf;
	
	If Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.isDisabled Then
		ClearPermissions1 = True;
	EndIf;
	
	If DeletionMark Then
		ClearPermissions1 = True;
	EndIf;
	
	ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
	
	If Not ClearPermissions1 Then
		
		HadPermissions = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(Object.Ref) <> Undefined;
		HasPermissions1 = Object.Permissions.Count() > 0;
		
		If HadPermissions Or HasPermissions1 Then
			
			PermissionsToRequest = New Array();
			For Each PermissionInData In PermissionsInData Do
				Resolution = XDTOFactory.Create(XDTOFactory.Type(ModuleSafeModeManagerInternal.Package(), PermissionInData.PermissionKind));
				PropertiesInData = PermissionInData.Parameters.Get();
				FillPropertyValues(Resolution, PropertiesInData);
				PermissionsToRequest.Add(Resolution);
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return ModuleSafeModeManagerInternal.PermissionsRequestForExternalModule(Object.Ref, PermissionsToRequest);
	
EndFunction

#EndRegion