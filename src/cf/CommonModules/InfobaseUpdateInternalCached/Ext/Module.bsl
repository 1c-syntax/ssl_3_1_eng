///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns the minimum version of the information database among all data areas.
//
// Returns:
//  String - 
//
Function EarliestIBVersion() Export
	
	If Common.DataSeparationEnabled() Then
		
		ModuleInfobaseUpdateInternalSaaS = Common.CommonModule(
			"InfobaseUpdateInternalSaaS");
		
		EarliestDataAreaVersion = ModuleInfobaseUpdateInternalSaaS.EarliestDataAreaVersion();
	Else
		EarliestDataAreaVersion = Undefined;
	EndIf;
	
	IBVersion = InfobaseUpdateInternal.IBVersion(Metadata.Name);
	
	If EarliestDataAreaVersion = Undefined Then
		EarliestIBVersion = IBVersion;
	Else
		If CommonClientServer.CompareVersions(IBVersion, EarliestDataAreaVersion) > 0 Then
			EarliestIBVersion = EarliestDataAreaVersion;
		Else
			EarliestIBVersion = IBVersion;
		EndIf;
	EndIf;
	
	Return EarliestIBVersion;
	
EndFunction

#EndRegion

#Region Private

// Check whether the database needs to be updated when changing the configuration version.
//
Function InfobaseUpdateRequired() Export
	
	If InfobaseUpdateInternal.UpdateRequired(
			Metadata.Version, InfobaseUpdateInternal.IBVersion(Metadata.Name)) Then
		Return True;
	EndIf;
	
	If Not InfobaseUpdateInternal.DeferredUpdateHandlersRegistered() Then
		Return True;
	EndIf;
	
	If InfobaseUpdateInternal.IsStartInfobaseUpdateSet() Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Returns matching names and IDs of deferred handlers
// and their queues.
//
Function DeferredUpdateHandlerQueue() Export
	
	Handlers        = InfobaseUpdate.NewUpdateHandlerTable();
	SubsystemsDetails  = StandardSubsystemsCached.SubsystemsDetails();
	For Each SubsystemName In SubsystemsDetails.Order Do
		SubsystemDetails = SubsystemsDetails.ByNames.Get(SubsystemName);
		If SubsystemDetails.DeferredHandlersExecutionMode <> "Parallel" Then
			Continue;
		EndIf;
		
		Module = Common.CommonModule(SubsystemDetails.MainServerModule);
		Module.OnAddUpdateHandlers(Handlers);
	EndDo;
	
	Filter = New Structure;
	Filter.Insert("ExecutionMode", "Deferred");
	DeferredHandlers = Handlers.FindRows(Filter);
	
	QueueByName          = New Map;
	QueueByID = New Map;
	For Each DeferredHandler In DeferredHandlers Do
		If DeferredHandler.DeferredProcessingQueue = 0 Then
			Continue;
		EndIf;
		
		QueueByName.Insert(DeferredHandler.Procedure, DeferredHandler.DeferredProcessingQueue);
		If ValueIsFilled(DeferredHandler.Id) Then
			QueueByID.Insert(DeferredHandler.Id, DeferredHandler.DeferredProcessingQueue);
		EndIf;
	EndDo;
	
	Result = New Map;
	Result.Insert("ByName", QueueByName);
	Result.Insert("ByID", QueueByID);
	
	Return New FixedMap(Result);
	
EndFunction

// Caches the types of metadata objects when checking for the presence
// of the recorded object as part of the Information Database update exchange plan.
// 
// Returns:
//  Map
//
Function CacheForCheckingRegisteredObjects() Export
	
	Return New Map;
	
EndFunction

// 

// Returns:
//  FixedMap of KeyAndValue:
//   * Key - MetadataObject
//   * Value - String
//
Function ObjectsWithInitialFilling() Export
	
	Result = New Map();
	
	SubsystemSettings = InfobaseUpdateInternal.SubsystemSettings();
	ObjectsWithInitialFilling = SubsystemSettings.ObjectsWithInitialFilling;
	For Each ObjectWithInitialPopulation In ObjectsWithInitialFilling Do
		Result.Insert(ObjectWithInitialPopulation, ObjectWithInitialPopulation.FullName());
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

#EndRegion
