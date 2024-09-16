///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Checks whether security profiles can be configured from the current database.
//
// Returns: 
//   Boolean - 
//
Function CanSetUpSecurityProfiles() Export
	
	If SecurityProfilesUsageAvailable() Then
		
		Cancel = False;
		
		SSLSubsystemsIntegration.OnCheckCanSetupSecurityProfiles(Cancel);
		If Not Cancel Then
			SafeModeManagerOverridable.OnCheckCanSetupSecurityProfiles(Cancel);
		EndIf;
		
		Return Not Cancel;
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

// Returns the connection mode of the external module.
//
// Parameters:
//  ExternalModule - AnyRef -  the link corresponding to the external module for which
//    the connection mode is requested.
//
// Returns:
//   String - 
//  
//
Function ExternalModuleAttachmentMode(Val ExternalModule) Export
	
	Return InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(ExternalModule);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

// Returns the URI of the XDTO package namespace that is used to describe permissions
// in security profiles.
//
// Returns:
//   String
//
Function Package() Export
	
	Return Metadata.XDTOPackages.ApplicationPermissions_1_0_0_2.Namespace;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

// Creates requests to use external resources for an external module.
//
// Parameters:
//  ProgramModule - AnyRef -  the link corresponding to the external module for which permissions are requested.
//  NewPermissions - Array of XDTODataObject -  internal descriptions of the requested permissions to access external resources.
//    It is assumed that all the XDTO objects passed as a parameter 
//    are formed by calling functions in a safe mode.Permission*().
//    When requesting permissions for external modules, permissions are always added in replacement mode.
//
// Returns:
//   Array of UUID - 
//
Function PermissionsRequestForExternalModule(Val ProgramModule, Val NewPermissions = Undefined) Export
	
	Result = New Array();
	
	If NewPermissions = Undefined Then
		NewPermissions = New Array();
	EndIf;
	
	If NewPermissions.Count() > 0 Then
		
		// 
		If ExternalModuleAttachmentMode(ProgramModule) = Undefined Then
			Result.Add(RequestForSecurityProfileCreation(ProgramModule));
		EndIf;
		
		Result.Add(
			PermissionChangeRequest(
				ProgramModule, True, NewPermissions, Undefined, ProgramModule));
		
	Else
		
		// 
		If ExternalModuleAttachmentMode(ProgramModule) <> Undefined Then
			Result.Add(RequestToDeleteSecurityProfile(ProgramModule));
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

////////////////////////////////////////////////////////////////////////////////
// 
// 
//
// 
// 
// 
//

// Generates the parameters for storing the references in the registers of the permits.
//
// Parameters:
//  Ref - AnyRef
//
// Returns:
//   Structure:
//                        * Type - CatalogRef.MetadataObjectIDs,
//                        * Id - UUID -  unique
//                           link ID.
//
Function PropertiesForPermissionRegister(Val Ref) Export
	
	Result = New Structure("Type,Id");
	
	If Ref = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result.Type = Catalogs.MetadataObjectIDs.EmptyRef();
		Result.Id = CommonClientServer.BlankUUID();
		
	Else
		
		Result.Type = Common.MetadataObjectID(Ref.Metadata());
		Result.Id = Ref.UUID();
		
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

Function PermissionsToUseExternalResourcesPresentation(Val ProgramModuleType, 
	Val ModuleID, Val OwnerType, Val OwnerID, Val Permissions) Export
	
	// 
	// 
	// 
	
	BeginTransaction();
	Try
		Manager = DataProcessors.ExternalResourcesPermissionsSetup.Create();
		
		Manager.AddRequestForPermissionsToUseExternalResources(
			ProgramModuleType,
			ModuleID,
			OwnerType,
			OwnerID,
			True,
			Permissions,
			New Array());
		
		Manager.CalculateRequestsApplication();
		
		RollbackTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// 
	
	Return Manager.Presentation(True);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters, BeforeUpdateApplicationRunParameters = False) Export
	
	If BeforeUpdateApplicationRunParameters Then
		Parameters.Insert("DisplayPermissionSetupAssistant", False);
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("DisplayPermissionSetupAssistant", InteractivePermissionRequestModeUsed());
	If Not Parameters.DisplayPermissionSetupAssistant Then
		Return;
	EndIf;	
	
	If Not Users.IsFullUser() Then
		Return;
	EndIf;	
			
	Validation = ExternalResourcesPermissionsSetupServerCall.CheckApplyPermissionsToUseExternalResources();
	If Validation.CheckResult Then
		Parameters.Insert("CheckExternalResourceUsagePermissionsApplication", False);
	Else
		Parameters.Insert("CheckExternalResourceUsagePermissionsApplication", True);
		Parameters.Insert("PermissionsToUseExternalResourcesApplicabilityCheck", Validation);
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters
Procedure OnAddClientParameters(Parameters) Export
	
	SetPrivilegedMode(True);
	Parameters.Insert("DisplayPermissionSetupAssistant", InteractivePermissionRequestModeUsed());
	
EndProcedure


// See ReportsOptionsOverridable.CustomizeReportsOptions.
Procedure OnSetUpReportsOptions(Settings) Export
	ModuleReportsOptions = Common.CommonModule("ReportsOptions");
	ModuleReportsOptions.CustomizeReportInManagerModule(Settings, Metadata.Reports.ExternalResourcesInUse);
EndProcedure

#EndRegion

#Region Private

// Creates a request to create a security profile for an external module.
// For internal use only.
//
// Parameters:
//  External Module-Any link-the link corresponding to the external module for which
//    permissions are requested. (Undefined when requesting permissions for configuration, not for external modules).
//
// Returns:
//   UUID - 
//
Function RequestForSecurityProfileCreation(Val ProgramModule)
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.SecurityProfileAdministrativeOperations.Creating;
	
	SSLSubsystemsIntegration.OnRequestToCreateSecurityProfile(
		ProgramModule, StandardProcessing, Result);
	
	If StandardProcessing Then
		SafeModeManagerOverridable.OnRequestToCreateSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionAdministrationRequest(
			ProgramModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

// Checks whether security profiles can be used for the current database.
//
// Returns:
//   Boolean
//
Function SecurityProfilesUsageAvailable() Export
	
	If Common.FileInfobase(InfoBaseConnectionString()) Then
		Return False;
	EndIf;
	
	Cancel = False;
	
	SafeModeManagerOverridable.OnCheckSecurityProfilesUsageAvailability(Cancel);
	
	Return Not Cancel;
	
EndFunction

// Returns checksums of the external component kit files that are supplied in the configuration layout.
//
// Parameters:
//  TemplateName - String -  name of the configuration layout that the external component kit is supplied with.
//
// Returns:
//   FixedMap of KeyAndValue:
//                         * Key - String -  file name,
//                         * Value - String -  checksum.
//
Function AddInBundleFilesChecksum(Val TemplateName) Export
	
	Result = New Map();
	
	NameStructure = StrSplit(TemplateName, ".");
	
	If NameStructure.Count() = 2 Then
		
		// 
		Template = GetCommonTemplate(NameStructure[1]);
		
	ElsIf NameStructure.Count() = 4 Then
		
		// 
		ObjectManager = Common.ObjectManagerByFullName(NameStructure[0] + "." + NameStructure[1]);
		Template = ObjectManager.GetTemplate(NameStructure[3]);
		
	Else
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot generate a permission to use the add-in:
				  |incorrect name of the %1 template.';"), TemplateName);
	EndIf;
	
	If Template = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot create a permission to use the add-in supplied in the template %1:
				  | Template %1 is not found in the configuration.';"), TemplateName);
	EndIf;
	
	TemplateType = Metadata.FindByFullName(TemplateName).TemplateType;
	If TemplateType <> Metadata.ObjectProperties.TemplateType.BinaryData And TemplateType <> Metadata.ObjectProperties.TemplateType.AddIn Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot generate a permission to use the add-in:
				  |the %1 template does not contain binary data.';"), TemplateName);
	EndIf;
	
	TempFile = GetTempFileName("zip");
	Template.Write(TempFile);
	
	Archiver = New ZipFileReader(TempFile);
	UnpackDirectory = GetTempFileName() + "\";
	CreateDirectory(UnpackDirectory);
	
	ManifestFile = "";
	For Each ArchiveItem In Archiver.Items Do
		If Upper(ArchiveItem.Name) = "MANIFEST.XML" Then
			ManifestFile = UnpackDirectory + ArchiveItem.Name;
			Archiver.Extract(ArchiveItem, UnpackDirectory);
		EndIf;
	EndDo;
	
	If IsBlankString(ManifestFile) Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot create a permission to use the add-in supplied in the template %1:
				  |The archive does not contain the MANIFEST.XML file.';"), TemplateName);
	EndIf;
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(ManifestFile);
	BundleDetails = XDTOFactory.ReadXML(ReaderStream, XDTOFactory.Type("http://v8.1c.ru/8.2/addin/bundle", "bundle"));
	For Each ComponentDetails In BundleDetails.component Do
		
		If ComponentDetails.type = "native" Or ComponentDetails.type = "com" Then
			
			ComponentFile = UnpackDirectory + ComponentDetails.path;
			
			Archiver.Extract(Archiver.Items.Find(ComponentDetails.path), UnpackDirectory);
			
			Hashing = New DataHashing(HashFunction.SHA1);
			Hashing.AppendFile(ComponentFile);
			Result.Insert(ComponentDetails.path, Base64String(Hashing.HashSum));
			
		EndIf;
		
	EndDo;
	
	ReaderStream.Close();
	Archiver.Close();
	
	Try
		DeleteFiles(UnpackDirectory);
	Except
		WriteLogEvent(NStr("en = 'Safe mode manager.Cannot create temporary file';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Try
		DeleteFiles(TempFile);
	Except
		WriteLogEvent(NStr("en = 'Safe mode manager.Cannot create temporary file';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return New FixedMap(Result);
	
EndFunction

// Creates a link from the data stored in the registers of the permits.
//
// Parameters:
//  Type - CatalogRef.MetadataObjectIDs
//  Id - UUID -  unique link ID.
//
// Returns:
//   AnyRef
//
Function ReferenceFormPermissionRegister(Val Type, Val Id) Export
	
	If Type = Catalogs.MetadataObjectIDs.EmptyRef() Then
		Return Type;
	EndIf;
		
	MetadataObject = Common.MetadataObjectByID(Type);
	Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
	
	If IsBlankString(Id) Then
		Return Manager.EmptyRef();
	Else
		Return Manager.GetRef(Id);
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

// Creates a request to change permissions for using external resources.
// For internal use only.
//
// Parameters:
//  Owner - AnyRef -  owner of permissions to use external resources.
//    (Undefined when requesting permissions for configuration, not for configuration objects).
//  ReplacementMode - Boolean -  the mode of substitution of previously granted permissions for the owner.
//  PermissionsToAdd - Array of XDTODataObject -  array of xdto Objects corresponding to the internal descriptions
//    of the requested permissions to access external resources. It is assumed that all xdto Objects passed
//    as a parameter are formed by calling functions in the safe mode.Permission*().
//  PermissionsToDelete - Array of XDTODataObject -  array of xdto Objects that correspond to internal descriptions
//    of revoked permissions to access external resources. It is assumed that all xdto Objects passed
//    as a parameter are formed by calling functions in the safe mode.Permission*().
//  ProgramModule - AnyRef -  the link corresponding to the external module for which
//    permissions are requested. (Undefined when requesting permissions for configuration, not for external modules).
//
// Returns:
//   UUID - 
//
Function PermissionChangeRequest(Val Owner, Val ReplacementMode, Val PermissionsToAdd = Undefined, 
	Val PermissionsToDelete = Undefined, Val ProgramModule = Undefined) Export
	
	StandardProcessing = True;
	Result = Undefined;
	
	SSLSubsystemsIntegration.OnRequestPermissionsToUseExternalResources(
			ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
	
	If StandardProcessing Then
		
		SafeModeManagerOverridable.OnRequestPermissionsToUseExternalResources(
			ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete, StandardProcessing, Result);
		
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.RequestToUsePermissions(
			ProgramModule, Owner, ReplacementMode, PermissionsToAdd, PermissionsToDelete);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates a request to delete the security profile for the external module.
// For internal use only.
//
// Parameters:
//  ProgramModule - AnyRef -  the link corresponding to the external module for which
//    permissions are requested. (Undefined when requesting permissions for configuration, not for external modules).
//
// Returns:
//   UUID - 
//
Function RequestToDeleteSecurityProfile(Val ProgramModule) Export
	
	StandardProcessing = True;
	Result = Undefined;
	Operation = Enums.SecurityProfileAdministrativeOperations.Delete;
	
	SSLSubsystemsIntegration.OnRequestToDeleteSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	
	If StandardProcessing Then
		SafeModeManagerOverridable.OnRequestToDeleteSecurityProfile(
			ProgramModule, StandardProcessing, Result);
	EndIf;
	
	If StandardProcessing Then
		
		Result = InformationRegisters.RequestsForPermissionsToUseExternalResources.PermissionAdministrationRequest(
			ProgramModule, Operation);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates requests to update configuration permissions.
//
// Parameters:
//  IncludingIBProfileCreationRequest - Boolean -  include a request to create a security profile
//    for the current database in the result.
//
// Returns: 
//   Array of UUID - 
//                                       
//
Function RequestsToUpdateApplicationPermissions(Val IncludingIBProfileCreationRequest = True) Export
	
	Result = New Array();
	
	BeginTransaction();
	Try
		If IncludingIBProfileCreationRequest Then
			Result.Add(RequestForSecurityProfileCreation(Catalogs.MetadataObjectIDs.EmptyRef()));
		EndIf;
		
		FillPermissionsToUpdatesProtectionCenter(Result);
		SSLSubsystemsIntegration.OnFillPermissionsToAccessExternalResources(Result);
		SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources(Result);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return Result;
	
EndFunction

Procedure FillPermissionsToUpdatesProtectionCenter(PermissionsRequests)
	
	Resolution = SafeModeManager.PermissionToUseInternetResource("HTTPS", "1cv8update.com",, 
		NStr("en = 'The ""Update protection center"" (UPC) site for checking legitimacy of the software usage and updating.';"));
	Permissions = New Array;
	Permissions.Add(Resolution);
	PermissionsRequests.Add(SafeModeManager.RequestToUseExternalResources(Permissions));

EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 
//

// Returns a software module that performs the functions of an external module manager.
//
// Parameters:
//  ExternalModule - AnyRef -  the link corresponding to the external module for which the manager is requested.
//
// Returns:
//   CommonModule
//
Function ExternalModuleManager(Val ExternalModule) Export
	
	Managers = ExternalModulesManagers();
	For Each Manager In Managers Do
		ManagerContainers = Manager.ExternalModulesContainers();
		
		If TypeOf(ExternalModule) = Type("CatalogRef.MetadataObjectIDs") Then
			MetadataObject = Common.MetadataObjectByID(ExternalModule);
		Else
			MetadataObject = ExternalModule.Metadata();
		EndIf;
		
		If ManagerContainers.Find(MetadataObject) <> Undefined Then
			Return Manager;
		EndIf;
	EndDo;
	
	Return Undefined;
	
EndFunction

// The procedure must be called when writing any service data
// that cannot be changed when safe mode is set.
//
Procedure OnSaveInternalData(Object) Export
	
	If SafeModeManager.SafeModeSet() Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Couldn''t save %1. Safe mode is set: %2.';"),
			Object.Metadata().FullName(),
			SafeMode());
		
	EndIf;
	
EndProcedure

// Checks whether to use interactive mode for requesting permissions.
//
// Returns:
//   Boolean
//
Function InteractivePermissionRequestModeUsed()
	
	If SecurityProfilesUsageAvailable() Then
		
		Return GetFunctionalOption("UseSecurityProfiles") And Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get();
		
	Else
		
		Return False;
		
	EndIf;
	
EndFunction

// Returns an array of directory managers that are containers of external modules.
//
// Returns:
//   Array of CatalogManager
//
Function ExternalModulesManagers()
	
	Managers = New Array;
	
	SSLSubsystemsIntegration.OnRegisterExternalModulesManagers(Managers);
	
	Return Managers;
	
EndFunction

#EndRegion
