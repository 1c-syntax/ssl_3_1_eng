///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Creates a security profile administration request.
//
// Parameters:
//  ProgramModule - AnyRef -  a link that describes the software module
//    that the security profile is intended to connect to,
//  Operation - EnumRef.SecurityProfileAdministrativeOperations
//
// Returns:
//   UUID - 
//
Function PermissionAdministrationRequest(Val ProgramModule, Val Operation) Export
	
	If Not RequestForPermissionsToUseExternalResourcesRequired() Then
		Return New UUID();
	EndIf;
	
	If Operation = Enums.SecurityProfileAdministrativeOperations.Creating Then
		SecurityProfileName = NewSecurityProfileName(ProgramModule);
	Else
		SecurityProfileName = SecurityProfileName(ProgramModule);
	EndIf;
	
	Manager = CreateRecordManager();
	Manager.QueryID = New UUID();
	
	If SafeModeManager.SafeModeSet() Then
		Manager.SafeMode = SafeMode();
	Else
		Manager.SafeMode = False;
	EndIf;
	
	Manager.Operation = Operation;
	Manager.AdministrationRequest = True;
	Manager.Name = SecurityProfileName;
	
	ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
	Manager.ProgramModuleType = ModuleProperties.Type;
	Manager.ModuleID = ModuleProperties.Id;
	
	Manager.Write();
	
	RecordKey = CreateRecordKey(New Structure("QueryID", Manager.QueryID));
	LockDataForEdit(RecordKey);
	
	Return Manager.QueryID;
	
EndFunction

// Creates a request for permissions to use external resources.
//
// Parameters:
//  ProgramModule - AnyRef -  a link that describes the software module
//    that the security profile is intended to connect to,
//  Owner - AnyRef -  a reference to an object in the information database that the requested
//    permissions are logically associated with. For example, all permissions to access file storage volume directories are logically linked
//    to the corresponding items in the file Storage directory, all permissions to access
//    data exchange directories (or other resources, depending on the exchange transport used) are logically
//    linked to the corresponding exchange plan nodes, and so on. If the permission is logically
//    separate (for example, the granting of permission is regulated by the value of a constant with the Boolean type)
//    , we recommend using a reference to the element of the reference list of object IDs.,
//  ReplacementMode - Boolean -  defines the mode for replacing previously issued permissions for this owner. If
//    the parameter is set to True, in addition to granting the requested permissions, the request will
//    clear all permissions previously requested for the same owner.
//  PermissionsToAdd - Array of XDTODataObject -  array of xdto Objects corresponding to the internal descriptions
//    of the requested permissions to access external resources. It is assumed that all xdto Objects passed
//    as a parameter are formed by calling functions in the safe mode.Permission*().
//  PermissionsToDelete - Array of XDTODataObject -  array of xdto Objects that correspond to internal descriptions
//    of revoked permissions to access external resources. It is assumed that all xdto Objects passed
//    as a parameter are formed by calling functions in the safe mode.Permission*().
//
// Returns:
//   UUID - 
//
Function RequestToUsePermissions(Val ProgramModule, Val Owner, Val ReplacementMode, Val PermissionsToAdd, Val PermissionsToDelete) Export
	
	If Not RequestForPermissionsToUseExternalResourcesRequired() Then
		Return New UUID();
	EndIf;
	
	If Owner = Undefined Then
		Owner = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	If ProgramModule = Undefined Then
		ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef();
	EndIf;
	
	If SafeModeManager.SafeModeSet() Then
		SafeMode = SafeMode();
	Else
		SafeMode = False;
	EndIf;
	
	Manager = CreateRecordManager();
	Manager.QueryID = New UUID();
	Manager.AdministrationRequest = False;
	Manager.SafeMode = SafeMode;
	Manager.ReplacementMode = ReplacementMode;
	Manager.Operation = Enums.SecurityProfileAdministrativeOperations.RefreshEnabled;
	
	OwnerProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(Owner);
	Manager.OwnerType = OwnerProperties.Type;
	Manager.OwnerID = OwnerProperties.Id;
	
	ModuleProperties = SafeModeManagerInternal.PropertiesForPermissionRegister(ProgramModule);
	Manager.ProgramModuleType = ModuleProperties.Type;
	Manager.ModuleID = ModuleProperties.Id;
	
	If PermissionsToAdd <> Undefined Then
		
		PermissionsArray = New Array();
		For Each NewPermission In PermissionsToAdd Do
			PermissionsArray.Add(Common.XDTODataObjectToXMLString(NewPermission));
		EndDo;
		
		If PermissionsArray.Count() > 0 Then
			Manager.PermissionsToAdd = Common.ValueToXMLString(PermissionsArray);
		EndIf;
		
	EndIf;
	
	If PermissionsToDelete <> Undefined Then
		
		PermissionsArray = New Array();
		For Each PermissionToRevoke In PermissionsToDelete Do
			PermissionsArray.Add(Common.XDTODataObjectToXMLString(PermissionToRevoke));
		EndDo;
		
		If PermissionsArray.Count() > 0 Then
			Manager.PermissionsToDelete = Common.ValueToXMLString(PermissionsArray);
		EndIf;
		
	EndIf;
	
	Manager.Write();
	
	RecordKey = CreateRecordKey(New Structure("QueryID", Manager.QueryID));
	LockDataForEdit(RecordKey);
	
	Return Manager.QueryID;
	
EndFunction

// Creates and initializes the Manager for applying requests to use external resources.
//
// Parameters:
//  RequestsIDs - Array of UUID -  IDs of requests
//   that the Manager is being created to apply.
//
// Returns:
//   DataProcessorObject.ExternalResourcesPermissionsSetup
//
Function PermissionsApplicationManager(Val RequestsIDs) Export
	
	Manager = DataProcessors.ExternalResourcesPermissionsSetup.Create();
	
	QueryText =
		"SELECT
		|	PermissionsRequests.ProgramModuleType,
		|	PermissionsRequests.ModuleID,
		|	PermissionsRequests.OwnerType,
		|	PermissionsRequests.OwnerID,
		|	PermissionsRequests.Operation,
		|	PermissionsRequests.Name,
		|	PermissionsRequests.ReplacementMode,
		|	PermissionsRequests.PermissionsToAdd,
		|	PermissionsRequests.PermissionsToDelete,
		|	PermissionsRequests.QueryID
		|FROM
		|	InformationRegister.RequestsForPermissionsToUseExternalResources AS PermissionsRequests
		|WHERE
		|	PermissionsRequests.QueryID IN(&RequestsIDs)
		|
		|ORDER BY
		|	PermissionsRequests.AdministrationRequest DESC";
	Query = New Query(QueryText);
	Query.SetParameter("RequestsIDs", RequestsIDs);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordKey = CreateRecordKey(New Structure("QueryID", Selection.QueryID));
		LockDataForEdit(RecordKey);
		
		If Selection.Operation = Enums.SecurityProfileAdministrativeOperations.Creating
			Or Selection.Operation = Enums.SecurityProfileAdministrativeOperations.Delete Then
			
			Manager.AddRequestID(Selection.QueryID);
			
			Manager.AddAdministrationOperation(
				Selection.ProgramModuleType,
				Selection.ModuleID,
				Selection.Operation,
				Selection.Name);
			
		EndIf;
		
		PermissionsToAdd = New Array();
		If ValueIsFilled(Selection.PermissionsToAdd) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToAdd);
			
			For Each ArrayElement In Array Do
				PermissionsToAdd.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		PermissionsToDelete = New Array();
		If ValueIsFilled(Selection.PermissionsToDelete) Then
			
			Array = Common.ValueFromXMLString(Selection.PermissionsToDelete);
			
			For Each ArrayElement In Array Do
				PermissionsToDelete.Add(Common.XDTODataObjectFromXMLString(ArrayElement));
			EndDo;
			
		EndIf;
		
		Manager.AddRequestID(Selection.QueryID);
		
		Manager.AddRequestForPermissionsToUseExternalResources(
			Selection.ProgramModuleType,
			Selection.ModuleID,
			Selection.OwnerType,
			Selection.OwnerID,
			Selection.ReplacementMode,
			PermissionsToAdd,
			PermissionsToDelete);
		
	EndDo;
	
	Manager.CalculateRequestsApplication();
	
	Return Manager;
	
EndFunction

// Checks whether you need to interactively request permissions to use external resources.
//
// Returns:
//   Boolean
//
Function RequestForPermissionsToUseExternalResourcesRequired()
	
	If Not CanRequestForPermissionsToUseExternalResources() Then
		Return False;
	EndIf;
	
	Return Constants.UseSecurityProfiles.Get() And Constants.AutomaticallyConfigurePermissionsInSecurityProfiles.Get();
	
EndFunction

// Checks whether you can interactively request permissions to use external resources.
//
// Returns:
//   Boolean
//
Function CanRequestForPermissionsToUseExternalResources()
	
	If Common.FileInfobase(InfoBaseConnectionString()) Or Not GetFunctionalOption("UseSecurityProfiles") Then
		// 
		// 
		Return PrivilegedMode() Or Users.IsFullUser();
	Else
		// 
		// 
		If Not Users.IsFullUser() Then
			Raise(NStr("en = 'Insufficient access rights to request permissions to use external resources.';"),
				ErrorCategory.AccessViolation);
		EndIf;
		Return True;
	EndIf; 
	
EndFunction

// Returns the name of the security profile for the information base or external module.
//
// Parameters:
//  Externalmodule-any Link - a link to a reference list element that is used
//    as an external module.
//
// Returns: 
//   String -  name of the security profile.
//
Function SecurityProfileName(Val ProgramModule)
	
	If ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Return Constants.InfobaseSecurityProfile.Get();
		
	Else
		
		Return InformationRegisters.ExternalModulesAttachmentModes.ExternalModuleAttachmentMode(ProgramModule);
		
	EndIf;
	
EndFunction

// Generates the name of the security profile for the information base or external module.
//
// Parameters:
//   Externalmodule-any Link - a link to a reference list element that is used
//                                 as an external module.
//
// Returns: 
//   String -  name of the security profile.
//
Function NewSecurityProfileName(Val ProgramModule)
	
	If ProgramModule = Catalogs.MetadataObjectIDs.EmptyRef() Then
		
		Result = "Infobase_" + String(New UUID());
		
	Else
		
		ModuleManager = SafeModeManagerInternal.ExternalModuleManager(ProgramModule);
		Template = ModuleManager.SecurityProfileNameTemplate(ProgramModule);
		Return StrReplace(Template, "%1", String(New UUID()));
		
	EndIf;
	
	Return Result;
	
EndFunction

// Clears out-of-date requests to use external resources.
//
Procedure ClearObsoleteRequests() Export
	
	BeginTransaction();
	
	Try
		
		Selection = Select();
		
		While Selection.Next() Do
			
			Try
				
				Var_Key = CreateRecordKey(New Structure("QueryID", Selection.QueryID));
				LockDataForEdit(Var_Key);
				
			Except
				
				// 
				// 
				Continue;
				
			EndTry;
			
			Manager = CreateRecordManager();
			Manager.QueryID = Selection.QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Creates "empty" substitution requests for all previously granted permissions.
//
// Returns:
//   Array of UUID - 
//     
//
Function ReplacementRequestsForAllGrantedPermissions() Export
	
	Result = New Array();
	
	QueryText =
		"SELECT DISTINCT
		|	PermissionsTable.ProgramModuleType,
		|	PermissionsTable.ModuleID,
		|	PermissionsTable.OwnerType,
		|	PermissionsTable.OwnerID
		|FROM
		|	InformationRegister.PermissionsToUseExternalResources AS PermissionsTable";
	
	Query = New Query(QueryText);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		ProgramModule = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Selection.ProgramModuleType,
			Selection.ModuleID);
		
		Owner = SafeModeManagerInternal.ReferenceFormPermissionRegister(
			Selection.OwnerType,
			Selection.OwnerID);
		
		ReplacementRequest = SafeModeManagerInternal.PermissionChangeRequest(
			Owner, True, New Array(), , ProgramModule);
		
		Result.Add(ReplacementRequest);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Serializes requests to use external resources.
//
// Parameters:
//  IDs - Array of UUID -  ids of serializable
//   requests.
//
// Returns:
//   String
//
Function WriteRequestsToXMLString(Val IDs) Export
	
	Result = New Array();
	
	For Each Id In IDs Do
		
		Set = CreateRecordSet();
		Set.Filter.QueryID.Set(Id);
		Set.Read();
		
		Result.Add(Set);
		
	EndDo;
	
	Return Common.ValueToXMLString(Result);
	
EndFunction

// Deserializes requests to use external resources.
//
// Parameters:
//  XMLLine - String -  the result of the function write a query to the XML () String.
//
Procedure ReadRequestsFromXMLString(Val XMLLine) Export
	
	Queries = Common.ValueFromXMLString(XMLLine); // Array of InformationRegisterRecordSet
	
	BeginTransaction();
	
	Try
		
		For Each Query In Queries Do
			Query.Write();
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Delete requests for the use of external resources.
//
// Parameters:
//  RequestsIDs - Array of UUID -  IDs of the requests to delete.
//
Procedure DeleteRequests(Val RequestsIDs) Export
	
	BeginTransaction();
	
	Try
		
		For Each QueryID In RequestsIDs Do
			
			Manager = CreateRecordManager();
			Manager.QueryID = QueryID;
			Manager.Delete();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndIf
