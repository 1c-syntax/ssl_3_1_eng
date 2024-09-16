///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Parameters:
//  Parameter Name-String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(SessionParametersNames, SpecifiedParameters) Export

	If SessionParametersNames = Undefined Or SessionParametersNames.Find("InstalledExtensions") <> Undefined Then

		SessionParameters.InstalledExtensions = InstalledExtensions(True);
		SpecifiedParameters.Add("InstalledExtensions");
	EndIf;

	If SessionParametersNames = Undefined Or SessionParametersNames.Find("AttachedExtensions") <> Undefined Then

		Extensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
		SessionParameters.AttachedExtensions = ExtensionsChecksums(Extensions, "SafeMode");
		SpecifiedParameters.Add("AttachedExtensions");
	EndIf;

	If SessionParametersNames <> Undefined And SessionParametersNames.Find("ExtensionsVersion") <> Undefined Then

		SessionParameters.ExtensionsVersion = ExtensionsVersion();
		SpecifiedParameters.Add("ExtensionsVersion");
	EndIf;

	If SessionParametersNames = Undefined And CurrentRunMode() <> Undefined Then

		RegisterExtensionsVersionUsage(True);
	EndIf;

EndProcedure

// 
// 
// 
// 
// 
// 
// 
//
// 
// 
//
// Returns:
//  FixedStructure:
//   * Main_    - String -  checksum of all extensions, except for corrective extensions.
//   * Corrections - String -  checksum of all corrective extensions.
//
Function InstalledExtensions(OnStart = False) Export

	DatabaseExtensions = ConfigurationExtensions.Get();
	If OnStart Then
		ExtensionsOnStart = New Map;
		ActiveExtensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied);
		For Each Extension In ActiveExtensions Do
			ExtensionsOnStart.Insert(ExtensionChecksum(Extension), Extension);
		EndDo;
		UnattachedExtensions = ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionDisabled);
		For Each Extension In UnattachedExtensions Do
			ExtensionsOnStart.Insert(ExtensionChecksum(Extension), Extension);
		EndDo;
		AllApplicationProblems = ConfigurationExtensions.GetSessionApplicationIssuesInformation();
		For Each ProblemOfApplication In AllApplicationProblems Do
			Checksum = ExtensionChecksum(ProblemOfApplication.Extension);
			If ExtensionsOnStart.Get(Checksum) = Undefined Then
				ExtensionsOnStart.Insert(Checksum, ProblemOfApplication.Extension);
			EndIf;
		EndDo;
		AddedExtensions = New Map;
		Extensions = New Array;
		For Each Extension In DatabaseExtensions Do
			Checksum = ExtensionChecksum(Extension);
			ExtensionOnStart = ExtensionsOnStart.Get(Checksum);
			If ExtensionOnStart <> Undefined Then
				AddedExtensions.Insert(Checksum, True);
				Extensions.Add(ExtensionOnStart);
			EndIf;
		EndDo;
		For Each ExtensionDetails In ExtensionsOnStart Do
			If AddedExtensions.Get(ExtensionDetails.Key) = Undefined Then
				Extensions.Add(ExtensionDetails.Value);
			EndIf;
		EndDo;
	Else
		Extensions = DatabaseExtensions;
	EndIf;

	IndexOf = Extensions.Count();
	While IndexOf > 0 Do
		IndexOf = IndexOf - 1;
		Extension = Extensions.Get(IndexOf);
		If Base64String(Extension.HashSum) = "AAAAAAAAAAAAAAAAAAAAAAAAAAA=" Then
			Extensions.Delete(IndexOf);
		EndIf;
	EndDo;

	Main_    = New Array;
	Corrections = New Array;

	If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
		ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
	Else
		ModuleConfigurationUpdate = Undefined;
	EndIf;
	
	// 
	// 
	// 
	SharedMode = Common.DataSeparationEnabled()
		And Not Common.SeparatedDataUsageAvailable();

	For Each Extension In Extensions Do
		If SharedMode And Extension.Scope = ConfigurationExtensionScope.DataSeparation Then
			Continue;
		EndIf;
		If ModuleConfigurationUpdate <> Undefined And ModuleConfigurationUpdate.IsPatch(Extension) Then
			Corrections.Add(Extension);
		Else
			Main_.Add(Extension);
		EndIf;
	EndDo;

	InstalledExtensions = New Structure;
	InstalledExtensions.Insert("Main_", ExtensionsChecksums(Main_));
	InstalledExtensions.Insert("Corrections", ExtensionsChecksums(Corrections));
	InstalledExtensions.Insert("MainState", ExtensionsChecksums(Main_, "All"));
	InstalledExtensions.Insert("PatchesState", ExtensionsChecksums(Corrections, "All"));

	If OnStart And ActiveExtensions.Count() = 0 And UnattachedExtensions.Count() = 0
		And DatabaseExtensions.Count() <> 0 And StandardSubsystemsServer.IsBaseConfigurationVersion() Then

		InstalledExtensions.Insert("ExtensionsUnavailable");
	EndIf;

	If OnStart Then
		SetTheInitialRegisteredState(InstalledExtensions, InstalledExtensions);
	EndIf;

	Return New FixedStructure(InstalledExtensions);

EndFunction

// For the long-term operation function.Run the client's background taskcontext.
Procedure InsertARegisteredSetOfInstalledExtensions(Parameters) Export

	ExtensionsChangedDynamically();

	SetPrivilegedMode(True);
	InstalledExtensions = SessionParameters.InstalledExtensions;
	SetPrivilegedMode(False);

	Properties = New Structure;
	Properties.Insert("MainState", InstalledExtensions.BasicRegisteredStatus);
	Properties.Insert("PatchesState", InstalledExtensions.FixesRegisteredStatus);

	Parameters.Insert("RegisteredCompositionOfInstalledExtensions", Properties);

EndProcedure

// For a long-term surgery procedure.Execute the client's context.
Procedure RestoreTheRegisteredCompositionOfInstalledExtensions(Parameters) Export

	If Parameters.Property("RegisteredCompositionOfInstalledExtensions") Then
		SetTheInitialRegisteredState(
			Parameters.RegisteredCompositionOfInstalledExtensions);
	EndIf;

EndProcedure

// Returns:
//  FixedStructure
//
Function InstalledExtensionsOnStartup() Export

	Result = New Structure;
	Result.Insert("Main_", "");
	Result.Insert("Corrections", "");
	Result.Insert("MainState", "");
	Result.Insert("PatchesState", "");

	FillPropertyValues(Result, SessionParameters.InstalledExtensions);

	Return New FixedStructure(Result);

EndFunction

// Returns a flag for changing the composition of extensions after starting the session.
// 
// Returns:
//  Boolean
//
Function ExtensionsChangedDynamically() Export

	SetPrivilegedMode(True);

	InstalledExtensions = InstalledExtensions();

	InstalledExtensionsOnStartup = InstalledExtensionsOnStartup();

	Unchanged = InstalledExtensionsOnStartup.Property("ExtensionsUnavailable")
		Or InstalledExtensionsOnStartup.MainState = InstalledExtensions.MainState
		And InstalledExtensionsOnStartup.PatchesState = InstalledExtensions.PatchesState;

	RegisterChangesToInstalledExtensions(InstalledExtensions, Unchanged);

	Return Not Unchanged;

EndFunction

// Returns information about modified extensions and fixes.
//
// Parameters:
//  InstalledExtensionsOnStartup - See InstalledExtensionsOnStartup
//                                    
//  IsCheckInCurrentSession - Boolean - 
//                                    
//
// Returns:
//  Structure:
//     * Extensions - Structure:
//          * Added2 - Number
//          * Deleted   - Number
//     * Corrections - Structure:
//          * Added2 - Number
//          * Deleted   - Number
//
Function DynamicallyChangedExtensions(InstalledExtensionsOnStartup = Undefined,
	IsCheckInCurrentSession = False) Export

	Result = New Structure;
	Result.Insert("Extensions", Undefined);
	Result.Insert("Corrections", Undefined);

	SetPrivilegedMode(True);

	InstalledExtensions = InstalledExtensions();

	If InstalledExtensionsOnStartup = Undefined Then
		IsCheckInCurrentSession = True;
		InstalledExtensionsOnStartup = InstalledExtensionsOnStartup();
	EndIf;

	Unchanged = InstalledExtensionsOnStartup.Property("ExtensionsUnavailable")
		Or InstalledExtensionsOnStartup.MainState = InstalledExtensions.MainState
		And InstalledExtensionsOnStartup.PatchesState = InstalledExtensions.PatchesState;

	If IsCheckInCurrentSession Then
		RegisterChangesToInstalledExtensions(InstalledExtensions, Unchanged);
	EndIf;

	If Unchanged Then
		Return Result;
	EndIf;

	If InstalledExtensionsOnStartup.PatchesState <> InstalledExtensions.PatchesState Then
		Changes = ChangesInExtensionsComposition(InstalledExtensionsOnStartup.Corrections,
			InstalledExtensions.Corrections);
		Result.Corrections = Changes;
	EndIf;

	If InstalledExtensionsOnStartup.MainState <> InstalledExtensions.MainState Then
		Changes = ChangesInExtensionsComposition(InstalledExtensionsOnStartup.MainState,
			InstalledExtensions.MainState);
		Result.Extensions = Changes;
	EndIf;

	Return Result;

EndFunction

// Adds information that the session started using the metadata version.
Procedure RegisterExtensionsVersionUsage(OnFirstSetSessionParameters = False) Export

	If TransactionActive() Then
		Return;
	EndIf;

	If Not Common.SeparatedDataUsageAvailable() Then
		If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
			ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
			ModuleAccessManagementInternal.OnRegisterExtensionsVersionUsageInSharedSession();
		EndIf;
		Return;
	EndIf;

	If OnFirstSetSessionParameters Then
		SessionParameters.ExtensionsVersion = ExtensionsVersion();
	EndIf;

	ExtensionsVersion = SessionParameters.ExtensionsVersion;

	If Not ValueIsFilled(ExtensionsVersion) Then
		UpdateLatestExtensionsVersion(ExtensionsVersion);
		Return;
	EndIf;

	RoundedSessionStartDate = RoundedSessionStartDate();
	Query = New Query;
	Query.SetParameter("ExtensionsVersion", ExtensionsVersion);
	Query.SetParameter("DateOfLastUse", RoundedSessionStartDate);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	NOT ExtensionsVersions.DeletionMark
	|	AND ExtensionsVersions.Ref = &ExtensionsVersion
	|	AND ExtensionsVersions.DateOfLastUse < &DateOfLastUse";
	
	// 
	// 
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.SetValue("Ref", ExtensionsVersion);
	LockItem.Mode = DataLockMode.Shared;

	BeginTransaction();
	Try
		Block.Lock();
		QueryResult = Query.Execute();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	If Not QueryResult.IsEmpty() Then
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExtensionsVersions");
		LockItem.SetValue("Ref", ExtensionsVersion);
		BeginTransaction();
		Try
			Block.Lock();
			Object = ServiceItem(ExtensionsVersion);

			If Object <> Undefined And Object.DateOfLastUse < RoundedSessionStartDate Then

				Object.DateOfLastUse = RoundedSessionStartDate;
				Object.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;

	UpdateLatestExtensionsVersion(ExtensionsVersion);

EndProcedure

// Returns:
//  Structure:
//    * ExtensionsVersion - CatalogRef.ExtensionsVersions
//                       - Undefined
//    * UpdateDate - Date
//    * UpdateID - UUID
//
Function LastExtensionsVersion() Export
	
	ParameterName = "StandardSubsystems.Core.LastExtensionsVersion";
	StoredProperties = StandardSubsystemsServer.ExtensionParameter(ParameterName, True);
	
	NewStoredProperties = NewStoredPropertiesOfExtensionsVersion();
	
	If TypeOf(StoredProperties) = Type("Structure") Then
		For Each KeyAndValue In NewStoredProperties Do
			If StoredProperties.Property(KeyAndValue.Key)
			   And TypeOf(StoredProperties[KeyAndValue.Key]) = TypeOf(KeyAndValue.Value) Then
				Continue;
			EndIf;
			StoredProperties = Undefined;
			Break;
		EndDo;
	EndIf;
	
	If TypeOf(StoredProperties) = Type("Structure") Then
		Return StoredProperties;
	EndIf;
	
	NewStoredProperties.ExtensionsVersion = Undefined;
	
	Return NewStoredProperties;
	
EndFunction

// Deletes outdated versions of metadata.
Procedure DeleteObsoleteParametersVersions() Export

	OtherVersion = OtherExtensionsVersion();

	If Not ValueIsFilled(OtherVersion) Then
		DisableScheduledJobIfRequired();
		Return;
	EndIf;

	ApplicationsToCheck = New Map;
	ApplicationsToCheck.Insert("1CV8", True);
	ApplicationsToCheck.Insert("1CV8C", True);
	ApplicationsToCheck.Insert("WebClient", True);
	ApplicationsToCheck.Insert("COMConnection", True);
	ApplicationsToCheck.Insert("WSConnection", True);
	ApplicationsToCheck.Insert("BackgroundJob", True);
	ApplicationsToCheck.Insert("SystemBackgroundJob", True);

	SessionsArray = GetInfoBaseSessions();
	MinSessionStartDate = GetCurrentInfoBaseSession().SessionStarted;

	For Each Session In SessionsArray Do
		If Session.SessionStarted >= MinSessionStartDate
			Or ApplicationsToCheck.Get(Session.ApplicationName) = Undefined Then
			Continue;
		EndIf;
		MinSessionStartDate = Session.SessionStarted;
	EndDo;
	MinSessionStartDate = RoundedSessionStartDate(MinSessionStartDate);
	
	// 
	While True Do
		OtherVersion = OtherExtensionsVersion(MinSessionStartDate);
		If Not ValueIsFilled(OtherVersion) Then
			Break;
		EndIf;

		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExtensionsVersions");
		LockItem.SetValue("Ref", OtherVersion);

		BeginTransaction();
		Try
			Block.Lock();
			Object = ServiceItem(OtherVersion);

			If Object <> Undefined And Object.DateOfLastUse < MinSessionStartDate Then

				Object.DeletionMark = True;
				Object.Write();
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndDo;

	DisableScheduledJobIfRequired();

EndProcedure

// Includes/Disables the routine task of deleting the old parameters of the extension Versionsreferences.
Procedure EnableDeleteObsoleteExtensionsVersionsParametersJob(Enable) Export

	ScheduledJobsServer.SetPredefinedScheduledJobUsage(
		Metadata.ScheduledJobs.DeleteObsoleteExtensionsVersionsParameters, Enable);

EndProcedure

// For General Extension forms, set Corrections.
//
Procedure ToggleExtensionUsage(ExtensionID, CurrentUsage) Export

	Extension = FindExtension(ExtensionID);

	If Extension = Undefined Or Extension.Active = CurrentUsage Then

		Return;
	EndIf;

	Extension.Active = CurrentUsage;
	DisableSecurityWarnings(Extension);
	DisableMainRolesUsageForAllUsers(Extension);
	Try
		Extension.Write();
	Except
		Raise;
	EndTry;

	Try
		InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
	Except
		ErrorInfo = ErrorInfo();
		If Extension.Active Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An unexpected error occurred while preparing the extensions (after enabling the extension):
					 |%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Else
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An unexpected error occurred while preparing the extensions (after disabling the extension):
					 |%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndIf;
	EndTry;

	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		Try
			Extension.Active = Not Extension.Active;
			Extension.Write();
		Except
			RecoveryErrorInformation = ErrorInfo();
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'An unexpected error occurred when trying to cancel the change of the extension attachment check box:
						 |%1';"), ErrorProcessing.BriefErrorDescription(RecoveryErrorInformation));
		EndTry;
		If RecoveryErrorInformation = Undefined Then
			ErrorText = ErrorText + Chars.LF + Chars.LF
				+ NStr("en = 'The change of the ""Attached"" extension parameter is canceled.';");
		EndIf;
	EndIf;

	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;

EndProcedure

// For General Extension forms, set Corrections.
//
// Returns:
//  ConfigurationExtension
//  Undefined
//
Function FindExtension(ExtensionID) Export

	Filter = New Structure;
	Filter.Insert("UUID", New UUID(ExtensionID));
	Extensions = ConfigurationExtensions.Get(Filter);

	Extension = Undefined;

	If Extensions.Count() = 1 Then
		Extension = Extensions[0];
	EndIf;

	Return Extension;

EndFunction

// For General Extension forms, set Corrections.
// 
// Parameters:
//  Extension - ConfigurationExtension
//
Procedure DisableSecurityWarnings(Extension) Export

	Extension.UnsafeActionProtection = Common.ProtectionWithoutWarningsDetails();

EndProcedure

// For General Extension forms, set Corrections.
Procedure DisableMainRolesUsageForAllUsers(Extension) Export

	Extension.UseDefaultRolesForAllUsers = False;

EndProcedure

// For General Extension forms, set Corrections.
Procedure DeleteExtensions(ExtensionsIDs, ErrorText) Export

	ExtensionsToDelete = New Array;

	ErrorText = "";
	Try
		ExtensionToDelete = "";
		For Each ExtensionID In ExtensionsIDs Do
			Extension = FindExtension(ExtensionID);
			If Extension <> Undefined Then
				ExtensionDetails = New Structure;
				ExtensionDetails.Insert("Deleted", False);
				ExtensionDetails.Insert("Extension", Extension);
				ExtensionDetails.Insert("ExtensionData", Extension.GetData());
				ExtensionsToDelete.Add(ExtensionDetails);
			EndIf;
		EndDo;
		IndexOf = ExtensionsToDelete.Count() - 1;
		While IndexOf >= 0 Do
			ExtensionDetails = ExtensionsToDelete[IndexOf];
			DisableSecurityWarnings(ExtensionDetails.Extension);
			DisableMainRolesUsageForAllUsers(ExtensionDetails.Extension);
			ExtensionToDelete = ExtensionDetails.Extension.Synonym;
			ExtensionToDelete = ?(ExtensionToDelete = "", ExtensionDetails.Extension.Name, ExtensionToDelete);
			ExtensionDetails.Extension.Delete();
			ExtensionToDelete = "";
			ExtensionDetails.Deleted = True;
			IndexOf = IndexOf - 1;
		EndDo;
	Except
		ErrorInfo = ErrorInfo();
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot delete extension ""%1"". Reason:
				 |%2';"), 
			ExtensionToDelete, ErrorProcessing.BriefErrorDescription(ErrorInfo));
	EndTry;

	If Not ValueIsFilled(ErrorText) Then
		Try
			If Common.SeparatedDataUsageAvailable()
				And ConfigurationExtensions.Get().Count() = 0 Then

				EnableDeleteObsoleteExtensionsVersionsParametersJob(True);
			EndIf;
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'After the deletion, an error occurred in the handler of deletion of all extensions:
					 |%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
	EndIf;

	If Not ValueIsFilled(ErrorText) Then
		Try
			InformationRegisters.ExtensionVersionParameters.UpdateExtensionParameters();
		Except
			ErrorInfo = ErrorInfo();
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'After the deletion, an error occurred while initializing the remaining extensions:
					 |%1';"), ErrorProcessing.BriefErrorDescription(ErrorInfo));
		EndTry;
	EndIf;

	If ValueIsFilled(ErrorText) Then
		RecoveryErrorInformation = Undefined;
		RecoveryPerformed = False;
		Try
			For Each ExtensionDetails In ExtensionsToDelete Do
				If Not ExtensionDetails.Deleted Then
					Continue;
				EndIf;
				ExtensionDetails.Extension.Write(ExtensionDetails.ExtensionData);
				RecoveryPerformed = True;
			EndDo;
		Except
			RecoveryErrorInformation = ErrorInfo();
			ErrorText = ErrorText + Chars.LF + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Another error occurred while attempting to restore the deleted extensions:
						 |%1';"), 
					ErrorProcessing.BriefErrorDescription(RecoveryErrorInformation));
		EndTry;
		If RecoveryPerformed And RecoveryErrorInformation = Undefined Then

			ErrorText = ErrorText + Chars.LF + Chars.LF 
				+ NStr("en = 'The deleted extensions are restored.';");
		EndIf;
	EndIf;

EndProcedure

// For General Extension forms, set Corrections.
//
// Returns:
//  Array of UUID
//
Function RequestsToRevokeExternalModuleUsagePermissions(ExtensionsIDs) Export

	Queries = New Array;

	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not ModuleSafeModeManager.UseSecurityProfiles() Then
		Return Queries;
	EndIf;

	Permissions = New Array;

	For Each ExtensionID In ExtensionsIDs Do
		CurrentExtension = FindExtension(ExtensionID);
		Permissions.Add(ModuleSafeModeManager.PermissionToUseExternalModule(
			CurrentExtension.Name, Base64String(CurrentExtension.HashSum)));
	EndDo;

	Queries.Add(ModuleSafeModeManager.RequestToCancelPermissionsToUseExternalResources(
		Common.MetadataObjectID("InformationRegister.ExtensionVersionParameters"), Permissions));

	Return Queries;

EndFunction

// Returns:
//  Boolean
//
Function AllExtensionsConnected() Export

	SetPrivilegedMode(True);

	Numberofextensions = ConfigurationExtensions.Get().Count();
	NumberofConnectedExtensions = ConfigurationExtensions.Get(,
		ConfigurationExtensionsSource.SessionApplied).Count();

	Return Numberofextensions = NumberofConnectedExtensions;

EndFunction

// Returns:
//  Date - 
//         
//         
//
Function SessionRealtimeTimestamp() Export

	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);

	If Not SessionParameters.InstalledExtensions.Property("SessionRealtimeTimestamp") Then
		InstalledExtensions = New Structure(SessionParameters.InstalledExtensions);
		InstalledExtensions.Insert("SessionRealtimeTimestamp",
			GetCurrentInfoBaseSession().SessionStarted - StandardTimeOffset());
		SessionParameters.InstalledExtensions = New FixedStructure(InstalledExtensions);
	EndIf;
	Timestamp1 = SessionParameters.InstalledExtensions.SessionRealtimeTimestamp;

	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);

	Return Timestamp1;

EndFunction

#EndRegion

#Region Private

// Returns checksums of the specified extensions.
//
// Parameters:
//  Extensions - Array -  to obtain the checksum of the specified extensions.
//  Acetylacetonate - Boolean - take into account the signs of Active and Bezopasnyi.
//
// Returns:
//  String - 
//
Function ExtensionsChecksums(Extensions, AttachmentProperties1 = "", IncludingConfiguration = True)

	List = New ValueList;

	For Each Extension In Extensions Do
		List.Add(ExtensionChecksum(Extension, AttachmentProperties1));
	EndDo;

	If IncludingConfiguration And List.Count() <> 0 Then
		Checksum = "#" + Metadata.Name + " (" + Metadata.Version + ")";
		List.Add(Checksum);
	EndIf;

	Checksums = "";
	For Each Item In List Do
		Checksums = Checksums + Chars.LF + Item.Value;
	EndDo;

	Return TrimL(Checksums);

EndFunction

// For the functions of Controlmeasurement and Ustanovlyuvalysya.
Function ExtensionChecksum(Extension, AttachmentProperties1 = "")

	Checksum = Extension.Name + " (" + Extension.Version + ") " + Base64String(Extension.HashSum);

	If ValueIsFilled(AttachmentProperties1) Then
		Checksum = Checksum + " SafeMode:"
			+ ?(TypeOf(Extension.SafeMode) = Type("Boolean"),
				?(Extension.SafeMode, "Yes", "None"),
				"{" + String(Extension.SafeMode) + "}");
	EndIf;

	If AttachmentProperties1 = "All" Then
		Checksum = Checksum + " PassToSubordinateDIBNodes:" 
			+ ?(Extension.UsedInDistributedInfoBase, "Yes", "None") + " Active:" 
			+ ?(Extension.Active, "Yes", "None");
	EndIf;

	Return Checksum;

EndFunction

// Returns the current version of extensions.
// To search for the version, use the description of the enabled extensions.
//
Function ExtensionsVersion()

	If Not Common.SeparatedDataUsageAvailable() Then
		Return EmptyRef();
	EndIf;

	ExtensionsDetails = SessionParameters.AttachedExtensions;
	If Not ValueIsFilled(ExtensionsDetails) Then
		Return EmptyRef();
	EndIf;

	Query = New Query;
	Query.Text =
	"SELECT
	|	ExtensionsVersions.Ref AS Ref,
	|	ExtensionsVersions.MetadataDetails AS ExtensionsDetails
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	NOT ExtensionsVersions.DeletionMark";
	
	// 
	// 
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.SetValue("Ref", FlagOfAddingNewVersion());
	LockItem.Mode = DataLockMode.Shared;
	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	If VersionFound(Selection, ExtensionsDetails) Then
		ExtensionsVersion = Selection.Ref;
	Else
		// 
		RoundedSessionStartDate = RoundedSessionStartDate();
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExtensionsVersions");
		LockItem.SetValue("Ref", FlagOfAddingNewVersion());
		BeginTransaction();
		Try
			Block.Lock();
			// 
			// 
			QueryResult = Query.Execute();
			Selection = QueryResult.Select();
			If VersionFound(Selection, ExtensionsDetails) Then
				ExtensionsVersion = Selection.Ref;
			Else
				Selection = QueryResult.Select();
				If Selection.Next() And Selection.Count() = 1 Then
					EnableDeleteObsoleteExtensionsVersionsParametersJob(True);
				EndIf;
				Object = ServiceItem();
				Object.MetadataDetails = ExtensionsDetails;
				Object.DateOfLastUse = RoundedSessionStartDate;
				Object.Write();
				ExtensionsVersion = Object.Ref;
			EndIf;
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
	EndIf;

	Return ExtensionsVersion;

EndFunction

// For the version Extensions function.
Function VersionFound(Selection, ExtensionsDetails)

	While Selection.Next() Do
		If Selection.ExtensionsDetails = ExtensionsDetails Then
			Return True;
		EndIf;
	EndDo;

	Return False;

EndFunction

// For the version Extensions function.
Function FlagOfAddingNewVersion()

	Return Catalogs.ExtensionsVersions.GetRef(
		New UUID("61ce6265-abb2-11ea-87d6-b06ebfbf08c7"));

EndFunction

// For the function Versionsextensions and procedures, delete the old versions of the Parameters,
// Register the use of versionsextensions.
//
Function RoundedSessionStartDate(SessionStarted = '00010101')

	If ValueIsFilled(SessionStarted) Then
		Return BegOfHour(SessionStarted);
	EndIf;

	Return BegOfHour(GetCurrentInfoBaseSession().SessionStarted);

EndFunction

// For the function Versionsextensions and procedures, delete the old versions of the Parameters,
// Register the use of versionsextensions.
//
Function ServiceItem(Ref = Undefined)

	If Ref = Undefined Then
		CatalogItem = CreateItem();
		Query = New Query;
		Query.Text =
		"SELECT
		|	ISNULL(MAX(ExtensionsVersions.Code), 0) AS MaxNumber
		|FROM
		|	Catalog.ExtensionsVersions AS ExtensionsVersions";
		Selection = Query.Execute().Select();
		CatalogItem.Code = ?(Selection.Next(), Selection.MaxNumber, 0) + 1;
	Else
		CatalogItem = Ref.GetObject();
		If CatalogItem = Undefined Then
			Return Undefined;
		EndIf;
	EndIf;

	CatalogItem.AdditionalProperties.Insert("DontControlObjectsToDelete");
	CatalogItem.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
	CatalogItem.DataExchange.Recipients.AutoFill = False;
	CatalogItem.DataExchange.Load = True;

	Return CatalogItem;

EndFunction

// For the procedure, delete the old version of the Parameters.
Function OtherExtensionsVersion(MinSessionStartDate = '39991231')

	Query = New Query;
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Query.SetParameter("MinSessionStartDate", MinSessionStartDate);
	Query.Text =
	"SELECT TOP 1
	|	ExtensionsVersions.Ref AS Ref
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	ExtensionsVersions.Ref <> &ExtensionsVersion
	|	AND ExtensionsVersions.DateOfLastUse < &MinSessionStartDate
	|	AND NOT ExtensionsVersions.DeletionMark";
	
	// 
	// 
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.Mode = DataLockMode.Shared;

	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;

	Return Undefined;

EndFunction

// For the procedure, delete the old version of the Parameters.
Procedure DisableScheduledJobIfRequired()

	// 
	Block = New DataLock;
	LockItem = Block.Add("Catalog.ExtensionsVersions");
	LockItem.Mode = DataLockMode.Shared;

	Query = New Query;
	Query.Text =
	"SELECT TOP 2
	|	ExtensionsVersions.Ref AS Ref
	|FROM
	|	Catalog.ExtensionsVersions AS ExtensionsVersions
	|WHERE
	|	NOT ExtensionsVersions.DeletionMark";

	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		If Selection.Count() = 0 Or Selection.Count() = 1 And Selection.Next() 
			And Selection.Ref = SessionParameters.ExtensionsVersion Then

			EnableDeleteObsoleteExtensionsVersionsParametersJob(False);
		EndIf;
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;

EndProcedure

// 
//
// Returns:
//  Structure:
//   * ExtensionsVersion - CatalogRef.ExtensionsVersions
//   * UpdateDate - Date
//   * UpdateID - UUID
//
Function NewStoredPropertiesOfExtensionsVersion()
	
	Result = New Structure;
	Result.Insert("ExtensionsVersion", EmptyRef());
	Result.Insert("UpdateDate", '00010101');
	Result.Insert("UpdateID",
		CommonClientServer.BlankUUID());
	
	Return Result;
	
EndFunction

// For the procedure, register the use of a version of Extensions.
Procedure UpdateLatestExtensionsVersion(ExtensionsVersion)

	If DataBaseConfigurationChangedDynamically() Or ExtensionsChangedDynamically() Then
		Return;
	EndIf;

	StoredProperties = LastExtensionsVersion();

	If StoredProperties.ExtensionsVersion = ExtensionsVersion Then
		Return;
	EndIf;

	StoredProperties.ExtensionsVersion = ExtensionsVersion;
	StoredProperties.UpdateDate   = CurrentSessionDate();
	StoredProperties.UpdateID = New UUID;

	ParameterName = "StandardSubsystems.Core.LastExtensionsVersion";
	StandardSubsystemsServer.SetExtensionParameter(ParameterName, StoredProperties, True);

EndProcedure

// For the dynamically changed Extension function.
Function ChangesInExtensionsComposition(CurrentComposition, NewContent)
	NewMap1 = New Map;
	For Each Extension In StrSplit(NewContent, Chars.LF) Do
		If StrStartsWith(Extension, "#") Or Not ValueIsFilled(Extension) Then
			Continue;
		EndIf;
		NameAndHash = StrSplit(Extension, " ");
		NewMap1.Insert(NameAndHash[0], Extension);
	EndDo;

	CurrentMap = New Map;
	For Each Extension In StrSplit(CurrentComposition, Chars.LF) Do
		If StrStartsWith(Extension, "#") Or Not ValueIsFilled(Extension) Then
			Continue;
		EndIf;
		NameAndHash = StrSplit(Extension, " ");
		CurrentMap.Insert(NameAndHash[0], Extension);
	EndDo;

	Added2 = 0;
	IsChanged  = 0;
	NewItemsList = New Array;
	For Each NewExtension In NewMap1 Do
		FoundItem = CurrentMap[NewExtension.Key];
		If FoundItem = Undefined Then
			Added2 = Added2 + 1;
			NewItemsList.Add(NewExtension.Key);
		ElsIf FoundItem <> NewExtension.Value Then
			IsChanged = IsChanged + 1;
			CurrentMap.Delete(NewExtension.Key);
		Else
			CurrentMap.Delete(NewExtension.Key);
		EndIf;
	EndDo;
	Deleted = CurrentMap.Count();

	Result = New Structure;
	Result.Insert("Added2", Added2);
	Result.Insert("IsChanged", IsChanged);
	Result.Insert("Deleted", Deleted);
	Result.Insert("NewItemsList", NewItemsList);

	Return Result;
EndFunction

// For the function setextensions and the procedure restore the registered setextensions.
Procedure SetTheInitialRegisteredState(Source, Receiver = Undefined)

	If Receiver = Undefined Then
		UpdateTheRegisteredStateInTheSessionParameter(Source);
	Else
		Receiver.Insert("BasicRegisteredStatus", Source.MainState);
		Receiver.Insert("FixesRegisteredStatus", Source.PatchesState);
	EndIf;

EndProcedure

// For the extension functions, the dynamic and dynamically changed extensions are changed.
Procedure RegisterChangesToInstalledExtensions(InstalledExtensions, Unchanged)

	If SessionParameters.InstalledExtensions.BasicRegisteredStatus = InstalledExtensions.MainState
		And SessionParameters.InstalledExtensions.FixesRegisteredStatus = InstalledExtensions.PatchesState Then
		Return;
	EndIf;

	DefaultLanguageCode = Common.DefaultLanguageCode();
	Comment = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '1. Previously:
			 |- Extensions:
			 |""%1""
			 |- Patches:
			 |""%2""
			 |2. Now:
			 |- Extensions:
			 |""%3""
			 |- Patches:
			 |""%4""
			 |3. New composition as at session start: %5';", DefaultLanguageCode),
		SessionParameters.InstalledExtensions.BasicRegisteredStatus,
		SessionParameters.InstalledExtensions.FixesRegisteredStatus,
		InstalledExtensions.MainState, InstalledExtensions.PatchesState, 
			?(Unchanged, NStr("en = 'Yes';", DefaultLanguageCode), NStr("en = 'No';", DefaultLanguageCode)));

	WriteLogEvent(
		NStr("en = 'Configuration extensions.Installed extension change is detected';",
		Common.DefaultLanguageCode()), EventLogLevel.Information,,, Comment);

	UpdateTheRegisteredStateInTheSessionParameter(InstalledExtensions);

EndProcedure

// For procedures to register changesextensionsreferences,
// Set the initial unregistered state.
//
Procedure UpdateTheRegisteredStateInTheSessionParameter(InstalledExtensions)

	Properties = New Structure(SessionParameters.InstalledExtensions);
	Properties.BasicRegisteredStatus    = InstalledExtensions.MainState;
	Properties.FixesRegisteredStatus = InstalledExtensions.PatchesState;

	SessionParameters.InstalledExtensions = New FixedStructure(Properties);

EndProcedure

// 
// 
//
// Returns:
//  Structure:
//   * ConnectedNow - String - 
//   * Disabled1  - String - 
//   * All          - String - 
//
Function DescriptionExtensionsForJournal() Export

	Result = New Structure;

	Result.Insert("ConnectedNow", ExtensionsChecksums(
		ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionApplied), "All", False));

	Result.Insert("Disabled1", ExtensionsChecksums(
		ConfigurationExtensions.Get(, ConfigurationExtensionsSource.SessionDisabled), "All", False));

	Result.Insert("All", ExtensionsChecksums(
		ConfigurationExtensions.Get(), "All", False));

	Return Result;

EndFunction

#EndRegion

#EndIf