///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns descriptions of all configuration libraries, including
// a description of the configuration itself.
// 
// Returns:
//  FixedStructure:
//   * Order - Array of String
//   * ByNames - Map of KeyAndValue:
//     ** Key - String
//     ** Value - See NewSubsystemDescription
//
Function SubsystemsDetails() Export
	
	SubsystemsModules = New Array;
	SubsystemsModules.Add("InfobaseUpdateSSL");
	
	SSLSubsystemsIntegration.OnAddSubsystems(SubsystemsModules);
	ConfigurationSubsystemsOverridable.OnAddSubsystems(SubsystemsModules);
	
	ConfigurationDetailsFound = False;
	SubsystemsDetails = New Structure;
	SubsystemsDetails.Insert("Order",  New Array);
	SubsystemsDetails.Insert("ByNames", New Map);
	
	AllRequiredSubsystems = New Map;
	
	For Each ModuleName In SubsystemsModules Do
		
		LongDesc = NewSubsystemDescription();
		Module = Common.CommonModule(ModuleName);
		Module.OnAddSubsystem(LongDesc);
		
		If SubsystemsDetails.ByNames.Get(LongDesc.Name) <> Undefined Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An error occurred when preparing subsystem details:
				           |subsystem details (see the procedure %1.%2)
				           |contain subsystem name ""%3"", which already exists.';"),
				ModuleName, "OnAddSubsystem", LongDesc.Name);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
		
		If LongDesc.Name = Metadata.Name Then
			ConfigurationDetailsFound = True;
			LongDesc.Insert("IsConfiguration", True);
		Else
			LongDesc.Insert("IsConfiguration", False);
		EndIf;
		
		LongDesc.Insert("MainServerModule", ModuleName);
		
		SubsystemsDetails.ByNames.Insert(LongDesc.Name, LongDesc);
		// 
		SubsystemsDetails.Order.Add(LongDesc.Name);
		// 
		For Each RequiredSubsystem In LongDesc.RequiredSubsystems1 Do
			If AllRequiredSubsystems.Get(RequiredSubsystem) = Undefined Then
				AllRequiredSubsystems.Insert(RequiredSubsystem, New Array);
			EndIf;
			AllRequiredSubsystems[RequiredSubsystem].Add(LongDesc.Name);
		EndDo;
	EndDo;
	
	// 
	If ConfigurationDetailsFound Then
		LongDesc = SubsystemsDetails.ByNames[Metadata.Name];
		
		If LongDesc.Version <> Metadata.Version Then
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Error when preparing subsystem details:
				           |version ""%2"" of configuration ""%1""(see procedure %3.%4)
				           |does not match the configuration version in the metadata: ""%5"".';"),
				LongDesc.Name,
				LongDesc.Version,
				LongDesc.MainServerModule,
				"OnAddSubsystem",
				Metadata.Version);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
	ElsIf Metadata.Name = "StandardSubsystemsLibrary" Then
		ErrorText = NStr("en = 'The 1C:Standard Subsystems Library distribution file is not intended for template-based infobase creation.
			|Before you start using it,  read the <link https://kb.1ci.com/1C_Standard_Subsystems_Library/Guides/>SSL documentation</>.';");
		Raise ErrorText;
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'An error occurred when preparing subsystem details:
			           |subsystem details matching configuration name ""%2"" 
			           |do not exist in common modules specified in procedure %1.';"),
			"ConfigurationSubsystemsOverridable.OnAddSubsystem", Metadata.Name);
		Raise(ErrorText, ErrorCategory.ConfigurationError);
	EndIf;
	
	// 
	For Each KeyAndValue In AllRequiredSubsystems Do
		If SubsystemsDetails.ByNames.Get(KeyAndValue.Key) = Undefined Then
			DependentSubsystems = "";
			For Each DependentSubsystem In KeyAndValue.Value Do
				DependentSubsystems = Chars.LF + DependentSubsystem;
			EndDo;
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot prepare subsystem descriptions.
				           |Subsystem ""%1"" does not exist. It is required for the following subsystems: %2.';"),
				KeyAndValue.Key,
				DependentSubsystems);
			Raise(ErrorText, ErrorCategory.ConfigurationError);
		EndIf;
	EndDo;
	
	// 
	For Each KeyAndValue In SubsystemsDetails.ByNames Do
		Name = KeyAndValue.Key;
		Order = SubsystemsDetails.Order.Find(Name);
		For Each RequiredSubsystem In KeyAndValue.Value.RequiredSubsystems1 Do
			RequiredSubsystemOrder = SubsystemsDetails.Order.Find(RequiredSubsystem);
			If Order < RequiredSubsystemOrder Then
				Interdependency = SubsystemsDetails.ByNames[RequiredSubsystem
					].RequiredSubsystems1.Find(Name) <> Undefined;
				If Interdependency Then
					NewOrder = RequiredSubsystemOrder;
				Else
					NewOrder = RequiredSubsystemOrder + 1;
				EndIf;
				If Order <> NewOrder Then
					SubsystemsDetails.Order.Insert(NewOrder, Name);
					SubsystemsDetails.Order.Delete(Order);
					Order = NewOrder - 1;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	// 
	IndexOf = SubsystemsDetails.Order.Find(Metadata.Name);
	If SubsystemsDetails.Order.Count() > IndexOf + 1 Then
		SubsystemsDetails.Order.Delete(IndexOf);
		SubsystemsDetails.Order.Add(Metadata.Name);
	EndIf;
	
	For Each KeyAndValue In SubsystemsDetails.ByNames Do
		KeyAndValue.Value.RequiredSubsystems1 =
			New FixedArray(KeyAndValue.Value.RequiredSubsystems1);
		
		SubsystemsDetails.ByNames[KeyAndValue.Key] =
			New FixedStructure(KeyAndValue.Value);
	EndDo;
	
	Return Common.FixedData(SubsystemsDetails);
	
EndFunction

// Returns True if the privileged mode was set
// at startup using the UsePrivilegedMode parameter.
//
// Supported only when running client applications
// (external connection is not supported).
// 
// Returns:
//  Boolean
// 
Function PrivilegedModeSetOnStart() Export
	
	Return StandardSubsystemsServer.ClientParametersAtServer(False).Get(
		"PrivilegedModeSetOnStart") = True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// For internal use only.
// 
// Returns:
//  Boolean
//
Function DisableMetadataObjectsIDs() Export
	
	CommonParameters = Common.CommonCoreParameters();	
	If Not CommonParameters.DisableMetadataObjectsIDs Then
		Return False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ReportsOptions")
	 Or Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors")
	 Or Common.SubsystemExists("StandardSubsystems.ReportMailing")
	 Or Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot disable the catalog of metadata object IDs
			           |if any of the following subsystems is used:
			           |- %1,
			           |- %2,
			           |- %3,
			           |- %4.';"),
			"ReportsOptions", "AdditionalReportsAndDataProcessors", "ReportMailing", "AccessManagement");
		Raise(ExceptionText, ErrorCategory.ConfigurationError);
	EndIf;
	
	Return True;
	
EndFunction

// For internal use only.
// 
// Parameters:
//  CheckForUpdates  - Boolean
//  ExtensionsObjects    - Boolean
//
// Returns:
//  Boolean
//
Function MetadataObjectIDsUsageCheck(CheckForUpdates = False, ExtensionsObjects = False) Export
	
	Catalogs.MetadataObjectIDs.CheckForUsage(ExtensionsObjects);
	
	If CheckForUpdates Then
		Catalogs.MetadataObjectIDs.IsDataUpdated(True, ExtensionsObjects);
	EndIf;
	
	Return True;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns whether the full rib is used in the information database (without filter).
// Verification is performed using a more accurate algorithm if the "data Exchange" subsystem is used.
//
// Parameters:
//  FilterByPurpose - String - :
//                                
//                                
//                                
//
// Returns:
//   Boolean
//
Function DIBUsed(FilterByPurpose = "") Export
	
	Return DIBNodes(FilterByPurpose).Count() > 0;
	
EndFunction

// Returns a list of rib nodes used in the information database (without filters).
// Verification is performed using a more accurate algorithm if the "data Exchange" subsystem is used.
//
// Parameters:
//  FilterByPurpose - String - :
//                                
//                                
//                                
//
// Returns:
//   ValueList
//
Function DIBNodes(FilterByPurpose = "") Export
	
	FilterByPurpose = Upper(FilterByPurpose);
	
	NodesList = New ValueList;
	
	DIBExchangePlans = DIBExchangePlans();
	Query = New Query();
	For Each ExchangePlanName In DIBExchangePlans Do
		
		If ValueIsFilled(FilterByPurpose)
			And Common.SubsystemExists("StandardSubsystems.DataExchange") Then
			
			ModuleDataExchangeServer = Common.CommonModule("DataExchangeServer");
			DIBPurpose = Upper(ModuleDataExchangeServer.ExchangePlanPurpose(ExchangePlanName));
			
			If FilterByPurpose = "WITHFILTER" And DIBPurpose <> "DIBWITHFILTER"
				Or FilterByPurpose = "FULL" And DIBPurpose <> "DIB" Then
				Continue;
			EndIf;
		EndIf;
		
		Query.Text =
		"SELECT
		|	ExchangePlan.Ref AS Ref
		|FROM
		|	&ExchangePlanName AS ExchangePlan
		|WHERE
		|	NOT ExchangePlan.ThisNode
		|	AND NOT ExchangePlan.DeletionMark";
		Query.Text = StrReplace(Query.Text, "&ExchangePlanName", "ExchangePlan" + "." + ExchangePlanName);
		// 
		NodeSelection = Query.Execute().Select();
		While NodeSelection.Next() Do
			NodesList.Add(NodeSelection.Ref);
		EndDo;
	EndDo;
	
	Return NodesList;
	
EndFunction

// Returns a list of rib exchange plans.
// If the configuration works in the service model,
// it returns a list of shared rib exchange plans.
// 
// Returns:
//  Array of String
// 
Function DIBExchangePlans() Export
	
	Result = New Array;
	
	If Common.DataSeparationEnabled() Then
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If StrStartsWith(ExchangePlan.Name, "Delete") Then
				Continue;
			EndIf;
			
			If Common.SubsystemExists("CloudTechnology.Core") Then
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				IsSeparatedData = ModuleSaaSOperations.IsSeparatedMetadataObject(
					ExchangePlan.FullName(), ModuleSaaSOperations.MainDataSeparator());
			Else
				IsSeparatedData = False;
			EndIf;
			
			If ExchangePlan.DistributedInfoBase
				And IsSeparatedData Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each ExchangePlan In Metadata.ExchangePlans Do
			
			If StrStartsWith(ExchangePlan.Name, "Delete") Then
				Continue;
			EndIf;
			
			If ExchangePlan.DistributedInfoBase Then
				
				Result.Add(ExchangePlan.Name);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Defines the mode of data logging on exchange plan nodes.
// 
// Parameters:
//  FullObjectName - String -  full name of the metadata object to check.
//  ExchangePlanName - String -  check the plan of exchange.
//
// Returns:
//  Undefined - 
//  
//  
//                               
//  
//                               
//                               
//
Function ExchangePlanDataRegistrationMode(FullObjectName, ExchangePlanName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(MetadataObject);
	If ExchangePlanContentItem = Undefined Then
		Return Undefined;
	ElsIf ExchangePlanContentItem.AutoRecord = AutoChangeRecord.Allow Then
		Return "AutoRecordEnabled";
	EndIf;
	
	// 
	// 
	For Each Subscription In Metadata.EventSubscriptions Do
		SubscriptionTitleBeginning = ExchangePlanName + "Registration";
		If Upper(Left(Subscription.Name, StrLen(SubscriptionTitleBeginning))) = Upper(SubscriptionTitleBeginning) Then
			For Each Type In Subscription.Source.Types() Do
				If MetadataObject = Metadata.FindByType(Type) Then
					Return "ProgramRegistration";
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return "AutoRecordDisabled";
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// The availability of the metadata objects by functional options.
// 
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String
//   * Value - Boolean
//
Function ObjectsEnabledByOption() Export
	
	Parameters = New Structure(StandardSubsystemsCached.InterfaceOptions());
	
	ObjectsEnabled = New Map;
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		Value = -1;
		For Each Item In FunctionalOption.Content Do
			If Item.Object = Undefined Then
				Continue;
			EndIf;
			If Value = -1 Then
				Value = GetFunctionalOption(FunctionalOption.Name, Parameters);
			EndIf;
			FullName = Item.Object.FullName();
			If Value = True Then
				ObjectsEnabled.Insert(FullName, True);
			Else
				If ObjectsEnabled[FullName] = Undefined Then
					ObjectsEnabled.Insert(FullName, False);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	Return New FixedMap(ObjectsEnabled);
	
EndFunction

// The latest version of the components from the layout.
// 
// Parameters:
//  Location - String -  the full name of the layout in the metadata
// 
// Returns:
//  FixedStructure - :
//   * Version - String
//   * Location - String
//
Function TheLatestVersionOfComponentsFromTheLayout(Location) Export
	
	LayoutLocationSplit = StrSplit(Location, ".");
	TheBeginningOfTheLayoutName = LayoutLocationSplit.Get(LayoutLocationSplit.UBound());
	
	If LayoutLocationSplit.Count() = 2 Then
		PathToLayouts = Metadata.CommonTemplates;
	Else
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		LayoutLocationSplit.Delete(LayoutLocationSplit.UBound());
		MetadataByFullName = Metadata.FindByFullName(StrConcat(LayoutLocationSplit, "."));
		
		If MetadataByFullName = Undefined Then 
			Parameters = New Structure;
			Parameters.Insert("Version", "0.0.0.0");
			Parameters.Insert("Location", Location);
			Return New FixedStructure(Parameters);
		EndIf;
		
		PathToLayouts = MetadataByFullName.Templates;
	EndIf;
	
	VersionTable = New ValueTable;
	VersionTable.Columns.Add("FullTemplateName");
	VersionTable.Columns.Add("Version");
	VersionTable.Columns.Add("ExtendedVersion", Common.StringTypeDetails(23));
	
	For Each Template In PathToLayouts Do
		
		If Template.TemplateType <> Metadata.ObjectProperties.TemplateType.AddIn
			And Template.TemplateType <> Metadata.ObjectProperties.TemplateType.BinaryData Then
			Continue;
		EndIf;
		
		TemplateName = Template.Name;
				
		If StrStartsWith(Upper(TemplateName), Upper(TheBeginningOfTheLayoutName)) Then
			
			If Upper(TemplateName) = Upper(TheBeginningOfTheLayoutName) Then
				VersionTableRow = VersionTable.Add();
				VersionTableRow.FullTemplateName = Template.FullName();
				VersionTableRow.ExtendedVersion = "00000_00000_00000_00000";
				VersionTableRow.Version = "0.0.0.0";
			Else
				If Mid(TemplateName, StrLen(TheBeginningOfTheLayoutName) + 1, 1) <> "_" Then
					Continue;
				EndIf;
				
				Version = Mid(TemplateName, StrLen(TheBeginningOfTheLayoutName) + 1);
				VersionParts = StrSplit(Version, "_", False);
				If VersionParts.Count() <> 4 Then
					Continue;
				EndIf;
				
				ExtendedPartsOfTheVersion = New Array;
				For Each VersionPart In VersionParts Do
					ExtendedPartsOfTheVersion.Add(Upper(Right("0000" + VersionPart, 5)));
				EndDo;
				VersionTableRow = VersionTable.Add();
				VersionTableRow.FullTemplateName = Template.FullName();
				VersionTableRow.ExtendedVersion = StrConcat(ExtendedPartsOfTheVersion, "_");
				VersionTableRow.Version = StrConcat(VersionParts, ".");
			EndIf;
			
		EndIf;
	EndDo;
	
	If VersionTable.Count() = 0 Then
		
		Parameters = New Structure;
		Parameters.Insert("Version", "0.0.0.0");
		Parameters.Insert("Location", Location);
		
		Return New FixedStructure(Parameters);
		
	EndIf;
	
	VersionTable.Sort("ExtendedVersion Desc");
	
	Parameters = New Structure;
	Parameters.Insert("Version", VersionTable[0].Version);
	Parameters.Insert("Location", VersionTable[0].FullTemplateName);

	Return New FixedStructure(Parameters);
	
EndFunction

// See Catalogs.MetadataObjectIDs.MetadataObjectCollectionProperties
Function MetadataObjectCollectionProperties(ExtensionsObjects = False) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectCollectionProperties(ExtensionsObjects);
	
EndFunction

#EndRegion

#Region Private

Function IsSeparatedModeWithoutDataAreaExtensions() Export
	
	ThisIsSplitSessionModeWithNoDelimiters = StandardSubsystemsServer.ThisIsSplitSessionModeWithNoDelimiters();
	
	If Not ThisIsSplitSessionModeWithNoDelimiters Then
		Return False;
	EndIf;
	
	BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	If BackgroundJob <> Undefined
	   And BackgroundJob.DataSeparation.Count() > 0 Then
		
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// 
//
// Returns:
//   See CommonOverridable.OnDetermineCommonCoreParameters.CommonParameters
//
Function CommonCoreParameters() Export
	
	Return Common.CommonCoreParameters(False);

EndFunction

// The settings applied to the elements of the command interface associated with a parametric functional options.
// 
// Returns:
//  FixedStructure:
//   * Key - String
//   * Value - Arbitrary
//
Function InterfaceOptions() Export 
	
	InterfaceOptions = New Structure;
	CommonOverridable.OnDetermineInterfaceFunctionalOptionsParameters(InterfaceOptions);
	Return New FixedStructure(InterfaceOptions);
	
EndFunction

// Returns a match between the names of "functional" subsystems and the value True.
// The" functional "subsystem has the" Include in command interface " checkbox unchecked.
//
// Returns:
//  FixedMap of KeyAndValue:
//   * Key - String
//   * Value - Boolean
//
Function SubsystemsNames() Export
	
	DisabledSubsystems = New Map;
	CommonOverridable.OnDetermineDisabledSubsystems(DisabledSubsystems);
	
	Names = New Map;
	InsertSubordinateSubsystemNames(Names, Metadata, DisabledSubsystems);
	
	Return New FixedMap(Names);
	
EndFunction

Function AllRefsTypeDetails() Export
	
	Return New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
		New TypeDescription(New TypeDescription(New TypeDescription(New TypeDescription(
			Catalogs.AllRefsType(),
			Documents.AllRefsType().Types()),
			ExchangePlans.AllRefsType().Types()),
			Enums.AllRefsType().Types()),
			ChartsOfCharacteristicTypes.AllRefsType().Types()),
			ChartsOfAccounts.AllRefsType().Types()),
			ChartsOfCalculationTypes.AllRefsType().Types()),
			BusinessProcesses.AllRefsType().Types()),
			BusinessProcesses.RoutePointsAllRefsType().Types()),
			Tasks.AllRefsType().Types());
	
EndFunction

Function IsLongRunningOperationSession() Export
	
	ParentSessionKey = StandardSubsystemsServer.ClientParametersAtServer(False).Get("ParentSessionKey");
	
	Return ValueIsFilled(ParentSessionKey);
	
EndFunction

Function FileInfobase() Export
	
	InfoBaseConnectionString = InfoBaseConnectionString();
	
	Return StrFind(Upper(InfoBaseConnectionString), "FILE=") = 1;
	
EndFunction 


Function DataSeparationEnabled() Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.DataSeparationEnabled();
	Else
		Return False;
	EndIf;
	
EndFunction

Function SeparatedDataUsageAvailable() Export
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		Return ModuleSaaSOperations.SeparatedDataUsageAvailable();
	Else
		Return True;
	EndIf;
	
EndFunction

Function CollectionNamesByBaseTypeNames() Export
	
	CollectionsNames = New Map;
	CollectionsNames.Insert(Upper("Subsystem"), "Subsystems");
	CollectionsNames.Insert(Upper("CommonModule"), "CommonModules");
	CollectionsNames.Insert(Upper("SessionParameter"), "SessionParameters");
	CollectionsNames.Insert(Upper("Role"), "Roles");
	CollectionsNames.Insert(Upper("CommonAttribute"), "CommonAttributes");
	CollectionsNames.Insert(Upper("ExchangePlan"), "ExchangePlans");
	CollectionsNames.Insert(Upper("FilterCriterion"), "FilterCriteria");
	CollectionsNames.Insert(Upper("EventSubscription"), "EventSubscriptions");
	CollectionsNames.Insert(Upper("ScheduledJob"), "ScheduledJobs");
	CollectionsNames.Insert(Upper("FunctionalOption"), "FunctionalOptions");
	CollectionsNames.Insert(Upper("FunctionalOptionsParameter"), "FunctionalOptionsParameters");
	CollectionsNames.Insert(Upper("DefinedType"), "DefinedTypes");
	CollectionsNames.Insert(Upper("SettingsStorage"), "SettingsStorages");
	CollectionsNames.Insert(Upper("CommonForm"), "CommonForms");
	CollectionsNames.Insert(Upper("CommonCommand"), "CommonCommands");
	CollectionsNames.Insert(Upper("CommandGroup"), "CommandGroups");
	CollectionsNames.Insert(Upper("CommonTemplate"), "CommonTemplates");
	CollectionsNames.Insert(Upper("CommonPicture"), "CommonPictures");
	CollectionsNames.Insert(Upper("XDTOPackage"), "XDTOPackages");
	CollectionsNames.Insert(Upper("WebService"), "WebServices");
	CollectionsNames.Insert(Upper("HTTPService"), "HTTPServices");
	CollectionsNames.Insert(Upper("WSReference"), "WSReferences");
	CollectionsNames.Insert(Upper("IntegrationService"), "IntegrationServices");
	CollectionsNames.Insert(Upper("StyleItem"), "StyleItems");
	CollectionsNames.Insert(Upper("Style"), "Styles");
	CollectionsNames.Insert(Upper("Language"), "Languages");
	CollectionsNames.Insert(Upper("Constant"), "Constants");
	CollectionsNames.Insert(Upper("Catalog"), "Catalogs");
	CollectionsNames.Insert(Upper("Document"), "Documents");
	CollectionsNames.Insert(Upper("Sequence"), "Sequences");
	CollectionsNames.Insert(Upper("DocumentJournal"), "DocumentJournals");
	CollectionsNames.Insert(Upper("Enum"), "Enums");
	CollectionsNames.Insert(Upper("Report"), "Reports");
	CollectionsNames.Insert(Upper("DataProcessor"), "DataProcessors");
	CollectionsNames.Insert(Upper("ChartOfCharacteristicTypes"), "ChartsOfCharacteristicTypes");
	CollectionsNames.Insert(Upper("ChartOfAccounts"), "ChartsOfAccounts");
	CollectionsNames.Insert(Upper("ChartOfCalculationTypes"), "ChartsOfCalculationTypes");
	CollectionsNames.Insert(Upper("InformationRegister"), "InformationRegisters");
	CollectionsNames.Insert(Upper("AccumulationRegister"), "AccumulationRegisters");
	CollectionsNames.Insert(Upper("AccountingRegister"), "AccountingRegisters");
	CollectionsNames.Insert(Upper("CalculationRegister"), "CalculationRegisters");
	CollectionsNames.Insert(Upper("BusinessProcess"), "BusinessProcesses");
	CollectionsNames.Insert(Upper("Task"), "Tasks");
	CollectionsNames.Insert(Upper("ExternalDataSources"), "ExternalDataSource");
	
	Return New FixedMap(CollectionsNames);
	
EndFunction

// Returns:
//  Structure:
//   * SessionNumber - Number
//   * SessionStarted - Date
//   * ComputerKey - String
//
Function CurrentSessionProperties() Export
	
	Session = GetCurrentInfoBaseSession();
	Hashing = New DataHashing(HashFunction.SHA256);
	Hashing.Append(Session.ComputerName);
	StringHashSum = Base64String(Hashing.HashSum);
	
	Result = New Structure;
	Result.Insert("SessionNumber",    Session.SessionNumber);
	Result.Insert("SessionStarted",   Session.SessionStarted);
	Result.Insert("ComputerKey", StringHashSum);
	
	Return Result;
	
EndFunction

// Returns:
//  FixedMap of KeyAndValue:
//    * Key - String - 
//                      
//    * Value - Boolean -  the value is True.
//  
Function QueueJobTemplates() Export
	
	Templates = New Map;
	
	If Common.SubsystemExists("CloudTechnology.JobsQueue") Then
		ModuleJobsQueue = Common.CommonModule("JobsQueue");
		QueueJobTemplates = ModuleJobsQueue.QueueJobTemplates();
		For Each Template In QueueJobTemplates Do
			Templates.Insert(Template, True);
		EndDo;
	EndIf;
	
	Return New FixedMap(Templates);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See Catalogs.MetadataObjectIDs.MetadataObjectIDCache
Function MetadataObjectIDCache(CachedDataKey) Export
	
	Return Catalogs.MetadataObjectIDs.MetadataObjectIDCache(
		CachedDataKey);
	
EndFunction

// See Catalogs.MetadataObjectIDs.RenamingTableForCurrentVersion
Function RenamingTableForCurrentVersion() Export
	
	Return Catalogs.MetadataObjectIDs.RenamingTableForCurrentVersion();
	
EndFunction

// See Catalogs.MetadataObjectIDs.IDPresentation
Function MetadataObjectIDPresentation(Ref) Export
	
	Return Catalogs.MetadataObjectIDs.IDPresentation(Ref);
	
EndFunction

// See Catalogs.MetadataObjectIDs.RolesByKeysMetadataObjects
Function RolesByKeysMetadataObjects() Export
	
	Return Catalogs.MetadataObjectIDs.RolesByKeysMetadataObjects();
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns whether the names of predefined values match their references.
//
// Parameters:
//  FullMetadataObjectName - String - 
//                               
//                               :
//                               
//                               
//                               
//                               
//
// Returns:
//  FixedMap of KeyAndValue:
//      * Key     - String -  name of the predefined,
//      * Value - CatalogRef
//                 - ChartOfCharacteristicTypesRef
//                 - ChartOfAccountsRef
//                 - ChartOfCalculationTypesRef
//                 - Null - 
//
//  
//  
//  
//
Function RefsByPredefinedItemsNames(FullMetadataObjectName) Export
	
	PredefinedValues = New Map;
	
	ObjectMetadata = Common.MetadataObjectByFullName(FullMetadataObjectName);
	
	// 
	If ObjectMetadata = Undefined Then 
		Return Undefined;
	EndIf;
	
	// 
	If Not Metadata.Catalogs.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfAccounts.Contains(ObjectMetadata)
		And Not Metadata.ChartsOfCalculationTypes.Contains(ObjectMetadata) Then 
		
		Return Undefined;
	EndIf;
	
	PredefinedItemsNames = ObjectMetadata.GetPredefinedNames();
	
	// 
	If PredefinedItemsNames.Count() = 0 Then 
		Return New FixedMap(PredefinedValues);
	EndIf;
	
	// 
	For Each PredefinedItemName In PredefinedItemsNames Do 
		PredefinedValues.Insert(PredefinedItemName, Null);
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	CurrentTable.Ref AS Ref,
		|	CurrentTable.PredefinedDataName AS PredefinedDataName
		|FROM
		|	&CurrentTable AS CurrentTable
		|WHERE
		|	CurrentTable.Predefined";
	
	Query.Text = StrReplace(Query.Text, "&CurrentTable", FullMetadataObjectName);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	Selection = Query.Execute().Select();
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	// 
	While Selection.Next() Do
		PredefinedValues.Insert(Selection.PredefinedDataName, Selection.Ref);
	EndDo;
	
	Return New FixedMap(PredefinedValues);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// Returns:
//   Structure:
//   * ParallelDeferredUpdateFromVersion - String
//   * DeferredHandlersExecutionMode - String
//   * MainServerModule - String
//   * IsConfiguration - Boolean
//   * OnlineSupportID - String
//   * RequiredSubsystems1 - Array
//   * Version - String
//   * Name - String
//   * FillDataNewSubsystemsWhenSwitchingFromAnotherProgram - Boolean
//
Function NewSubsystemDescription() Export
	
	LongDesc = New Structure;
	LongDesc.Insert("Name",    "");
	LongDesc.Insert("Version", "");
	LongDesc.Insert("RequiredSubsystems1", New Array);
	LongDesc.Insert("OnlineSupportID", "");
	
	// 
	LongDesc.Insert("IsConfiguration", False);
	
	// 
	// 
	LongDesc.Insert("MainServerModule", "");
	
	// 
	// 
	LongDesc.Insert("DeferredHandlersExecutionMode", "Sequentially");
	LongDesc.Insert("ParallelDeferredUpdateFromVersion", "");
	
	// 
	// 
	LongDesc.Insert("FillDataNewSubsystemsWhenSwitchingFromAnotherProgram", False);
	
	Return LongDesc;
	
EndFunction

Procedure InsertSubordinateSubsystemNames(Names, ParentSubsystem, DisabledSubsystems, ParentSubsystemName = "")
	
	For Each CurrentSubsystem In ParentSubsystem.Subsystems Do
		
		If CurrentSubsystem.IncludeInCommandInterface Then
			Continue;
		EndIf;
		
		CurrentSubsystemName = ParentSubsystemName + CurrentSubsystem.Name;
		If DisabledSubsystems.Get(CurrentSubsystemName) = True Then
			Continue;
		Else
			Names.Insert(CurrentSubsystemName, True);
		EndIf;
		
		If CurrentSubsystem.Subsystems.Count() = 0 Then
			Continue;
		EndIf;
		
		InsertSubordinateSubsystemNames(Names, CurrentSubsystem, DisabledSubsystems, CurrentSubsystemName + ".");
	EndDo;
	
EndProcedure

#EndRegion