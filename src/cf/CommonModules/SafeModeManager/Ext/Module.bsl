///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

////////////////////////////////////////////////////////////////////////////////
// 
//

// Returns an internal description of the permission to use the file system directory.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  Address - String -  address of the file system resource,
//  DataReader - Boolean -  specifies the need to grant permission
//                          to read data from this file system directory.
//  DataWriter - Boolean -  specifies the need to grant permission
//                          to write data to the specified directory of the file system.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject 
//
Function PermissionToUseFileSystemDirectory(Val Address, Val DataReader = False, Val DataWriter = False, Val LongDesc = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "FileSystemAccess"));
	Result.Description = LongDesc;
	
	If StrEndsWith(Address, "\") Or StrEndsWith(Address, "/") Then
		Address = Left(Address, StrLen(Address) - 1);
	EndIf;
	
	Result.Path = Address;
	Result.AllowedRead = DataReader;
	Result.AllowedWrite = DataWriter;
	
	Return Result;
	
EndFunction

// Returns an internal description of the permission to use the temporary files directory.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  DataReader - Boolean -  indicates the need to grant permission
//                          to read data from the temporary files directory.
//  DataWriter - Boolean -  indicates the need to grant permission
//                          to write data to the temporary files directory.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToUseTempDirectory(Val DataReader = False, Val DataWriter = False, Val LongDesc = "") Export
	
	Return PermissionToUseFileSystemDirectory(TempDirectoryAlias(), DataReader, DataWriter);
	
EndFunction

// Returns an internal description of the permission to use the program directory.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  DataReader - Boolean -  indicates the need to grant permission
//                          to read data from the program directory.
//  DataWriter - Boolean -  indicates the need to grant permission
//                          to write data to the program directory.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToUseApplicationDirectory(Val DataReader = False, Val DataWriter = False, Val LongDesc = "") Export
	
	Return PermissionToUseFileSystemDirectory(ApplicationDirectoryAlias(), DataReader, DataWriter);
	
EndFunction

// Returns an internal description of the permission to use the COM class.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  ProgID - String -  The ProgID of the COM class with which it is registered in the system.
//                    For example, "Excel.Application".
//  CLSID - String -  The CLSID of the COM class with which it is registered in the system.
//  ComputerName - String -  the name of the computer on which to create the specified object.
//                           If not specified, the object will be created on the computer where
//                           the current workflow is running.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToCreateCOMClass(Val ProgID, Val CLSID, Val ComputerName = "", Val LongDesc = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "CreateComObject"));
	Result.Description = LongDesc;
	
	Result.ProgId = ProgID;
	Result.CLSID = String(CLSID);
	Result.ComputerName = ComputerName;
	
	Return Result;
	
EndFunction

// Returns an internal description of the permission to use an external component supplied
// in the general configuration layout.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  TemplateName - String -  the name of the general layout in the configuration in which the external component is supplied.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToUseAddIn(Val TemplateName, Val LongDesc = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "AttachAddin"));
	Result.Description = LongDesc;
	
	Result.TemplateName = TemplateName;
	
	Return Result;
	
EndFunction

// Returns an internal description of the permission to use the configuration extension.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  Name - String -  name of the configuration extension.
//  Checksum - String -  checksum of the configuration extension.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToUseExternalModule(Val Name, Val Checksum, Val LongDesc = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "ExternalModule"));
	Result.Description = LongDesc;
	
	Result.Name = Name;
	Result.Hash = Checksum;
	
	Return Result;
	
EndFunction

// Returns an internal description of the permission to use the operating system application.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  CommandLinePattern - String -  template of the application launch string.
//                                 For more information, see the platform documentation.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToUseOperatingSystemApplications(Val CommandLinePattern, Val LongDesc = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "RunApplication"));
	Result.Description = LongDesc;
	
	Result.CommandMask = CommandLinePattern;
	
	Return Result;
	
EndFunction

// Returns an internal description of the permission to use the Internet resource.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  Protocol - String - :
//                      
//  Address - String -  resource address without specifying the Protocol.
//  Port - Number -  the number of the port that is used to communicate with the resource.
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToUseInternetResource(Val Protocol, Val Address, Val Port = Undefined, Val LongDesc = "") Export
	
	If Port = Undefined Then
		StandardPorts = StandardInternetProtocolPorts();
		If StandardPorts.Property(Upper(Protocol)) <> Undefined Then
			Port = StandardPorts[Upper(Protocol)];
		EndIf;
	EndIf;
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "InternetResourceAccess"));
	Result.Description = LongDesc;
	
	Result.Protocol = Protocol;
	Result.Host = Address;
	Result.Port = Port;
	
	Return Result;
	
EndFunction

// Returns an internal description of the permission to work with extended data (including the installation
// of privileged mode) for external modules.
// To pass as a parameter in the function:
// Work in a safe mode.Request the use of external resources and
// work in a secure mode.Request to change the permission to use the external resources.
//
// Parameters:
//  LongDesc - String -  description of the reason why permission is required.
//
// Returns:
//  XDTODataObject
//
Function PermissionToUsePrivilegedMode(Val LongDesc = "") Export
	
	Package = SafeModeManagerInternal.Package();
	Result = XDTOFactory.Create(XDTOFactory.Type(Package, "ExternalModulePrivilegedModeAllowed"));
	Result.Description = LongDesc;
	
	Return Result;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
//

// Creates a request to use external resources.
//
// Parameters:
//  NewPermissions - Array of See SafeModeManager.PermissionToUseExternalModule 
//                  - Array of See SafeModeManager.PermissionToUseAddIn  
//                  - Array of See SafeModeManager.PermissionToUseInternetResource  
//                  - Array of See SafeModeManager.PermissionToUseTempDirectory  
//                  - Array of See SafeModeManager.PermissionToUseApplicationDirectory  
//                  - Array of See SafeModeManager.PermissionToUseFileSystemDirectory  
//                  - Array of See SafeModeManager.PermissionToUsePrivilegedMode  
//					- Array of See SafeModeManager.PermissionToUseOperatingSystemApplications - 
//					  
//  Owner - AnyRef -  a reference to the object of the information base with which the requested
//    permissions are logically linked. For example, all permissions to access directories of file storage volumes are logically linked
//    to the corresponding elements of the directory of file storage volumes, all permissions to access
//    data exchange directories (or other resources, depending on the exchange transport used) are logically
//    linked to the corresponding nodes of exchange plans, etc. In the event that the permission is logically
//    separate (for example, the granting of permission is regulated by the value of a constant with the Boolean type), it is
//    recommended to use a reference to an element of the directory of identifiers of Data objects.
//  ReplacementMode - Boolean -  defines the mode for replacing previously issued permissions for this owner. If
//    the parameter is set to True, in addition to granting the requested permissions, the request will
//    clear all permissions previously requested for the same owner.
//
// Returns:
//  UUID -  
//     
//    
//
Function RequestToUseExternalResources(Val NewPermissions, Val Owner = Undefined, Val ReplacementMode = True) Export
	
	Return SafeModeManagerInternal.PermissionChangeRequest(
		Owner,
		ReplacementMode,
		NewPermissions);
	
EndFunction

// Creates a request to revoke permissions to use external resources.
//
// Parameters:
//  Owner - AnyRef -  a reference to an object in the information database that the revoked
//    permissions are logically associated with. For example, all permissions to access file storage volume directories are logically linked
//    to the corresponding items in the file Storage directory, all permissions to access
//    data exchange directories (or other resources, depending on the exchange transport used) are logically
//    linked to the corresponding exchange plan nodes, and so on. If the permission is logically
//    separate (for example, revoked permissions are regulated by the value of a constant with the Boolean type), it is
//    recommended to use a reference to the element of the reference list of object IDs of Metadata.
//  PermissionsToCancel - Array of See SafeModeManager.PermissionToUseExternalModule 
//                       - Array of See SafeModeManager.PermissionToUseAddIn  
//                       - Array of See SafeModeManager.PermissionToUseInternetResource  
//                       - Array of See SafeModeManager.PermissionToUseTempDirectory  
//                       - Array of See SafeModeManager.PermissionToUseApplicationDirectory  
//                       - Array of See SafeModeManager.PermissionToUseFileSystemDirectory  
//                       - Array of See SafeModeManager.PermissionToUsePrivilegedMode  
//					- Array of See SafeModeManager.PermissionToUseOperatingSystemApplications - 
//					  
//
// Returns:
//  UUID - 
//     
//    
//
Function RequestToCancelPermissionsToUseExternalResources(Val Owner, Val PermissionsToCancel) Export
	
	Return SafeModeManagerInternal.PermissionChangeRequest(
		Owner,
		False,
		,
		PermissionsToCancel);
	
EndFunction

// Creates a request to revoke all permissions to use external resources associated with the owner.
//
// Parameters:
//  Owner - AnyRef -  a reference to an object in the information database that the revoked
//    permissions are logically associated with. For example, all permissions to access file storage volume directories are logically linked
//    to the corresponding items in the file Storage directory, all permissions to access
//    data exchange directories (or other resources, depending on the exchange transport used) are logically
//    linked to the corresponding exchange plan nodes, and so on. If the permission is logically
//    separate (for example, revoked permissions are regulated by the value of a constant with the Boolean type), it is
//    recommended to use a reference to the element of the reference list of object IDs of Metadata.
//
// Returns:
//  UUID - 
//     
//    
//
Function RequestToClearPermissionsToUseExternalResources(Val Owner) Export
	
	Return SafeModeManagerInternal.PermissionChangeRequest(
		Owner,
		True);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 
// 
//

// They will check that safe mode is set, ignoring the safe mode of the security profile
//  that is used as a security profile with the configuration privilege level.
//
// Returns:
//   Boolean - 
//
Function SafeModeSet() Export
	
	CurrentSafeMode = SafeMode();
	
	If TypeOf(CurrentSafeMode) = Type("String") Then
		
		If Not SwichingToPrivilegedModeAvailable() Then
			Return True; // 
		EndIf;
		
		Try
			InfobaseProfile = InfobaseSecurityProfile();
		Except
			Return True;
		EndTry;
		
		Return (CurrentSafeMode <> InfobaseProfile);
		
	ElsIf TypeOf(CurrentSafeMode) = Type("Boolean") Then
		
		Return CurrentSafeMode;
		
	EndIf;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Other
//

// Creates requests to update configuration permissions.
//
// Parameters:
//  IncludingIBProfileCreationRequest - Boolean -  include a request to create a security profile
//    for the current database in the result.
//
// Returns:
//  Array - 
//           
//
Function RequestsToUpdateApplicationPermissions(Val IncludingIBProfileCreationRequest = True) Export
	
	Return SafeModeManagerInternal.RequestsToUpdateApplicationPermissions(IncludingIBProfileCreationRequest);
	
EndFunction

// Returns checksums of the external component kit files that are supplied in the configuration layout.
//
// Parameters:
//   TemplateName - String -  name of the configuration layout that the external component kit is supplied with.
//
// Returns:
//   FixedMap of KeyAndValue - :
//     * Key - String -  file name,
//     * Value - String -  checksum.
//
Function AddInBundleFilesChecksum(Val TemplateName) Export
	
	Return SafeModeManagerInternal.AddInBundleFilesChecksum(TemplateName);
	
EndFunction

#EndRegion

#Region Internal

Function UseSecurityProfiles() Export
	Return GetFunctionalOption("UseSecurityProfiles");
EndFunction

// Returns the name of the security profile that grants configuration code privileges.
//
// Returns:
//   String
//
Function InfobaseSecurityProfile(CheckForUsage = False) Export
	
	If CheckForUsage And Not GetFunctionalOption("UseSecurityProfiles") Then
		Return "";
	EndIf;
	
	SetPrivilegedMode(True);
	
	SecurityProfile = Constants.InfobaseSecurityProfile.Get();
	
	If SecurityProfile = False Then
		Return "";
	EndIf;
	
	Return SecurityProfile;
	
EndFunction

#EndRegion

#Region Private

// Checks whether it is possible to switch to privileged mode from the current safe mode.
//
// Returns:
//   Boolean
//
Function SwichingToPrivilegedModeAvailable()
	
	SetPrivilegedMode(True);
	Return PrivilegedMode();
	
EndFunction

// Returns a "predefined" alias for the program directory.
//
// Returns:
//   String
//
Function ApplicationDirectoryAlias()
	
	Return "/bin";
	
EndFunction

// Returns a "predefined" alias for the temporary file directory.
//
Function TempDirectoryAlias()
	
	Return "/temp";
	
EndFunction

// Returns standard network ports for Internet protocols, tools for using which
// are available in the built-in 1C language:Companies. Used to determine the network port
// when permission is requested from the application code without specifying the network port.
//
// Returns:
//   FixedStructure:
//    * IMAP - Number - 143. 
//    * POP3 - Number - 110.
//    * SMTP - Number - 25.
//    * HTTP - Number - 80.
//    * HTTPS - Number - 443.
//    * FTP - Number - 21.
//    * FTPS - Number - 21.
//    * WS - Number - 80.
//    * WSS - Number - 443.
//
Function StandardInternetProtocolPorts()
	
	Result = New Structure();
	
	Result.Insert("IMAP",  143);
	Result.Insert("POP3",  110);
	Result.Insert("SMTP",  25);
	Result.Insert("HTTP",  80);
	Result.Insert("HTTPS", 443);
	Result.Insert("FTP",   21);
	Result.Insert("FTPS",  21);
	Result.Insert("WS",    80);
	Result.Insert("WSS",   443);
	
	Return New FixedStructure(Result);
	
EndFunction

#EndRegion

