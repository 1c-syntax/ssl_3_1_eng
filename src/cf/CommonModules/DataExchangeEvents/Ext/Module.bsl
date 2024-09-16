///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Procedure-handler of the event" before Writing " documents for the mechanism for registering objects on nodes.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  Source       - DocumentObject -  event source.
//  Cancel          - Boolean -  flag for refusing to execute the handler.
//  WriteMode - DocumentWriteMode - see the Document Recording mode in the Syntax Assistant.
//  PostingMode - DocumentPostingMode - See the Document Execution mode in the Syntax Assistant.
// 
Procedure ObjectsRegistrationMechanismBeforeWriteDocument(ExchangePlanName, Source, Cancel, WriteMode, PostingMode) Export
	
	If Source.AdditionalProperties.Property("DisableObjectChangeRecordMechanism")
	   And Not Source.AdditionalProperties.Property("RegisterAtExchangePlanNodesOnUpdateIB") Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		
		Module = Common.CommonModule("PersonalDataProtection");
		If Module.SkipObjectRegistration(ExchangePlanName, Source) Then
			Return;
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure("WriteMode", WriteMode);
	RegisterObjectChange(ExchangePlanName, Source, Cancel, AdditionalParameters);
	
EndProcedure

// Procedure-event handler for" pre-Recording " reference data types (other than documents) for the mechanism for registering
// objects on nodes.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  Source       - CatalogObject
//                 - ChartOfCharacteristicTypesObject - 
//  Cancel          - Boolean -  flag for refusing to execute the handler.
// 
Procedure ObjectsRegistrationMechanismBeforeWrite(ExchangePlanName, Source, Cancel) Export
	
	If Source.AdditionalProperties.Property("DisableObjectChangeRecordMechanism")
	   And Not Source.AdditionalProperties.Property("RegisterAtExchangePlanNodesOnUpdateIB") Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		
		Module = Common.CommonModule("PersonalDataProtection");
		If Module.SkipObjectRegistration(ExchangePlanName, Source) Then
			Return;
		EndIf;
		
	EndIf;
	
	RegisterObjectChange(ExchangePlanName, Source, Cancel);
	
EndProcedure

// Procedure-event handler for" pre-Writing " registers for the mechanism for registering objects on nodes.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  Source       - НаборЗаписейРегистра -  event source.
//  Cancel          - Boolean -  flag for refusing to execute the handler.
//  Replacing      - Boolean -  indicates whether an existing record set is being replaced.
// 
Procedure ObjectsRegistrationMechanismBeforeWriteRegister(ExchangePlanName, Source, Cancel, Replacing) Export
	
	If Source.AdditionalProperties.Property("DisableObjectChangeRecordMechanism")
	   And Not Source.AdditionalProperties.Property("RegisterAtExchangePlanNodesOnUpdateIB") Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		
		Module = Common.CommonModule("PersonalDataProtection");
		If Module.SkipObjectRegistration(ExchangePlanName, Source) Then
			Return;
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure("IsRegister,Replacing", True, Replacing);
	RegisterObjectChange(ExchangePlanName, Source, Cancel, AdditionalParameters);
	
EndProcedure

// Procedure-handler for the event" before Writing " a constant for the mechanism for registering objects on nodes.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  Source       - ConstantValueManager -  event source.
//  Cancel          - Boolean -  flag for refusing to execute the handler.
// 
Procedure ObjectsRegistrationMechanismBeforeWriteConstant(ExchangePlanName, Source, Cancel) Export
	
	If Source.AdditionalProperties.Property("DisableObjectChangeRecordMechanism")
	   And Not Source.AdditionalProperties.Property("RegisterAtExchangePlanNodesOnUpdateIB") Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure("IsConstant", True);
	RegisterObjectChange(ExchangePlanName, Source, Cancel, AdditionalParameters);
	
EndProcedure

// Procedure-handler for the "pre-Deletion" event of reference data types for the mechanism for registering objects on nodes.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  Source       - CatalogObject
//                 - DocumentObject
//                 - ChartOfCharacteristicTypesObject -  event source.
//  Cancel          - Boolean -  flag for refusing to execute the handler.
// 
Procedure ObjectsRegistrationMechanismBeforeDelete(ExchangePlanName, Source, Cancel) Export
	
	If Source.AdditionalProperties.Property("DisableObjectChangeRecordMechanism")
	   And Not Source.AdditionalProperties.Property("RegisterAtExchangePlanNodesOnUpdateIB") Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		
		Module = Common.CommonModule("PersonalDataProtection");
		If Module.SkipObjectRegistration(ExchangePlanName, Source) Then
			Return;
		EndIf;
		
	EndIf;
	
	AdditionalParameters = New Structure("IsObjectDeletion", True);
	RegisterObjectChange(ExchangePlanName, Source, Cancel, AdditionalParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// The procedure adds the passed values to the list of object recipient nodes.
//
// Parameters:
//   Object - CatalogObject
//          - DocumentObject - 
//   Nodes   - Array of ExchangePlanRef -  exchange plan nodes to add to the list of object recipient nodes.
//
Procedure SupplementRecipients(Object, Nodes) Export
	
	For Each Item In Nodes Do
		
		Try
			Object.DataExchange.Recipients.Add(Item);
		Except
			ExchangePlanName   = DataExchangeCached.GetExchangePlanName(Item);
			MetadataObject = Object.Metadata();
			MessageString  = NStr("en = 'Registration of [FullName] is not specified in the exchange plan [ExchangePlanName].';");
			MessageString  = StrReplace(MessageString, "[ExchangePlanName]", ExchangePlanName);
			MessageString  = StrReplace(MessageString, "[FullName]",      MetadataObject.FullName());
			Raise MessageString;
		EndTry;
		
	EndDo;
	
EndProcedure

// The procedure subtracts the passed values from the list of object recipient nodes.
//
// Parameters:
//   Object - CatalogObject
//          - DocumentObject - 
//   Nodes - Array of ExchangePlanRef -  the nodes of the plan of exchange, which must be subtracted from the node list recipient object.
// 
Procedure ReduceRecipients(Object, Nodes) Export
	
	Recipients = ReduceArray(Object.DataExchange.Recipients, Nodes);
	
	// 
	Object.DataExchange.Recipients.Clear();
	
	// 
	SupplementRecipients(Object, Recipients);
	
EndProcedure

// Defines an array of recipient nodes for an object with the specified exchange plan and registers the object on
// the received nodes.
//
// Parameters:
//  Object         - Arbitrary -  Reference object, document Object, etc. the object to be registered for
//                   and to register on nodes.
//  ExchangePlanName - String - 
//  Sender    - ExchangePlanRef -  the exchange plan node that the exchange message is received from.
//                    If set, the object will not be registered on this node.
// 
Procedure ExecuteRegistrationRulesForObject(Object, ExchangePlanName, Sender = Undefined) Export
	
	Recipients = GetRecipients(Object, ExchangePlanName);
	
	CommonClientServer.DeleteValueFromArray(Recipients, Sender);
	
	If Recipients.Count() > 0 Then
		
		ExchangePlans.RecordChanges(Recipients, Object);
		
	EndIf;
	
EndProcedure

// Subtracts one array of elements from another array. Returns the result of subtraction.
//
// Parameters:
//  Array - Array of Arbitrary -  original array.
//  SubtractionArray - Array of Arbitrary -  an array that is subtracted from the original array.
//
// Returns:
//   Array of Arbitrary - 
//
Function ReduceArray(Array, SubtractionArray) Export
	
	Return CommonClientServer.ArraysDifference(Array, SubtractionArray);
	
EndFunction

// The function returns a list of all nodes of the specified exchange plan except the predefined node.
//
// Parameters:
//   ExchangePlanName - String -  the name of the exchange plan, as specified in the Configurator,
//                    and the list of nodes to get.
//
// Returns:
//   Array of ExchangePlanRef - 
//
Function AllExchangePlanNodes(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeServer.ExchangePlanNodes(ExchangePlanName);
	
EndFunction

// The function defines an array of recipient nodes for an object with the specified exchange plan.
//
// Parameters:
//   Object         - Arbitrary -  A reference object, document Object, and so on. an object for which you need to follow
//                    the registration rules and define a list of recipient nodes.
//   ExchangePlanName - String - 
// 
// Returns:
//   Array of ExchangePlanRef - 
//
Function GetRecipients(Object, ExchangePlanName) Export
	
	NodesArrayResult = New Array;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("MetadataObject", Object.Metadata());
	AdditionalParameters.Insert("IsRegister", Common.IsRegister(AdditionalParameters.MetadataObject));
	ExecuteObjectsRegistrationRulesForExchangePlan(NodesArrayResult, Object, ExchangePlanName, AdditionalParameters);
	
	Return NodesArrayResult;
	
EndFunction

// Specifies whether the metadata object is automatically registered as part of the exchange plan.
//
// Parameters:
//   MetadataObject - MetadataObject -  the object to get the autoregistration attribute for. 
//   ExchangePlanName - String - 
//                          
//
// Returns:
//   Boolean - :
//           * True - 
//           * False   - 
//                      
//
Function AutoRegistrationAllowed(MetadataObject, ExchangePlanName) Export
	
	Return DataExchangeCached.AutoRegistrationAllowed(ExchangePlanName, MetadataObject.FullName());
	
EndFunction

// Checks whether the data element is not being loaded.
//  For this function to work, you need to set up the data procedure for checking the
// Module's changesdate Changesdetectable.
//
// Parameters:
//  Data     - Arbitrary -  Reference object.<Name>,
//                        Document object.<Name>,
//                        Provideopportunities.<Name>,
//                        Planscontact.<Name>,
//                        Providesdetailed.<Name>,
//                        Business process object.<Name>,
//                        Taskobject.<Name>,
//                        Planebook.<Name>,
//                        Deleting an object - a data object.
//                        Register of leaded sets of records.<Name>,
//                        Register of placemarkingset of records.<Name>,
//                        Registersocketnotifier.<Name>,
//                        The register is calculated for records.<Name> - a set of records.
//
//  ExchangePlanNode     - ПланыОбменаОбъект -  the node
//                        for which validation will be performed.
//
// Returns:
//  Boolean - 
//
Function ImportRestricted(Data, Val ExchangePlanNode) Export
	
	IsObjectDeletion = (TypeOf(Data) = Type("ObjectDeletion"));
	
	If Not IsObjectDeletion
		And Data.AdditionalProperties.Property("DataImportRestrictionFound") Then
		Return True;
	EndIf;
	
	ItemReceive = DataItemReceive.Auto;
	CheckImportRestrictionByDate(Data, ItemReceive, ExchangePlanNode);
	
	Return ItemReceive = DataItemReceive.Ignore;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// See ExportImportDataOverridable.OnRegisterDataImportHandlers.
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		HandlerRow = HandlersTable.Add();
		HandlerRow.MetadataObject      = Metadata.ExchangePlans[ExchangePlanName];
		HandlerRow.Handler            = Common.CommonModule("DataExchangeEvents");
		HandlerRow.AfterImportObject = True;
		
	EndDo;
		
EndProcedure

// Executes handlers after the object is loaded.
//
// Parameters:
//	Container - DataProcessorObject.ExportImportDataContainerManager -  
//		the container manager used in the data upload process. For more information, see the comment
//		on the software interface for processing the unloading of the data of the Manager container.
//	Object - Arbitrary -  the object of the uploaded data.
//	Artifacts - Array of XDTODataObject - 
//
Procedure AfterImportObject(Container, Object, Artifacts) Export
	
	ExchangePlansList = DataExchangeCached.SSLExchangePlans();
	If ExchangePlansList.Find(Object.Metadata().Name) <> Undefined
		And Not Object.ThisNode Then
		
		Record = InformationRegisters.CommonInfobasesNodesSettings.CreateRecordManager();
		Record.InfobaseNode = Object.Ref;
		Record.SynchronizationIsUnavailable = True;
		Record.SettingCompleted = True;
		Record.Write(True);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Internal

// The procedure is used to determine the type of sending of the uploaded data element.
// Called from the exchange plan handlers: pre-sent to Main(), pre-sent to Subordinate ().
//
// Parameters:
//   DataElement - ConstantValueManager
//                 - CatalogObject
//                 - DocumentObject
//                 - InformationRegisterRecordSet
//                 - и т.п. -
//                    data element.
//   ItemSend - DataItemSend - see the description of the "Sending Element" parameter in the syntax helper
//                      for the methods sent to the main() and sent to the subordinate().
//   InitialImageCreating - Boolean -  indicates whether the procedure was called when creating the initial rib image.
//   Recipient - ExchangePlanRef
//              - Undefined - 
//   Analysis - Boolean -  indicates whether the procedure was called during analysis.
//
Procedure OnSendDataToRecipient(DataElement,
										ItemSend,
										Val InitialImageCreating = False,
										Val Recipient = Undefined,
										Val Analysis = True) Export
	
	If Recipient = Undefined Then
		
		//
		
	ElsIf ItemSend = DataItemSend.Delete
		Or ItemSend = DataItemSend.Ignore Then
		
		// 
		
	ElsIf DataExchangeCached.IsSSLDataExchangeNode(Recipient.Ref) Then
		
		OnSendData(DataElement, ItemSend, Recipient.Ref, InitialImageCreating, Analysis);
		
	EndIf;
	
	If Analysis Then
		Return;
	EndIf;
	
	// 
	If Not InitialImageCreating
		And ItemSend <> DataItemSend.Ignore
		And DataExchangeCached.IsDistributedInfobaseNode(Recipient.Ref)
		And TypeOf(DataElement) <> Type("ObjectDeletion") Then
		
		MetadataObject = DataElement.Metadata();
		
		If Common.IsCatalog(MetadataObject)
			Or Common.IsChartOfCharacteristicTypes(MetadataObject)
			Or Common.IsChartOfAccounts(MetadataObject)
			Or Common.IsChartOfCalculationTypes(MetadataObject) Then
			
			If DataElement.Predefined Then
				
				DataExchangeInternal.SupplementPriorityExchangeData(DataElement.Ref);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// The procedure is a handler for an event of the same name that occurs when data is exchanged in a distributed
// information database.
//
// Parameters:
//   see the description of the event handler for the receipt of the given Head() in the syntax assistant.
// 
Procedure OnReceiveDataFromMasterInBeginning(DataElement, ItemReceive, SendBack, Sender) Export
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"ImportApplicationParameters") Then
		
		// 
		ItemReceive = DataItemReceive.Ignore;
		
	Else
		
		If TypeOf(DataElement) = Type("ConstantValueManager.DataForDeferredUpdate") Then
			ItemReceive = DataItemReceive.Ignore;
			DataExchangeServer.ProcessDataToUpdateInSubordinateNode(DataElement);
		EndIf;
		
	EndIf;
	
EndProcedure

// This procedure is intended for performing checks for collisions between loading and changing data.
// Called from the exchange plan handler: getting the data from the Main one.
//
// Parameters:
//   see the description of the event handler for the receipt of the given Head() in the syntax assistant.
// 
Procedure OnReceiveDataFromMasterInEnd(DataElement, ItemReceive, Val Sender) Export
	
	// 
	CheckImportRestrictionByDate(DataElement, ItemReceive, Sender);
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	// 
	CheckDataChangesConflict(DataElement, ItemReceive, Sender, True);
	
EndProcedure

// This procedure is intended for performing checks for collisions between loading and changing data.
// Called from the exchange plan handler: Getteddannotsubscribed.
//
// Parameters:
//   see the description of the handler for the event of receiving the Sent() in the syntax assistant.
// 
Procedure OnReceiveDataFromSlaveInEnd(DataElement, ItemReceive, Val Sender) Export
	
	// 
	CheckImportRestrictionByDate(DataElement, ItemReceive, Sender);
	
	If ItemReceive = DataItemReceive.Ignore Then
		Return;
	EndIf;
	
	// 
	CheckDataChangesConflict(DataElement, ItemReceive, Sender, False);
	
EndProcedure

// Registers a change to a single data item for subsequent sending to the destination node.
// The data element will only be registered if it matches the object registration rule filters 
// set in the properties of the recipient node.
// Data elements that are downloaded when needed, you are registered of course.
// Object Udaleniya recorded of course.
//
// Parameters:
//     Recipient - ExchangePlanRef          -  the exchange plan node for which data changes are registered
//                                              .
//     Data     - CatalogObject
//                - DocumentObject
//                - Arbitrary
//                - ObjectDeletion - 
//                  
//                  
//     CheckExportPermission - Boolean   -  flag. If set to False, then an additional check
//                                              for compliance with the general settings of the node will not be performed during registration
//                                              .
//
Procedure RecordDataChanges(Val Recipient, Val Data, Val CheckExportPermission=True) Export
	
	If TypeOf(Data) = Type("ObjectDeletion") Then
		// 
		ExchangePlans.RecordChanges(Recipient, Data);
		
	Else
		ObjectExportMode = DataExchangeCached.ObjectExportMode(Data.Metadata().FullName(), Recipient);
		
		If ObjectExportMode = Enums.ExchangeObjectExportModes.ExportIfNecessary
			And Common.RefTypeValue(Data) Then
			
			IsNewObject = Data.IsEmpty();
			
			If IsNewObject Then
				Raise NStr("en = 'Cannot register objects exported by reference if they are not written.';");
			EndIf;
			
			BeginTransaction();
			Try
				// 
				ExchangePlans.RecordChanges(Recipient, Data);
				
				// 
				// 
				If DataExchangeServer.IsXDTOExchangePlan(Recipient) Then
					DataExchangeXDTOServer.AddObjectToAllowedObjectsFilter(Data.Ref, Recipient);
				Else
					InformationRegisters.InfobaseObjectsMaps.AddObjectToAllowedObjectsFilter(Data.Ref, Recipient);
				EndIf;
				
				CommitTransaction();
			Except
				RollbackTransaction();
				Raise;
			EndTry;
			
		ElsIf Not CheckExportPermission Then
			// 
			ExchangePlans.RecordChanges(Recipient, Data);
			
		ElsIf ObjectExportAllowed(Recipient, Data) Then
			// 
			ExchangePlans.RecordChanges(Recipient, Data);
			
		EndIf;
	EndIf;
	
EndProcedure

Procedure SetNodeFilterValues(ExchangePlanNode, Settings) Export
	
	SetValueOnNode(ExchangePlanNode, Settings);
	
EndProcedure

Procedure SetDefaultNodeValues(ExchangePlanNode, Settings) Export
	
	SetValueOnNode(ExchangePlanNode, Settings);
	
EndProcedure

// Creates and writes the object version to the information database.
//
// Parameters:
//  Object - 
//  RefExists - Boolean - 
//  :
//    * VersionAuthor - Пользователь, УзелПланаОбмена -  source of the version.
//        Optional, the default value is Undefined.
//    * ObjectVersionType - String -  type of version being created.
//        Optional, the default value is "changed by User".
//    * SynchronizationWarning - String -  synchronization warning to the version being created.
//        Optional, the default value is "".
//
Procedure OnCreateObjectVersion(Object, ObjectVersionInfo, RefExists, Sender) Export
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		NewObjectVersionInfo = New Structure;
		NewObjectVersionInfo.Insert("VersionAuthor", Undefined);
		NewObjectVersionInfo.Insert("ObjectVersionType", "ChangedByUser");
		NewObjectVersionInfo.Insert("Comment", "");
		NewObjectVersionInfo.Insert("SynchronizationWarning", "");
		FillPropertyValues(NewObjectVersionInfo, ObjectVersionInfo);
		
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		ModuleObjectsVersioning.CreateObjectVersionByDataExchange(Object, NewObjectVersionInfo, RefExists, Sender);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region EventsSubscriptionsHandlers

Procedure RegisterDataMigrationRestrictionFiltersChanges(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.IsNew() Then
		Return;
	ElsIf Source.AdditionalProperties.Property("GettingExchangeMessage") Then
		Return; // 
	ElsIf Not DataExchangeCached.IsSSLDataExchangeNode(Source.Ref) Then
		Return;
	ElsIf Source.ThisNode Then
		Return;
	EndIf;
	
	SourceRef = Common.ObjectAttributesValues(Source.Ref, "SentNo, ReceivedNo");
	
	If SourceRef.SentNo <> Source.SentNo Then
		Return; // 
	ElsIf SourceRef.ReceivedNo <> Source.ReceivedNo Then
		Return; // 
	EndIf;
	
	NodeCheckParameters = New Structure;
	NodeCheckParameters.Insert("IsNodeModified", False);
	NodeCheckParameters.Insert("AttributesOfExchangePlanNodeRefType", Undefined);
	
	ExchangePlanNodeModifiedByRefAttributes(Source, NodeCheckParameters);
	
	If NodeCheckParameters.IsNodeModified
		And NodeCheckParameters.AttributesOfExchangePlanNodeRefType <> Undefined Then
		
		Source.AdditionalProperties.Insert("NodeAttributesTable", NodeCheckParameters.AttributesOfExchangePlanNodeRefType);
		
	EndIf;
	
EndProcedure

Procedure CheckForChangesToDataMigrationRestrictionFiltersWhenWriting(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DataExchangeCached.IsSSLDataExchangeNode(Source.Ref) Then
		Return;
	EndIf;
	
	ObjectsRegisteredForExport = Undefined;
	If Source.AdditionalProperties.Property("ObjectsRegisteredForExport", ObjectsRegisteredForExport) Then
		
		DataExchangeInternal.RefreshObjectsRegistrationMechanismCache();
		
		For Each ItemSet In ObjectsRegisteredForExport Do
			
			If Common.IsRefTypeObject(ItemSet.Key) Then
				
				PDParameters = BatchRegistrationParameters();
				
				PerformBatchRegistrationForNode(Source.Ref, ItemSet.Value, PDParameters);
					
				If PDParameters.ThereIsPRO_WithoutBatchRegistration Then
					For Each Ref In PDParameters.LinksNotByBatchRegistrationFilter Do
						If Not ObjectExportAllowed(Source.Ref, Ref) Then
							ExchangePlans.DeleteChangeRecords(Source.Ref, Ref);
						EndIf;
					EndDo;
				Else
					For Each Ref In PDParameters.LinksNotByBatchRegistrationFilter Do
						ExchangePlans.DeleteChangeRecords(Source.Ref, Ref);
					EndDo;
				EndIf;
					
			ElsIf Common.IsConstant(ItemSet.Key) Then
				
				Object = ItemSet.Value;
				If Not ObjectExportAllowed(Source.Ref, Object) Then
					ExchangePlans.DeleteChangeRecords(Source.Ref, Object);
				EndIf;
				Object = Undefined;
				
			Else
				
				ObjectManager = Common.ObjectManagerByFullName(ItemSet.Key.FullName());
				
				FiltersTable1 = ItemSet.Value; // ValueTable
				While FiltersTable1.Count() > 0 Do
					
					Object = ObjectManager.CreateRecordSet();
					For Each FilterElement In FiltersTable1.Columns Do
						DataExchangeInternal.SetFilterItemValue(
							Object.Filter, FilterElement.Name, FiltersTable1[0][FilterElement.Name]);
					EndDo;
					Object.Read();
					
					If Not ObjectExportAllowed(Source.Ref, Object) Then
						ExchangePlans.DeleteChangeRecords(Source.Ref, Object);
					EndIf;
					Object = Undefined;
					FiltersTable1.Delete(0);
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ReferenceTypeAttributesTable = Undefined;
	If Source.AdditionalProperties.Property("NodeAttributesTable", ReferenceTypeAttributesTable) Then
		
		// 
		RegisterReferenceTypeObjectsByNodeProperties(Source, ReferenceTypeAttributesTable);
		
		// 
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
		
	EndIf;
	
EndProcedure

Procedure EnableExchangePlanUsage(Source, Cancel) Export
	
	// 
	// 
	// 
	
	If Source.IsNew() And DataExchangeCached.IsSeparatedSSLDataExchangeNode(Source.Ref) Then
		
		// 
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
		
	EndIf;
	
EndProcedure

// Parameters:
//   Source - ExchangePlanObject -  the site plan of exchange.
//   Cancel - Boolean -  The truth is, in case of refusal to perform the operation.
//
Procedure DisableExchangePlanUsage(Source, Cancel) Export
	
	// 
	// 
	// 
	
	If DataExchangeCached.IsSeparatedSSLDataExchangeNode(Source.Ref) Then
		
		// 
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
		
	EndIf;
	
EndProcedure

Procedure CheckDataExchangeSettingsEditability(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not DataExchangeCached.IsSSLDataExchangeNode(Source.Ref) Then
		Return;
	EndIf;
	
	PropertiesToExclude = New Array;
	PropertiesToExclude.Add("SentNo");
	PropertiesToExclude.Add("ReceivedNo");
	PropertiesToExclude.Add("DeletionMark");
	PropertiesToExclude.Add("Code");
	PropertiesToExclude.Add("Description");
	
	If Common.DataSeparationEnabled() Then
		FullMetadataName = Source.Metadata().FullName();
		
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		
		MainDataSeparator        = ModuleSaaSOperations.MainDataSeparator();
		AuxiliaryDataSeparator = ModuleSaaSOperations.AuxiliaryDataSeparator();
		
		If ModuleSaaSOperations.IsSeparatedMetadataObject(FullMetadataName, MainDataSeparator) Then
			PropertiesToExclude.Add(MainDataSeparator);
		EndIf;
		
		If ModuleSaaSOperations.IsSeparatedMetadataObject(FullMetadataName, AuxiliaryDataSeparator) Then
			PropertiesToExclude.Add(AuxiliaryDataSeparator);
		EndIf;
		
	EndIf;
	
	If Source.AdditionalProperties.Property("DeferredNodeWriting") 
		Or (Not Source.AdditionalProperties.Property("GettingExchangeMessage")
		And Not Source.IsNew()
		And Not Source.ThisNode
		And DataDiffers1(Source, Source.Ref.GetObject(), , StrConcat(PropertiesToExclude, ","))
		And DataExchangeInternal.ChangesRegistered(Source.Ref)) Then
		
		SaveObjectsAvailableForExport(Source);
		
	EndIf;
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		SessionWithoutSeparators = ModuleSaaSOperations.SessionWithoutSeparators();
	Else
		SessionWithoutSeparators = True;
	EndIf;
	
	// 
	If Common.DataSeparationEnabled()
		And Not SessionWithoutSeparators
		And Not Source.IsNew()
		And DataDiffers1(Source, Source.Ref.GetObject(), "Code, Description") Then
		
		Raise NStr("en = 'Changing data synchronization description and ID is not allowed.';");
		
	EndIf;
	
EndProcedure

Procedure DisableAutomaticDataSynchronizationDuringRecording(Source, Cancel, Replacing) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		ModuleStandaloneMode.DisableAutoDataSyncronizationWithWebApplication(Source);
	EndIf;
	
EndProcedure

// Parameters:
//   NodeRef1 - ExchangePlanRef
//   FullMetadataObjectName - String
//   
// Returns:
//   ValueTable - :
//     * Ref - AnyRef -  object reference.
//     * Node - ExchangePlanRef -  the site plan of exchange.
//     * Recorder - DocumentRef -  the Registrar of record set (optional).
//     * <LeadingRegisterChanges> - Arbitrary
//
Function RegisteredDataOfSingleType(NodeRef1, FullMetadataObjectName)
	
	Query = New Query(
	"SELECT
	|	*
	|FROM
	|	#ChangesTable1 AS ChangesTable1
	|WHERE
	|	ChangesTable1.Node = &Node");
	Query.SetParameter("Node", NodeRef1);
	
	Query.Text = StrReplace(Query.Text, "#ChangesTable1", FullMetadataObjectName + ".Changes");
		
	Return Query.Execute().Unload();
	
EndFunction

// Returns:
//   ValueTable:
//     * Ref - AnyRef -  link to the registered object.
//
Function RegisteredDataOfSingleReferenceType(NodeRef1, FullMetadataObjectName)
	
	Query = New Query(
	"SELECT
	|	TableObject.Ref AS Ref
	|FROM
	|	#ChangesTable1 AS ChangesTable1
	|		INNER JOIN #TableObject AS TableObject
	|		ON ChangesTable1.Ref = TableObject.Ref
	|WHERE
	|	ChangesTable1.Node = &Node");
	Query.SetParameter("Node", NodeRef1);
	
	Query.Text = StrReplace(Query.Text, "#ChangesTable1", FullMetadataObjectName + ".Changes");
	Query.Text = StrReplace(Query.Text, "#TableObject", FullMetadataObjectName);
	
	Return Query.Execute().Unload();
	
EndFunction

Procedure SaveObjectsAvailableForExport(ObjectNode)
	
	SetPrivilegedMode(True);
	
	RegisteredData = New Map;
	
	ExchangePlanContent = ObjectNode.Metadata().Content;
	
	For Each CompositionItem In ExchangePlanContent Do
		
		If CompositionItem.AutoRecord = AutoChangeRecord.Allow Then
			Continue;
		EndIf;
		
		ItemMetadata = CompositionItem.Metadata;
		FullMetadataObjectName = ItemMetadata.FullName();
		
		If Common.IsRefTypeObject(ItemMetadata) Then
			
			RefsCollection = New Array;
			
			DataSet = RegisteredDataOfSingleReferenceType(ObjectNode.Ref, FullMetadataObjectName);
			
			ReferencesArrray = DataSet.UnloadColumn("Ref");
			PDParameters = BatchRegistrationParameters();
			
			PerformBatchRegistrationForNode(ObjectNode.Ref, ReferencesArrray, PDParameters);
				
			For Each Ref In PDParameters.LinksToBatchRegistrationFilter Do
				RefsCollection.Add(Ref);
			EndDo;
			
			If PDParameters.ThereIsPRO_WithoutBatchRegistration Then
				For Each Ref In PDParameters.LinksNotByBatchRegistrationFilter Do
					If ObjectExportAllowed(ObjectNode.Ref, Ref) Then
						RefsCollection.Add(Ref);
					EndIf;
				EndDo;
			EndIf;
			
			RegisteredData[ItemMetadata] = RefsCollection;
			
		ElsIf Common.IsConstant(ItemMetadata) Then
			
			ConstantValueManager = Constants[ItemMetadata.Name].CreateValueManager();
			If ObjectExportAllowed(ObjectNode.Ref, ConstantValueManager) Then
				RegisteredData[ItemMetadata] = ConstantValueManager;
			EndIf;
			
		Else // 
		
			FiltersTable1 = New ValueTable;
			
			ObjectManager = Common.ObjectManagerByFullName(FullMetadataObjectName);
			
			DataSet = RegisteredDataOfSingleType(ObjectNode.Ref, FullMetadataObjectName);
			
			RecordSet = ObjectManager.CreateRecordSet(); // 
			For Each FilterElement In RecordSet.Filter Do
				If DataSet.Columns.Find(FilterElement.Name) <> Undefined Then
					FiltersTable1.Columns.Add(FilterElement.Name);
				EndIf;
			EndDo;
			
			For Each DataString In DataSet Do
				
				RecordSet = ObjectManager.CreateRecordSet(); // 
				For Each FilterElement In FiltersTable1.Columns Do
					DataExchangeInternal.SetFilterItemValue(
						RecordSet.Filter, FilterElement.Name, DataString[FilterElement.Name]);
				EndDo;
				
				RecordSet.Read();
				
				If ObjectExportAllowed(ObjectNode.Ref, RecordSet) Then
					FilterStructure1 = FiltersTable1.Add();
					FillPropertyValues(FilterStructure1, DataString);
				EndIf;
				
			EndDo;
			
			RegisteredData[ItemMetadata] = FiltersTable1;
			
		EndIf;
		
	EndDo;
	
	ObjectNode.AdditionalProperties.Insert("ObjectsRegisteredForExport", RegisteredData);
	
EndProcedure

Function ObjectExportAllowed(ExchangeNode, Object)
	
	If Common.RefTypeValue(Object) Then
		Return DataExchangeServer.RefExportAllowed(ExchangeNode, Object);
	EndIf;
	
	Send = DataItemSend.Auto;
	OnSendDataToRecipient(Object, Send, , ExchangeNode);
	Return Send = DataItemSend.Auto;
EndFunction

Procedure CancelSendNodeDataInDistributedInfobase(Source, DataElement, Ignore) Export
	
	If Not DataExchangeCached.IsSSLDataExchangeNode(Source.Ref) Then
		Return;
	EndIf;
	
	If Not DataElement.ThisNode Then
		If Common.DataSeparationEnabled() Then
			// 
			// 
			// 
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			If ModuleSaaSOperations.IsSeparatedMetadataObject(Source.Metadata().FullName(),
				ModuleSaaSOperations.MainDataSeparator()) Then
				DataElement[ModuleSaaSOperations.MainDataSeparator()] = 0;
			EndIf;
			If ModuleSaaSOperations.IsSeparatedMetadataObject(Source.Metadata().FullName(),
				ModuleSaaSOperations.AuxiliaryDataSeparator()) Then
				DataElement[ModuleSaaSOperations.AuxiliaryDataSeparator()] = 0;
			EndIf;
		EndIf;
		
		Return;
	EndIf;
	
	Ignore = True;
	
EndProcedure

Procedure RegisterCommonNodesDataChanges(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Source.IsNew() Then
		Return;
	ElsIf Source.AdditionalProperties.Property("GettingExchangeMessage") Then
		Return; // 
	ElsIf Not DataExchangeCached.IsSeparatedSSLDataExchangeNode(Source.Ref) Then
		Return;
	ElsIf Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	CommonNodeData = DataExchangeCached.CommonNodeData(Source.Ref);
	
	If IsBlankString(CommonNodeData) Then
		Return;
	EndIf;
	
	If Source.ThisNode Then
		Return;
	EndIf;
	
	If DataDiffers1(Source, Source.Ref.GetObject(), CommonNodeData) Then
		
		InformationRegisters.CommonNodeDataChanges.RecordChanges(Source.Ref);
		
	EndIf;
	
EndProcedure

Procedure ClearRefsToInfobaseNode(Source, Cancel) Export
	
	// 
	// 
	// 
	
	If Not DataExchangeCached.IsSSLDataExchangeNode(Source.Ref) Then
		Return;
	EndIf;
	
	Catalogs.DataExchangeScenarios.ClearRefsToInfobaseNode(Source.Ref);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		If Common.SubsystemExists("CloudTechnology.JobsQueue")
			And Not Source.AdditionalProperties.Property("IsSWPMasterNode") Then
			
			ModuleJobsQueue = Common.CommonModule("JobsQueue");
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			
			JobKey = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Data exchange with external system (%1)';"),
				Source.Code);
				
			Filter = New Structure;
			Filter.Insert("DataArea", ModuleSaaSOperations.SessionSeparatorValue());
			Filter.Insert("Key",          JobKey);
			
			JobTable = ModuleJobsQueue.GetJobs(Filter);
			For Each JobRow In JobTable Do
				ModuleJobsQueue.DeleteJob(JobRow.Id);
			EndDo;
		EndIf;
		
		If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
			
			ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
			
			DataExchangeScenarios = "";
			ExchangeID = "";
			
			HasNodeScheduledExchange = ModuleDataExchangeInternalPublication.HasNodeScheduledExchange(
				Source.Ref, DataExchangeScenarios,ExchangeID);
			
			If HasNodeScheduledExchange Then
				ModuleDataExchangeInternalPublication.CancelTaskQueue(
					Source.Ref, DataExchangeScenarios, ExchangeID);
			EndIf;	
					
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(True);
	Common.DeleteDataFromSecureStorage(Source.Ref);
	SetPrivilegedMode(False);
	
EndProcedure

Procedure BeforeDeleteExchangePlan(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;

	If DataExchangeCached.IsSSLDataExchangeNode(Source.Ref)
		And Not Source.AdditionalProperties.Property("DeleteSyncSetting") Then
		
		Cancel = True;
				
	EndIf;
	
EndProcedure

#EndRegion

#Region ObjectsRegistrationMechanism

// Defines a list of nodes that are recipients of the exchange plan nameexchange Plan, for which you need to 
// register the object Object for subsequent unloading.
//
// First, using the selective object registration (VRO) mechanism, it is determined
// on which exchange plans the object should be registered for uploading.
// Then, using the object registration mechanism (for EXAMPLE, registration rules), it is determined 
// on which nodes of each exchange plan the object should be registered.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  Object - Arbitrary -  data to change: an object, a set of records, a constant, or information about deleting an object.
//  Cancel - Boolean - :
//    
//  AdditionalParameters - Structure - :
//    * IsRegister - Boolean -  a value of True means that the case is being processed.
//        Optional, the default value is False.
//    * IsObjectDeletion - Boolean -  the value True means that object deletion is being processed.
//        Optional, the default value is False.
//    * IsConstant - Boolean -  a value of True means that a constant is being processed.
//        Optional, the default value is False.
//    * WriteMode - см. в синтакс-document recording Mode - document recording mode (only for documents).
//        Optional, the default value is Undefined.
//    * Replacing - Boolean -  register recording mode (only for registers).
//        Optional, the default value is Undefined.
//
Procedure RegisterObjectChange(ExchangePlanName, Object, Cancel, AdditionalParameters = Undefined)
	
	// 
	// 
	// 
	
	OptionalParameters = New Structure;
	OptionalParameters.Insert("IsRegister", False);
	OptionalParameters.Insert("IsObjectDeletion", False);
	OptionalParameters.Insert("IsConstant", False);
	OptionalParameters.Insert("WriteMode", Undefined);
	OptionalParameters.Insert("Replacing", Undefined);
	
	If AdditionalParameters <> Undefined Then
		FillPropertyValues(OptionalParameters, AdditionalParameters);
	EndIf;
	
	IsRegister = OptionalParameters.IsRegister;
	IsObjectDeletion = OptionalParameters.IsObjectDeletion;
	IsConstant = OptionalParameters.IsConstant;
	WriteMode = OptionalParameters.WriteMode;
	Replacing = OptionalParameters.Replacing;
	
	Try
		
		SetPrivilegedMode(True);
		
		// 
		DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
		
		If Object.AdditionalProperties.Property("RegisterAtExchangePlanNodesOnUpdateIB") Then
			// 
			DisableRegistration = True;
			If Object.AdditionalProperties.RegisterAtExchangePlanNodesOnUpdateIB = Undefined Then
				// 
				// 
				If Not (IsRegister Or IsObjectDeletion Or IsConstant) And Object.IsNew() Then
					// 
					DisableRegistration = False;
				ElsIf ValueIsFilled(SessionParameters.UpdateHandlerParameters) Then
					ExchangePlanPurpose = DataExchangeCached.ExchangePlanPurpose(ExchangePlanName);
					If ExchangePlanPurpose = "DIBWithFilter" Then
						// 
						// 
						UpdateHandlerParameters = SessionParameters.UpdateHandlerParameters;
						If UpdateHandlerParameters.DeferredHandlersExecutionMode = "Parallel" Then
							DisableRegistration = UpdateHandlerParameters.RunAlsoInSubordinateDIBNodeWithFilters;
						EndIf;
					ElsIf ExchangePlanPurpose = "DIB" Then
						DisableRegistration = Not SessionParameters.UpdateHandlerParameters.ExecuteInMasterNodeOnly;
					EndIf;
				EndIf;
			ElsIf Object.AdditionalProperties.RegisterAtExchangePlanNodesOnUpdateIB Then
				// 
				DisableRegistration = False;
			EndIf;
			
			If DisableRegistration Then
				Return;
			EndIf;
		ElsIf Object.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
			// 
			Return;
		EndIf;
		
		MetadataObject = Object.Metadata();
		
		If Common.DataSeparationEnabled() Then
			
			If Not SeparatedExchangePlan(ExchangePlanName) Then
				Raise NStr("en = 'Shared exchange plans don''t support registration of changes.';");
			EndIf;
			
			If Not DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlanName) Then
				Return;
			EndIf;
			
			If Common.SubsystemExists("CloudTechnology.Core") Then
				ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
				IsSeparatedData = ModuleSaaSOperations.IsSeparatedMetadataObject(
					MetadataObject.FullName(), ModuleSaaSOperations.MainDataSeparator());
			Else
				IsSeparatedData = False;
			EndIf;
			
			If Common.SeparatedDataUsageAvailable() Then
				
				If Common.SubsystemExists("CloudTechnology.Core") Then
					ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
					IsMutuallySeparatedData = ModuleSaaSOperations.IsSeparatedMetadataObject(
						MetadataObject.FullName(), ModuleSaaSOperations.AuxiliaryDataSeparator());
				Else
					IsMutuallySeparatedData = False;
				EndIf;
				
				If Not IsSeparatedData And Not IsMutuallySeparatedData Then
					Raise NStr("en = 'Register changes of shared data in separated mode.';");
				EndIf;
				
			Else
				
				If IsSeparatedData Then
					Raise NStr("en = 'Register changes of separated data in shared mode.';");
				EndIf;
					
				// 
				// 
				// 
				RegisterChangesForAllSeparatedExchangePlanNodes(ExchangePlanName, Object);
				Return;
				
			EndIf;
			
		EndIf;
		
		// 
		If Object.AdditionalProperties.Property("RecordObjectChangeAtSenderNode") Then
			Object.DataExchange.Sender = Undefined;
		EndIf;
		
		If Not DataExchangeInternal.DataExchangeEnabled(ExchangePlanName, Object.DataExchange.Sender) Then
			Return;
		EndIf;
		
		// 
		RecordObjectToExport = IsRegister Or IsObjectDeletion Or IsConstant;
		
		ObjectIsModified = Object.AdditionalProperties.Property("DeferredWriting")
			Or Object.AdditionalProperties.Property("DeferredPosting")
			Or DataExchangeRegistrationServer.ObjectModifiedForExchangePlan(
				Object, MetadataObject, ExchangePlanName, WriteMode, RecordObjectToExport);
		
		If Not ObjectIsModified Then
			
			If DataExchangeCached.AutoRegistrationAllowed(ExchangePlanName, MetadataObject.FullName()) Then
				
				// 
				// 
				ReduceRecipients(Object, AllExchangePlanNodes(ExchangePlanName));
				
			EndIf;
			
			// 
			// 
			Return;
			
		EndIf;
		
		If Not DataExchangeCached.AutoRegistrationAllowed(ExchangePlanName, MetadataObject.FullName()) Then
			
			NodesArrayResult = New Array;
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("MetadataObject", MetadataObject);
			AdditionalParameters.Insert("IsRegister", IsRegister);
			AdditionalParameters.Insert("IsObjectDeletion", IsObjectDeletion);
			AdditionalParameters.Insert("Replacing", Replacing);
			AdditionalParameters.Insert("WriteMode", WriteMode);
			
			CheckRef1 = ?(IsRegister Or IsConstant, False, Not Object.IsNew() And Not IsObjectDeletion);
			AdditionalParameters.Insert("CheckRef1", CheckRef1);
			
			ExecuteObjectsRegistrationRulesForExchangePlan(NodesArrayResult, Object, ExchangePlanName, AdditionalParameters);
			
			If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
				ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
				ModuleDataExchangeSaaS.AfterDetermineRecipients(Object, NodesArrayResult, ExchangePlanName);
			EndIf;
			
			ExcludeRegistrationFromLoopedNodes(NodesArrayResult, Object, ExchangePlanName);
			
			SupplementRecipients(Object, NodesArrayResult);
			
		EndIf;
				
	Except
		
		TextTemplate1 = NStr("en = 'Cannot register changes in the nodes. Exchange plan: %1. Reason: %2';", Common.DefaultLanguageCode());
		DetailedPresentation = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		ErrorDescription = StrTemplate(TextTemplate1, ExchangePlanName, DetailedPresentation);
		
		WriteLogEvent(DataExchangeRegistrationServer.RegistrationRuleEventName(),
			EventLogLevel.Error, Metadata.ExchangePlans[ExchangePlanName], , ErrorDescription);
		
		Raise ErrorDescription;
		
	EndTry;
	
EndProcedure

Procedure RegisterChangesForAllSeparatedExchangePlanNodes(ExchangePlanName, Object)
	
	TextTemplate1 = "ExchangePlan.%1";
	NameOfTheStringExchangePlan = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, ExchangePlanName);
	
	QueryText =
	"SELECT
	|	ExchangePlan.Ref AS Recipient
	|FROM
	|	&ExchangePlanName AS ExchangePlan
	|WHERE
	|	ExchangePlan.RegisterChanges
	|	AND NOT ExchangePlan.ThisNode
	|	AND NOT ExchangePlan.DeletionMark";

	Query = New Query;
	Query.Text = StrReplace(QueryText, "&ExchangePlanName", NameOfTheStringExchangePlan);
	Recipients = Query.Execute().Unload().UnloadColumn("Recipient");

	For Each Recipient In Recipients Do
		Object.DataExchange.Recipients.Add(Recipient);
	EndDo;
	
EndProcedure

#EndRegion

#Region ObjectsRegistrationRules

// A wrapper procedure that executes the code of the main procedure in attempt mode
// (See ExecuteObjectsRegistrationRulesForExchangePlanAttemptException)
// .
//
// Parameters:
//  NodesArrayResult - Array -  array of nodes of exchange plan recipients of the exchange plan Name
//   that need to be registered.
//  Object - Arbitrary -  data to change: an object, a set of records, a constant, or information about deleting an object.
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  AdditionalParameters - Structure - :
//    * MetadataObject - MetadataObject -  the metadata object that the data being modified corresponds to. Obligatory.
//    * IsRegister - Boolean -  a value of True means that the case is being processed.
//        Optional, the default value is False.
//    * IsObjectDeletion - Boolean -  the value True means that object deletion is being processed.
//        Optional, the default value is False.
//    * WriteMode - см. в синтакс-document recording Mode - document recording mode (only for documents).
//        Optional, the default value is Undefined.
//    * Replacing - Boolean -  register recording mode (only for registers).
//        Optional, the default value is Undefined.
//    * CheckRef1 - Boolean -  indicates whether the version of the data should be taken into account at the time before it is changed.
//        Optional, the default value is False.
//    * Upload0 - Boolean -  this parameter defines the context for executing the registration rule.
//        True-the registration rule is executed in the context of object unloading.
//        False-the registration rule is executed in the context before the object is written.
//        Optional, the default value is False.
//
Procedure ExecuteObjectsRegistrationRulesForExchangePlan(NodesArrayResult, Object, ExchangePlanName, AdditionalParameters)

	MetadataObject = AdditionalParameters.MetadataObject;
	OptionalParameters = New Structure;
	OptionalParameters.Insert("IsRegister", False);
	OptionalParameters.Insert("IsObjectDeletion", False);
	OptionalParameters.Insert("WriteMode", Undefined);
	OptionalParameters.Insert("Replacing", False);
	OptionalParameters.Insert("CheckRef1", False);
	OptionalParameters.Insert("Upload0", False);
	FillPropertyValues(OptionalParameters, AdditionalParameters);
	
	AdditionalParameters = OptionalParameters;
	
	AdditionalParameters.Insert("MetadataObject", MetadataObject);
	
	Try
		ExecuteObjectsRegistrationRulesForExchangePlanAttemptException(NodesArrayResult, Object, ExchangePlanName, AdditionalParameters);
	Except
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot execute object registration rules for exchange plan %1.
			|Error details:
			|%2';"),
			ExchangePlanName,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Defines a list of nodes that are recipients of the exchange plan nameexchange Plan, for which you need to 
// register the object Object for subsequent unloading.
//
// Parameters:
//  NodesArrayResult - Array -  array of nodes of exchange plan recipients of the exchange plan Name
//   that need to be registered.
//  Object - Arbitrary -  data to change: an object, a set of records, a constant, or information about deleting an object.
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  AdditionalParameters - Structure - :
//    * MetadataObject - MetadataObject -  the metadata object that the data being modified corresponds to. Obligatory.
//    * IsRegister - Boolean -  a value of True means that the case is being processed. Obligatory.
//    * IsObjectDeletion - Boolean -  the value True means that object deletion is being processed. Obligatory.
//    * WriteMode - см. в синтакс-document recording Mode - document recording mode (only for documents).
//                    Obligatory.
//    * Replacing - Boolean -  register recording mode (only for registers). Obligatory.
//    * CheckRef1 - Boolean -  indicates whether the version of the data should be taken into account at the time before it is changed.
//                                 Obligatory.
//    * Upload0 - Boolean -  this parameter defines the context for executing the registration rule.
//        True-the registration rule is executed in the context of object unloading.
//        False-the registration rule is executed in the context before the object is written. Obligatory.
//
Procedure ExecuteObjectsRegistrationRulesForExchangePlanAttemptException(NodesArrayResult, Object, ExchangePlanName, AdditionalParameters)
	
	MetadataObject = AdditionalParameters.MetadataObject;
	IsRegister = AdditionalParameters.IsRegister;
	Replacing = AdditionalParameters.Replacing;
	Upload0 = AdditionalParameters.Upload0;
	
	ObjectRegistrationRules = New Array;
	
	SecurityProfileName = DataExchangeCached.SecurityProfileName(ExchangePlanName);
	If SecurityProfileName <> Undefined Then
		SetSafeMode(SecurityProfileName);
	EndIf;
	
	Rules = ObjectRegistrationRules(ExchangePlanName, MetadataObject.FullName());
	
	For Each Rule In Rules Do
		
		ObjectRegistrationRules.Add(RegistrationRuleAsStructure(Rule, Rules.Columns));
		
	EndDo;
	
	If ObjectRegistrationRules.Count() = 0 Then // 
		
		// 
		// 
		Recipients = AllExchangePlanNodes(ExchangePlanName);
		
		CommonClientServer.SupplementArray(NodesArrayResult, Recipients, True);
		
	Else // 
		
		If IsRegister Then // 
			
			For Each ORR In ObjectRegistrationRules Do
				
				// 
				
				DefineRecipientsByConditionForRecordSet(NodesArrayResult, ORR, Object, MetadataObject, ExchangePlanName, Replacing, Upload0);
				
				If ValueIsFilled(ORR.FlagAttributeName) Then
					
					// 
					
					SetPrivilegedMode(True);
					Recipients = NodesForRegistrationByExportAlwaysCondition(ExchangePlanName, ORR.FlagAttributeName);
					SetPrivilegedMode(False);
					
					CommonClientServer.SupplementArray(NodesArrayResult, Recipients, True);
					
					// 
					// 
					
				EndIf;
				
			EndDo;
			
		Else // 
			
			For Each ORR In ObjectRegistrationRules Do
					
				// 
				// 
				// 
				If ORR.BatchExecutionOfHandlers 
					And Object.AdditionalProperties.Property("CheckRegistrationBeforeUploading")
					And Not Object.AdditionalProperties.Property("InteractiveExportAddition") Then
					Continue;
				EndIf;
				
				// 
				
				DefineRecipientsByCondition(NodesArrayResult, ORR, Object, ExchangePlanName, AdditionalParameters);
				
				If ValueIsFilled(ORR.FlagAttributeName) Then
					
					// 
					
					SetPrivilegedMode(True);
					Recipients = NodesForRegistrationByExportAlwaysCondition(ExchangePlanName, ORR.FlagAttributeName);
					SetPrivilegedMode(False);
					
					CommonClientServer.SupplementArray(NodesArrayResult, Recipients, True);
					
					// 
					
					If Not Object.IsNew() Then
						
						SetPrivilegedMode(True);
						Recipients = NodesForRegistrationByExportIfNecessaryCondition(Object.Ref, ExchangePlanName, ORR.FlagAttributeName);
						SetPrivilegedMode(False);
						
						CommonClientServer.SupplementArray(NodesArrayResult, Recipients, True);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Retrieves an array of exchange plan nodes that have the "always Unload" flag set.
//
// Parameters:
//  ExchangePlanName    - String -  name of the exchange plan as the metadata object that the nodes are defined by.
//  FlagAttributeName - String -  name of the exchange plan details for which the filter is set for the selection of nodes.
//
// Returns:
//  Array - 
//
Function NodesForRegistrationByExportAlwaysCondition(Val ExchangePlanName, Val FlagAttributeName)
	
	TextTemplate1 = "ExchangePlan.%1";
	NameOfTheStringExchangePlan = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, ExchangePlanName);
	
	TextTemplateField = "ExchangePlanHeader.%1";
	TheNameOfTheFlagSPropsAsAString = StringFunctionsClientServer.SubstituteParametersToString(TextTemplateField, FlagAttributeName);
	
	QueryText = "SELECT
	|	ExchangePlanHeader.Ref AS Node
	|FROM
	|	&ExchangePlanName AS ExchangePlanHeader
	|WHERE
	|	NOT ExchangePlanHeader.ThisNode
	|	AND &FlagAttributeName = VALUE(Enum.ExchangeObjectExportModes.ExportAlways)
	|	AND NOT ExchangePlanHeader.DeletionMark";
	
	QueryText = StrReplace(QueryText, "&ExchangePlanName", NameOfTheStringExchangePlan);
	QueryText = StrReplace(QueryText, "&FlagAttributeName", TheNameOfTheFlagSPropsAsAString);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Return Query.Execute().Unload().UnloadColumn("Node");
EndFunction

// Retrieves an array of exchange plan nodes that have the "Unload if necessary" flag set.
//
// Parameters:
//  Ref - 
//  ExchangePlanName    - String -  name of the exchange plan as the metadata object that the nodes are defined by.
//  FlagAttributeName - String -  name of the exchange plan details for which the filter is set for the selection of nodes.
//
// Returns:
//  Array - 
//
Function NodesForRegistrationByExportIfNecessaryCondition(Ref, Val ExchangePlanName, Val FlagAttributeName)
	
	NodesArray = New Array;
	
	If DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName) Then
		NodesArray = DataExchangeXDTOServer.NodesArrayToRegisterExportIfNecessary(
			Ref, ExchangePlanName, FlagAttributeName);
	Else
		
		TextTemplateTable = "ExchangePlan.%1";
		NameOfTheStringExchangePlan = StringFunctionsClientServer.SubstituteParametersToString(TextTemplateTable, ExchangePlanName);
		
		TextTemplateField = "ExchangePlanHeader.%1";
		TheNameOfTheFlagSPropsAsAString = StringFunctionsClientServer.SubstituteParametersToString(TextTemplateField, FlagAttributeName);
		
		QueryText = "SELECT DISTINCT
		|	ExchangePlanHeader.Ref AS Node
		|FROM
		|	&ExchangePlanName AS ExchangePlanHeader
		|		LEFT JOIN InformationRegister.InfobaseObjectsMaps AS InfobaseObjectsMaps
		|		ON ExchangePlanHeader.Ref = InfobaseObjectsMaps.InfobaseNode
		|		AND InfobaseObjectsMaps.SourceUUID = &Object
		|WHERE
		|	NOT ExchangePlanHeader.ThisNode
		|	AND &FlagAttributeName = VALUE(Enum.ExchangeObjectExportModes.ExportIfNecessary)
		|	AND NOT ExchangePlanHeader.DeletionMark
		|	AND InfobaseObjectsMaps.SourceUUID = &Object";
		
		QueryText = StrReplace(QueryText, "&ExchangePlanName", NameOfTheStringExchangePlan);
		QueryText = StrReplace(QueryText, "&FlagAttributeName", TheNameOfTheFlagSPropsAsAString);
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Object",   Ref);
		
		NodesArray = Query.Execute().Unload().UnloadColumn("Node");
		
	EndIf;
	
	Return NodesArray;
	
EndFunction

Procedure ExecuteObjectRegistrationRuleForRecordSet(NodesArrayResult,
															ORR,
															Object,
															MetadataObject,
															ExchangePlanName,
															Replacing,
															Upload0)
	
	// 
	DefineRecipientsArrayByRecordSet(NodesArrayResult, Object, ORR, MetadataObject, ExchangePlanName, False, Upload0);
	
	If Replacing And Not Upload0 Then
		
		PreviousRecordSet = RecordSet(Object);
		
		// 
		DefineRecipientsArrayByRecordSet(NodesArrayResult, PreviousRecordSet, ORR, MetadataObject, ExchangePlanName, True, False);
		
	EndIf;
	
EndProcedure

// Defines a list of nodes that are recipients of the exchange plan nameexchange Plan, for which you need to 
// register the object Object in accordance with the ABM (universal part) for its subsequent unloading.
//
// Parameters:
//  NodesArrayResult - Array -  array of nodes of exchange plan recipients of the exchange plan Name
//   that need to be registered.
//  ORR - ValueTableRow -  contains information about the object registration rule that the procedure is being performed for.
//  Object - Arbitrary -  data to change: an object, a set of records, a constant, or information about deleting an object.
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  AdditionalParameters - Structure - :
//    * IsObjectDeletion - Boolean -  the value True means that object deletion is being processed. Obligatory.
//    * WriteMode - см. в синтакс-document recording Mode - document recording mode (only for documents).
//                    Obligatory.
//    * CheckRef1 - Boolean -  indicates whether the version of the data should be taken into account at the time before it is changed.
//                                 Obligatory.
//    * Upload0 - Boolean -  this parameter defines the context for executing the registration rule.
//        True-the registration rule is executed in the context of object unloading.
//        False-the registration rule is executed in the context before the object is written. Obligatory.
//
Procedure ExecuteObjectRegistrationRuleForReferenceType(NodesArrayResult,
															ORR,
															Object,
															ExchangePlanName,
															AdditionalParameters)
	
	IsObjectDeletion = AdditionalParameters.IsObjectDeletion;
	WriteMode = AdditionalParameters.WriteMode;
	CheckRef1 = AdditionalParameters.CheckRef1;
	Upload0 = AdditionalParameters.Upload0;
	
	// 
	// 
	// 
	
	GetConstantsAlgorithmsValues(ORR, ORR.FilterByObjectProperties);
	
	// 
	If  Not ORR.RuleByObjectPropertiesEmpty
		And Not ObjectMeetsRegistrationRulesFilterConditionsByProperties(ORR, Object, CheckRef1, WriteMode) Then
		
		Return;
		
	EndIf;
	
	// 
	// 
	DefineNodesArrayForObject(NodesArrayResult, Object, ExchangePlanName, ORR, IsObjectDeletion, CheckRef1, Upload0);
	
EndProcedure

// Defines a list of nodes that are recipients of the exchange plan nameexchange Plan, for which you need to 
// register the object Object in accordance with the ABM for its subsequent unloading.
//
// Parameters:
//  NodesArrayResult - Array -  array of nodes of exchange plan recipients of the exchange plan Name
//   that need to be registered.
//  ORR - ValueTableRow -  contains information about the object registration rule that the procedure is being performed for.
//  Object - Arbitrary -  data to change: an object, a set of records, a constant, or information about deleting an object.
//  ExchangePlanName - String -  name of the exchange plan that the registration mechanism is running for.
//  AdditionalParameters - Structure - :
//    * MetadataObject - MetadataObject -  the metadata object that the data being modified corresponds to. Obligatory.
//    * IsObjectDeletion - Boolean -  the value True means that object deletion is being processed. Obligatory.
//    * WriteMode - см. в синтакс-document recording Mode - document recording mode (only for documents).
//                    Obligatory.
//    * CheckRef1 - Boolean -  indicates whether the version of the data should be taken into account at the time before it is changed.
//                                 Obligatory.
//    * Upload0 - Boolean -  this parameter defines the context for executing the registration rule.
//        True-the registration rule is executed in the context of object unloading.
//        False-the registration rule is executed in the context before the object is written. Obligatory.
//
Procedure DefineRecipientsByCondition(NodesArrayResult, ORR, Object, ExchangePlanName, AdditionalParameters)
	
	MetadataObject = AdditionalParameters.MetadataObject;
	Upload0 = AdditionalParameters.Upload0;
	
	// 
	Cancel = False;
	
	ExecuteORRHandlerBeforeProcessing(ORR, Cancel, Object, MetadataObject, Upload0);
	
	If Cancel Then
		Return;
	EndIf;
	// 
	
	Recipients = New Array;
	
	ExecuteObjectRegistrationRuleForReferenceType(Recipients, ORR, Object, ExchangePlanName, AdditionalParameters);
	
	// 
	Cancel = False;
	
	ExecuteORRHandlerAfterProcessing(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	
	If Cancel Then
		Return;
	EndIf;
	// 
	
	CommonClientServer.SupplementArray(NodesArrayResult, Recipients, True);
	
EndProcedure

Procedure DefineRecipientsByConditionForRecordSet(NodesArrayResult,
														ORR,
														Object,
														MetadataObject,
														ExchangePlanName,
														Replacing,
														Upload0)
	
	// 
	Cancel = False;
	
	ExecuteORRHandlerBeforeProcessing(ORR, Cancel, Object, MetadataObject, Upload0);
	
	If Cancel Then
		Return;
	EndIf;
	// 
	
	Recipients = New Array;
	
	ExecuteObjectRegistrationRuleForRecordSet(Recipients, ORR, Object, MetadataObject, ExchangePlanName, Replacing, Upload0);
	
	// 
	Cancel = False;
	
	ExecuteORRHandlerAfterProcessing(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
	
	If Cancel Then
		Return;
	EndIf;
	// 
	
	CommonClientServer.SupplementArray(NodesArrayResult, Recipients, True);
	
EndProcedure

Procedure DefineNodesArrayForObject(NodesArrayResult,
										Source,
										ExchangePlanName,
										ORR,
										IsObjectDeletion,
										CheckRef1,
										Upload0)
	
	// 
	ObjectPropertiesValues = PropertiesValuesForObject(Source, ORR);
	
	// 
	NodesArray = DefineNodesArrayByPropertiesValues(ObjectPropertiesValues, ORR, ExchangePlanName, Source, Upload0);
	
	// 
	CommonClientServer.SupplementArray(NodesArrayResult, NodesArray, True);
	
	If CheckRef1 Then
		
		// 
		SetPrivilegedMode(True);
		RefPropertiesValues = PropertiesValuesForRef(Source.Ref, ORR.ObjectProperties, ORR.ObjectPropertiesAsString, ORR.MetadataObjectName3);
		SetPrivilegedMode(False);
		
		// 
		NodesArray = DefineNodesArrayByPropertiesValuesAdditional(RefPropertiesValues, ORR, ExchangePlanName, Source);
		
		// 
		CommonClientServer.SupplementArray(NodesArrayResult, NodesArray, True);
		
	EndIf;
	
EndProcedure

Procedure DefineRecipientsArrayByRecordSet(NodesArrayResult,
													RecordSet,
													ORR,
													MetadataObject,
													ExchangePlanName,
													IsObjectVersionBeforeChange,
													Upload0)
	
	// 
	Recorder = Undefined;
	
	FilterElement = RecordSet.Filter.Find("Recorder");
	
	HasRecorder = FilterElement <> Undefined;
	
	If HasRecorder Then
		
		Recorder = FilterElement.Value;
		
	EndIf;
	
	ORRSetRows = CopyStructure(ORR);
	GetConstantsAlgorithmsValues(ORRSetRows, ORRSetRows.FilterByObjectProperties);
	
	For Each SetRow In RecordSet Do
		
		If HasRecorder And SetRow["Recorder"] = Undefined Then
			
			If Recorder <> Undefined Then
				
				SetRow["Recorder"] = Recorder;
				
			EndIf;
			
		EndIf;
		
		// 
		If Not ObjectMeetsRegistrationRulesFilterConditionsByProperties(ORRSetRows, SetRow, False) Then
			
			Continue;
			
		EndIf;
		
		// 
		
		// 
		ObjectPropertiesValues = PropertiesValuesForObject(SetRow, ORRSetRows);
		
		If IsObjectVersionBeforeChange Then
			
			// 
			NodesArray = DefineNodesArrayByPropertiesValuesAdditional(ObjectPropertiesValues,
				ORRSetRows, ExchangePlanName, SetRow, RecordSet.AdditionalProperties);
			
		Else
			
			// 
			NodesArray = DefineNodesArrayByPropertiesValues(ObjectPropertiesValues, ORRSetRows,
				ExchangePlanName, SetRow, Upload0, RecordSet.AdditionalProperties);
			
		EndIf;
		
		// 
		CommonClientServer.SupplementArray(NodesArrayResult, NodesArray, True);
		
	EndDo;
	
EndProcedure

// Returns a structure with the object property values obtained by the request from the is.
// Key structure - property name; Value is the property value of the object.
//
// Parameters:
//  Ref - 
//
// Returns:
//  Structure - 
//
Function PropertiesValuesForRef(Ref, ObjectProperties, Val ObjectPropertiesAsString, Val MetadataObjectName3)
	
	PropertiesValues = CopyStructure(ObjectProperties);
	
	If PropertiesValues.Count() = 0 Then
		
		Return PropertiesValues; // 
		
	EndIf;
	
	QueryText = 
	"SELECT
	|	&ObjectPropertiesAsString
	|FROM
	|	&MetadataObjectName3 AS Table
	|WHERE
	|	Table.Ref = &Ref";
	
	QueryText = StrReplace(QueryText, "&ObjectPropertiesAsString", ObjectPropertiesAsString);
	QueryText = StrReplace(QueryText, "&MetadataObjectName3",    MetadataObjectName3);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", Ref);
	
	Try
		
		Selection = Query.Execute().Select();
		
	Except
		MessageString = NStr("en = 'An error occurred when receiving reference properties. Query execution error: [ErrorDescription]';");
		MessageString = StrReplace(MessageString, "[ErrorDescription]", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise MessageString;
	EndTry;
	
	If Selection.Next() Then
		
		For Each Item In PropertiesValues Do
			
			PropertiesValues[Item.Key] = Selection[Item.Key];
			
		EndDo;
		
	EndIf;
	
	Return PropertiesValues;
EndFunction

Function DefineNodesArrayByPropertiesValues(PropertiesValues, ORR, Val ExchangePlanName, Object, Val Upload0, AdditionalProperties = Undefined)
	
	UseCache = True;
	QueryText = ORR.QueryText;
	
	// 
	Cancel = False;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("QueryText", QueryText);
	AdditionalParameters.Insert("QueryOptions", PropertiesValues);
	AdditionalParameters.Insert("UseCache", UseCache);
	AdditionalParameters.Insert("Upload0", Upload0);
	AdditionalParameters.Insert("AdditionalProperties", AdditionalProperties);
	
	ExecuteORRHandlerOnProcessing(Cancel, ORR, Object, AdditionalParameters);
	
	QueryText = AdditionalParameters.QueryText;
	PropertiesValues = AdditionalParameters.QueryOptions;
	UseCache = AdditionalParameters.UseCache;
	
	If Cancel Then
		Return New Array;
	EndIf;
	// 
	
	If UseCache Then
		
		Return DataExchangeCached.NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, ORR.FlagAttributeName, Upload0);
		
	Else
		
		SetPrivilegedMode(True);
		Return NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, ORR.FlagAttributeName, Upload0);
		
	EndIf;
	
EndFunction

Function DefineNodesArrayByPropertiesValuesAdditional(PropertiesValues, ORR, Val ExchangePlanName, Object, AdditionalProperties = Undefined)
	
	UseCache = True;
	QueryText = ORR.QueryText;
	
	// 
	Cancel = False;
	
	ExecuteORRHandlerOnProcessingAdditional(Cancel, ORR, Object, QueryText, PropertiesValues, UseCache, AdditionalProperties);
	
	If Cancel Then
		Return New Array;
	EndIf;
	// 
	
	If UseCache Then
		
		Return DataExchangeCached.NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, ORR.FlagAttributeName);
		
	Else
		
		SetPrivilegedMode(True);
		Return NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, ORR.FlagAttributeName);
		
	EndIf;
	
EndFunction

// Returns an array of exchange plan nodes based on the specified request parameters and the request text for the exchange plan table.
//
//
Function NodesArrayByPropertiesValues(PropertiesValues, Val QueryText, Val ExchangePlanName, Val FlagAttributeName, Val Upload0 = False) Export
	
	// 
	NodesArrayResult = New Array;
	
	// 
	QueryText = StrReplace(QueryText, "[FilterCriterionByFlagAttribute]", "AND &FilterCriterionByFlagAttribute");
	
	// 
	Query = New Query;
	
	QueryText = StrReplace(QueryText, "[MandatoryConditions]",
				"AND    ExchangePlanMainTable.Ref <> &" + ExchangePlanName + "ThisNode
				|AND NOT ExchangePlanMainTable.DeletionMark
				|AND &FilterCriterionByFlagAttribute
				|");
	//
	If IsBlankString(FlagAttributeName) Then
		
		QueryText = StrReplace(QueryText, "&FilterCriterionByFlagAttribute", "TRUE");
		
	Else
		
		If Upload0 Then
			QueryText = StrReplace(QueryText, "&FilterCriterionByFlagAttribute",
				"(ExchangePlanMainTable.[FlagAttributeName] = VALUE(Enum.ExchangeObjectExportModes.ExportByCondition)
				|OR ExchangePlanMainTable.[FlagAttributeName] = VALUE(Enum.ExchangeObjectExportModes.ManualExport)
				|OR ExchangePlanMainTable.[FlagAttributeName] = VALUE(Enum.ExchangeObjectExportModes.EmptyRef))");
		Else
			QueryText = StrReplace(QueryText, "&FilterCriterionByFlagAttribute",
				"(ExchangePlanMainTable.[FlagAttributeName] = VALUE(Enum.ExchangeObjectExportModes.ExportByCondition)
				|OR ExchangePlanMainTable.[FlagAttributeName] = VALUE(Enum.ExchangeObjectExportModes.EmptyRef))");
		EndIf;
		
		QueryText = StrReplace(QueryText, "[FlagAttributeName]", FlagAttributeName);
		
	EndIf;
	
	// 
	Query.Text = QueryText;
	
	Query.SetParameter(ExchangePlanName + "ThisNode", DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName));
	
	// 
	For Each Item In PropertiesValues Do
		
		Query.SetParameter("ObjectProperty1_" + Item.Key, Item.Value);
		
	EndDo;
	
	Try
		
		NodesArrayResult = Query.Execute().Unload().UnloadColumn("Ref");
		
	Except
		MessageString = NStr("en = 'An error occurred when receiving the list of destination nodes. Query execution error: [ErrorDescription]';");
		MessageString = StrReplace(MessageString, "[ErrorDescription]", ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise MessageString;
	EndTry;
	
	Return NodesArrayResult;
EndFunction

Function PropertiesValuesForObject(Object, ORR)
	
	PropertiesValues = New Structure;
	
	For Each Item In ORR.ObjectProperties Do
		
		PropertiesValues.Insert(Item.Key, ObjectPropertyValue(Object, Item.Value));
		
	EndDo;
	
	Return PropertiesValues;
	
EndFunction

Function ObjectPropertyValue(Object, ObjectPropertiesString)
	
	Value = Object;
	
	SubstringsArray = StrSplit(ObjectPropertiesString, ".");
	
	// 
	For Each PropertyName In SubstringsArray Do
		
		Value = Value[PropertyName];
		
		If Value = Undefined Then
			Return Undefined;
		EndIf;
		
	EndDo;
	
	Return Value;
	
EndFunction

// Returns:
//   ValueTable - 
//
Function ExchangePlanObjectsRegistrationRules(Val ExchangePlanName) Export
	
	Return DataExchangeCached.ExchangePlanObjectsRegistrationRules(ExchangePlanName);
	
EndFunction

Function ObjectRegistrationRules(Val ExchangePlanName, Val FullObjectName) Export
	
	Return DataExchangeCached.ObjectRegistrationRules(ExchangePlanName, FullObjectName);
	
EndFunction

Function RegistrationRuleAsStructure(Rule, Columns)
	
	Result = New Structure;
	
	For Each Column In Columns Do
		
		Var_Key = Column.Name;
		Value = Rule[Var_Key];
		
		If TypeOf(Value) = Type("ValueTable") Then
			
			Result.Insert(Var_Key, Value.Copy());
			
		ElsIf TypeOf(Value) = Type("ValueTree") Then
			
			Result.Insert(Var_Key, Value.Copy());
			
		ElsIf TypeOf(Value) = Type("Structure") Then
			
			Result.Insert(Var_Key, CopyStructure(Value));
			
		Else
			
			Result.Insert(Var_Key, Value);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function SeparatedExchangePlan(Val ExchangePlanName)
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedData = ModuleSaaSOperations.IsSeparatedMetadataObject(
			"ExchangePlan." + ExchangePlanName, ModuleSaaSOperations.MainDataSeparator());
	Else
		IsSeparatedData = False;
	EndIf;
	
	Return IsSeparatedData;
	
EndFunction

// Creates a set of entries for the register.
//
// Parameters:
//  MetadataObject register - to get a set of records.
//
// Returns:
//  НаборЗаписей - 
//    
//
Function RecordSetByType(MetadataObject)
	
	If Common.IsInformationRegister(MetadataObject) Then
		
		Result = InformationRegisters[MetadataObject.Name].CreateRecordSet();
		
	ElsIf Common.IsAccumulationRegister(MetadataObject) Then
		
		Result = AccumulationRegisters[MetadataObject.Name].CreateRecordSet();
		
	ElsIf Common.IsAccountingRegister(MetadataObject) Then
		
		Result = AccountingRegisters[MetadataObject.Name].CreateRecordSet();
		
	ElsIf Common.IsCalculationRegister(MetadataObject) Then
		
		Result = CalculationRegisters[MetadataObject.Name].CreateRecordSet();
		
	ElsIf Common.IsSequence(MetadataObject) Then
		
		Result = Sequences[MetadataObject.Name].CreateRecordSet();
		
	ElsIf Common.IsCalculationRegister(MetadataObject.Parent())
		And Metadata.CalculationRegisters[MetadataObject.Parent().Name].Recalculations.Contains(MetadataObject) Then
		
		Result = CalculationRegisters[MetadataObject.Parent().Name].Recalculations[MetadataObject.Name].CreateRecordSet();
		
	Else
		
		MessageString = NStr("en = 'Metadata object %1 cannot have a record set.';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, MetadataObject.FullName());
		Raise MessageString;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region RegistrationRulesByObjectsProperties

Procedure FillPropertiesValuesFromObject(ValueTree, Object)
	
	For Each TreeRow In ValueTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			FillPropertiesValuesFromObject(TreeRow, Object);
			
		Else
			
			TreeRow.PropertyValue = ObjectPropertyValue(Object, TreeRow.ObjectProperty1);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Parameters:
//   Object - Arbitrary
//   DestinationValueTree - ValueTree
//   SourceValueTree - ValueTree
//
Procedure CreateValidFilterByProperties(Object, DestinationValueTree, SourceValueTree)
	
	For Each SourceTreeRow In SourceValueTree.Rows Do
		
		If SourceTreeRow.IsFolder Then
			
			DestinationTreeRow = DestinationValueTree.Rows.Add();
			
			FillPropertyValues(DestinationTreeRow, SourceTreeRow);
			
			CreateValidFilterByProperties(Object, DestinationTreeRow, SourceTreeRow);
			
		Else
			
			If PropertiesChainValid(Object, SourceTreeRow.ObjectProperty1) Then
				
				DestinationTreeRow = DestinationValueTree.Rows.Add();
				
				FillPropertyValues(DestinationTreeRow, SourceTreeRow);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Purposes for getting values of constants that are calculated using arbitrary expressions.
// Values are calculated in privileged mode.
//
Procedure GetConstantsAlgorithmsValues(ORR, ValueTree)
	
	For Each TreeRow In ValueTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			GetConstantsAlgorithmsValues(ORR, TreeRow);
			
		Else
			
			If TreeRow.FilterItemKind = DataExchangeServer.FilterItemPropertyValueAlgorithm() Then
				
				Value = Undefined;
				
				Try
					
					#If ExternalConnection Or ThickClientOrdinaryApplication Then
						
						ExecuteHandlerInPrivilegedMode(Value, TreeRow.ConstantValue);
						
					#Else
						
						SetPrivilegedMode(True);
						Execute(TreeRow.ConstantValue);
						SetPrivilegedMode(False);
						
					#EndIf
					
				Except
					
					MessageString = NStr("en = 'An error occurred while calculating a constant value:
												|Exchange plan: [ExchangePlanName]
												|Metadata object: [MetadataObjectName3]
												|Error details: [LongDesc]
												|Algorithm:
												|// {Algorithm beginning} 
												|[ConstantValue]
												|// {Algorithm end}';");
					MessageString = StrReplace(MessageString, "[ExchangePlanName]",      ORR.ExchangePlanName);
					MessageString = StrReplace(MessageString, "[MetadataObjectName3]", ORR.MetadataObjectName3);
					MessageString = StrReplace(MessageString, "[LongDesc]",            ErrorInfo().Description);
					MessageString = StrReplace(MessageString, "[ConstantValue]",   String(TreeRow.ConstantValue));
					
					Raise MessageString;
					
				EndTry;
				
				TreeRow.ConstantValue = Value;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function PropertiesChainValid(Object, Val ObjectPropertiesString)
	
	Value = Object;
	
	SubstringsArray = StrSplit(ObjectPropertiesString, ".");
	
	// 
	For Each PropertyName In SubstringsArray Do
		
		Try
			Value = Value[PropertyName];
		Except
			Return False;
		EndTry;
		
	EndDo;
	
	Return True;
EndFunction

// We perform TESTS for the link and for the object.
// The result is taken into account by the "OR" condition.
// If the object passed the SAMPLE filter for the values from the link,
// then we don't perform any more SAMPLES for the object values.
//
Function ObjectMeetsRegistrationRulesFilterConditionsByProperties(ORR, Object, CheckRef1, WriteMode = Undefined)
	
	InitialValueOfPostedProperty = Undefined;
	
	If WriteMode <> Undefined Then
		
		InitialValueOfPostedProperty = Object.Posted;
		
		If WriteMode = DocumentWriteMode.UndoPosting Then
			
			Object.Posted = False;
			
		ElsIf WriteMode = DocumentWriteMode.Posting Then
			
			Object.Posted = True;
			
		EndIf;
		
	EndIf;
	
	// 
	If ObjectPassesORROPFilter(ORR, Object) Then
		
		If InitialValueOfPostedProperty <> Undefined Then
			
			Object.Posted = InitialValueOfPostedProperty;
			
		EndIf;
		
		Return True;
		
	EndIf;
	
	If InitialValueOfPostedProperty <> Undefined Then
		
		Object.Posted = InitialValueOfPostedProperty;
		
	EndIf;
	
	If CheckRef1 Then
		
		// 
		If ObjectPassesORROPFilter(ORR, Object.Ref) Then
			
			Return True;
			
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Function ObjectPassesORROPFilter(ORR, Object)
	
	ORR.SelectionByProperties = DataProcessors.ObjectsRegistrationRulesImport.FilterByObjectPropertiesTableInitialization();
	
	CreateValidFilterByProperties(Object, ORR.SelectionByProperties, ORR.FilterByObjectProperties);
	
	FillPropertiesValuesFromObject(ORR.SelectionByProperties, Object);
	
	Return ConditionIsTrueForValueTreeBranch(ORR.SelectionByProperties);
	
EndFunction

// By default, we assume that the selection elements of the root group are compared by the "And" condition.
// This is why the this Operator parameter is set to True by default.
//
Function ConditionIsTrueForValueTreeBranch(ValueTree, Val IsANDOperator = True)
	
	// Initialize
	If IsANDOperator Then // And
		Result = True;
	Else // Or
		Result = False;
	EndIf;
	
	For Each TreeRow In ValueTree.Rows Do
		
		If TreeRow.IsFolder Then
			
			ItemResult = ConditionIsTrueForValueTreeBranch(TreeRow, TreeRow.IsANDOperator);
		Else
			
			ItemResult = ConditionTrueForItem(TreeRow, IsANDOperator);
		EndIf;
		
		If IsANDOperator Then // And
			
			Result = Result And ItemResult;
			
			If Not Result Then
				Return False;
			EndIf;
			
		Else // Or
			
			Result = Result Or ItemResult;
			
			If Result Then
				Return True;
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function ConditionTrueForItem(TreeRow, IsANDOperator)
	
	RuleComparisonKind = TreeRow.ComparisonType;
	
	Try
		
		If      RuleComparisonKind = "Equal"          Then Return TreeRow.PropertyValue =  TreeRow.ConstantValue;
		ElsIf RuleComparisonKind = "NotEqual"        Then Return TreeRow.PropertyValue <> TreeRow.ConstantValue;
		ElsIf RuleComparisonKind = "Greater"         Then Return TreeRow.PropertyValue >  TreeRow.ConstantValue;
		ElsIf RuleComparisonKind = "GreaterOrEqual" Then Return TreeRow.PropertyValue >= TreeRow.ConstantValue;
		ElsIf RuleComparisonKind = "Less"         Then Return TreeRow.PropertyValue <  TreeRow.ConstantValue;
		ElsIf RuleComparisonKind = "LessOrEqual" Then Return TreeRow.PropertyValue <= TreeRow.ConstantValue;
		EndIf;
		
	Except
		
		Return False;
		
	EndTry;
	
	Return False;
	
EndFunction

#EndRegion

#Region ObjectsRegistrationRulesEvents

Procedure ExecuteORRHandlerBeforeProcessing(ORR, Cancel, Object, MetadataObject, Val Upload0)
	
	If ORR.HasBeforeProcessHandler Then
		
		Try
			If ValueIsFilled(ORR.RegistrationManagerName) Then
			 	Manager = Common.CommonModule(ORR.RegistrationManagerName);
				Manager.BeforeProcess(ORR, Cancel, Object, MetadataObject, Upload0);
			Else
				Execute(ORR.BeforeProcess);
			EndIf;
		Except
			Raise DetailedHandlerExecutionErrorPresentation(
				"BeforeProcess",
				ORR.ExchangePlanName,
				ORR.MetadataObjectName3,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure ExecuteORRHandlerOnProcessing(Cancel, ORR, Object, AdditionalParameters)
	
	QueryText = AdditionalParameters.QueryText;
	QueryOptions = AdditionalParameters.QueryOptions;
	UseCache = AdditionalParameters.UseCache;
	Upload0 = AdditionalParameters.Upload0;
	AdditionalProperties = AdditionalParameters.AdditionalProperties;
	
	If ORR.HasOnProcessHandler Then
		
		Try
			If ValueIsFilled(ORR.RegistrationManagerName) Then
			 	Manager = Common.CommonModule(ORR.RegistrationManagerName);
				Manager.OnProcess(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, Upload0, AdditionalProperties);
			Else
				Execute(ORR.OnProcess);
			EndIf;
		Except
			Raise DetailedHandlerExecutionErrorPresentation(
				"OnProcess",
				ORR.ExchangePlanName,
				ORR.MetadataObjectName3,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
	AdditionalParameters.QueryText = QueryText;
	AdditionalParameters.QueryOptions = QueryOptions;
	AdditionalParameters.UseCache = UseCache;
	
EndProcedure

Procedure ExecuteORRHandlerOnProcessingAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties = Undefined)
	
	If ORR.HasOnProcessHandlerAdditional Then
		
		Try
			If ValueIsFilled(ORR.RegistrationManagerName) Then
				Manager = Common.CommonModule(ORR.RegistrationManagerName);
				Manager.OnProcessAdditional(Cancel, ORR, Object, QueryText, QueryOptions, UseCache, AdditionalProperties);
			Else
				Execute(ORR.OnProcessAdditional);
			EndIf;
		Except
			Raise DetailedHandlerExecutionErrorPresentation(
				"OnProcessAdditional",
				ORR.ExchangePlanName,
				ORR.MetadataObjectName3,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
EndProcedure

Procedure ExecuteORRHandlerAfterProcessing(ORR, Cancel, Object, MetadataObject, Recipients, Val Upload0)
	
	If ORR.HasAfterProcessHandler Then
		
		Try
			If ValueIsFilled(ORR.RegistrationManagerName) Then
			 	Manager = Common.CommonModule(ORR.RegistrationManagerName);
				Manager.AfterProcess(ORR, Cancel, Object, MetadataObject, Recipients, Upload0);
			Else
				Execute(ORR.AfterProcess);
			EndIf;
		Except
			Raise DetailedHandlerExecutionErrorPresentation(
				"AfterProcess",
				ORR.ExchangePlanName,
				ORR.MetadataObjectName3,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
EndProcedure

Function BatchRegistrationParameters() Export

	Parameters = New Structure;
	Parameters.Insert("ThereIsPRO_WITHBatchRegistration", False);
	Parameters.Insert("ThereIsPRO_WithoutBatchRegistration",False);
	Parameters.Insert("LinksToBatchRegistrationFilter", New Array);
	Parameters.Insert("LinksNotByBatchRegistrationFilter", New Array);
	Parameters.Insert("InitialImageCreating", False);
	
	Return Parameters;
	
EndFunction

Procedure PerformBatchRegistrationForNode(Node, ReferencesArrray, Parameters) Export
	
	If ReferencesArrray.Count() = 0 Then
		Return;
	EndIf;
		
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Node);
	FullObjectName = ReferencesArrray[0].Metadata().FullName();
	
	ObjectExportMode = DataExchangeCached.ObjectExportMode(FullObjectName, Node);
	
	If ObjectExportMode = Enums.ExchangeObjectExportModes.ExportAlways Then
		
		Parameters.LinksToBatchRegistrationFilter = ReferencesArrray;
		
	Else
	
		Rules = ObjectRegistrationRules(ExchangePlanName, FullObjectName);
			
		For Each ORR In Rules Do
			If ORR.BatchExecutionOfHandlers Then
				
				ArrayOfLinksAbout = Common.CopyRecursive(ReferencesArrray, False);
				PerformBatchRegistrationForNodeAttemptException(ORR, ArrayOfLinksAbout, Node);
				CommonClientServer.SupplementArray(Parameters.LinksToBatchRegistrationFilter, ArrayOfLinksAbout, True);
				
				Parameters.ThereIsPRO_WITHBatchRegistration = True;
				
			Else
				
				Parameters.ThereIsPRO_WithoutBatchRegistration = True;
				
			EndIf;
		EndDo;
		
		If Not Parameters.ThereIsPRO_WITHBatchRegistration Then
			
			Parameters.LinksNotByBatchRegistrationFilter = ReferencesArrray;
			
		ElsIf ReferencesArrray.Count() <> Parameters.LinksToBatchRegistrationFilter.Count() Then
				
			For Each Ref In ReferencesArrray Do
				If Parameters.LinksToBatchRegistrationFilter.Find(Ref) = Undefined Then
					Parameters.LinksNotByBatchRegistrationFilter.Add(Ref);
				EndIf;
			EndDo;
		
		EndIf;
		
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		ModulePersonalDataProtection = Common.CommonModule("PersonalDataProtection");
		
		Count = Parameters.LinksToBatchRegistrationFilter.Count();
		For Cnt = 1 To Count Do
			
			IndexOf = Count - Cnt;
			Ref = Parameters.LinksToBatchRegistrationFilter[IndexOf];
			ItemSend = DataItemSend.Auto;
			ModulePersonalDataProtection.OnSendData(Ref, ItemSend, Node, Parameters.InitialImageCreating);
			
			If ItemSend = DataItemSend.Ignore Then
				Parameters.LinksToBatchRegistrationFilter.Delete(IndexOf);
			EndIf;
			
		EndDo;
		
	EndIf;
		
EndProcedure

Procedure PerformBatchRegistrationForNodeAttemptException(ORR, ReferencesArrray, Node)
	
	ExportMode = Node[ORR.FlagAttributeName];
	
	If ExportMode <> Enums.ExchangeObjectExportModes.ExportByCondition
		And ExportMode <> Enums.ExchangeObjectExportModes.ManualExport
		And ExportMode <> Enums.ExchangeObjectExportModes.EmptyRef() Then
		
		ReferencesArrray = New Array;
		Return;
		
	EndIf;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Node);
	SecurityProfileName = DataExchangeCached.SecurityProfileName(ExchangePlanName);
	If SecurityProfileName <> Undefined Then
		SetSafeMode(SecurityProfileName);
	EndIf;
	
	Try
		If ValueIsFilled(ORR.RegistrationManagerName) Then
			Manager = Common.CommonModule(ORR.RegistrationManagerName);
			Manager.BatchProcessing(ORR, ReferencesArrray, Node);
		Else
			Execute(ORR.BatchProcessing);
		EndIf;
	Except
		ReferencesArrray = New Array;
		
		Raise DetailedHandlerExecutionErrorPresentation(
			"BatchProcessing",
			ORR.ExchangePlanName,
			ORR.MetadataObjectName3,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#EndRegion

#Region AuxiliaryProceduresAndFunctions

Function DetailedHandlerExecutionErrorPresentation(HandlerName, ExchangePlanName, MetadataObjectName, ErrorPresentation)
	
	Return StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Error executing handler: ""%1"".
		|Exchange plan: %2.
		|Metadata object: %3.
		|Error details: %4.';"),
		HandlerName,
		ExchangePlanName,
		MetadataObjectName,
		ErrorPresentation);
	
EndFunction

Procedure OnSendData(DataElement, ItemSend, Val Recipient, Val InitialImageCreating, Val Analysis)
	
	If TypeOf(DataElement) = Type("ObjectDeletion") Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PersonalDataProtection") Then
		ModulePersonalDataProtection = Common.CommonModule("PersonalDataProtection");
		ModulePersonalDataProtection.OnSendData(DataElement, ItemSend, Recipient, InitialImageCreating);
	EndIf;
	
	// 
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	ObjectExportMode = DataExchangeCached.ObjectExportMode(DataElement.Metadata().FullName(), Recipient);
	
	If ObjectExportMode = Enums.ExchangeObjectExportModes.ExportAlways Then
		
		// 
		
	ElsIf ObjectExportMode = Enums.ExchangeObjectExportModes.ExportByCondition
		Or ObjectExportMode = Enums.ExchangeObjectExportModes.ExportIfNecessary Then
		
		If Not DataMatchRegistrationRulesFilter(DataElement, Recipient) Then
			
			If InitialImageCreating Then
				
				ItemSend = DataItemSend.Ignore;
				
			Else
				
				ItemSend = DataItemSend.Delete;
				
			EndIf;
			
		EndIf;
		
	ElsIf ObjectExportMode = Enums.ExchangeObjectExportModes.ManualExport Then
		
		If DataMatchRegistrationRulesFilter(DataElement, Recipient) Then
			
			If Not Analysis Then
				
				// 
				ExchangePlans.DeleteChangeRecords(Recipient, DataElement);
				
			EndIf;
			
		Else
			
			ItemSend = DataItemSend.Ignore;
			
		EndIf;
			
	ElsIf ObjectExportMode = Enums.ExchangeObjectExportModes.NotExport Then
		
		ItemSend = DataItemSend.Ignore;
		
	EndIf;
	
	If ItemSend = DataItemSend.Ignore
		And Not (DataExchangeCached.IsDistributedInfobaseNode(Recipient) And InitialImageCreating)
		And Not Analysis Then
		// 
		ExchangePlans.DeleteChangeRecords(Recipient, DataElement);
	EndIf;
	
EndProcedure

Function DataMatchRegistrationRulesFilter(DataElement, Val Recipient)
	
	Result = True;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Recipient);
	
	MetadataObject = DataElement.Metadata();
	
	If    Common.IsCatalog(MetadataObject)
		Or Common.IsDocument(MetadataObject)
		Or Common.IsChartOfCharacteristicTypes(MetadataObject)
		Or Common.IsChartOfAccounts(MetadataObject)
		Or Common.IsChartOfCalculationTypes(MetadataObject)
		Or Common.IsBusinessProcess(MetadataObject)
		Or Common.IsTask(MetadataObject) Then
		
		// 
		NodesArrayForObjectRegistration = New Array;
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("MetadataObject", MetadataObject);
		AdditionalParameters.Insert("Upload0", True);
		ExecuteObjectsRegistrationRulesForExchangePlan(NodesArrayForObjectRegistration,
														DataElement,
														ExchangePlanName,
														AdditionalParameters);
		//
		
		// 
		If NodesArrayForObjectRegistration.Find(Recipient) = Undefined Then
			
			Result = False;
			
		EndIf;
		
	ElsIf Common.IsRegister(MetadataObject) Then
		
		ExcludeProperties = ?(Common.IsAccumulationRegister(MetadataObject), "RecordType", "");
		
		DataToCheck = RecordSetByType(MetadataObject);
		
		For Each SourceFilterItem In DataElement.Filter Do
			
			DestinationFilterItem = DataToCheck.Filter.Find(SourceFilterItem.Name);
			
			FillPropertyValues(DestinationFilterItem, SourceFilterItem);
			
		EndDo;
		
		DataToCheck.Add();
		
		ReverseIndex = DataElement.Count() - 1;
		
		While ReverseIndex >= 0 Do
			
			FillPropertyValues(DataToCheck[0], DataElement[ReverseIndex],, ExcludeProperties);
			
			// 
			NodesArrayForObjectRegistration = New Array;
			
			AdditionalParameters = New Structure;
			AdditionalParameters.Insert("MetadataObject", MetadataObject);
			AdditionalParameters.Insert("IsRegister", True);
			AdditionalParameters.Insert("Upload0", True);
			ExecuteObjectsRegistrationRulesForExchangePlan(NodesArrayForObjectRegistration,
															DataToCheck,
															ExchangePlanName,
															AdditionalParameters);
			
			// 
			If NodesArrayForObjectRegistration.Find(Recipient) = Undefined Then
				
				DataElement.Delete(ReverseIndex);
				
			EndIf;
			
			ReverseIndex = ReverseIndex - 1;
			
		EndDo;
		
		If DataElement.Count() = 0 Then
			
			Result = False;
			
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

// Fills in the values of details and table parts of the same type of information database objects.
//
// Parameters:
//  Source - 
//   
//
//  
//  
//
//  ListOfProperties - String -  a comma-separated list of object properties and table parts.
//                           If the parameter is set, the object properties will
//                           be filled in according to the specified properties.
//                           ExcludeProperties it will be ignored.
//
//  Exclusionproperties-String-a comma-separated list of object properties and table parts.
//                           If this parameter is set, the object properties will be filled
//                           in for all properties and table parts, excluding the specified properties.
//
Procedure FillObjectPropertiesValues(Receiver, Source, Val ListOfProperties = Undefined, Val ExcludeProperties = Undefined) Export
	
	If ListOfProperties <> Undefined Then
		
		ListOfProperties = StrReplace(ListOfProperties, " ", "");
		
		ListOfProperties = StrSplit(ListOfProperties, ",");
		
		MetadataObject = Receiver.Metadata();
		
		TabularSections = ObjectTabularSections(MetadataObject);
		
		HeaderPropertiesList = New Array;
		UsedTabularSections = New Array;
		
		For Each Property In ListOfProperties Do
			
			If TabularSections.Find(Property) <> Undefined Then
				
				UsedTabularSections.Add(Property);
				
			Else
				
				HeaderPropertiesList.Add(Property);
				
			EndIf;
			
		EndDo;
		
		HeaderPropertiesList = StrConcat(HeaderPropertiesList, ",");
		
		FillPropertyValues(Receiver, Source, HeaderPropertiesList);
		
		For Each TabularSection In UsedTabularSections Do
			
			Receiver[TabularSection].Load(Source[TabularSection].Unload());
			
		EndDo;
		
	ElsIf ExcludeProperties <> Undefined Then
		
		FillPropertyValues(Receiver, Source,, ExcludeProperties);
		
		MetadataObject = Receiver.Metadata();
		
		TabularSections = ObjectTabularSections(MetadataObject);
		
		For Each TabularSection In TabularSections Do
			
			If StrFind(ExcludeProperties, TabularSection) <> 0 Then
				Continue;
			EndIf;
			
			Receiver[TabularSection].Load(Source[TabularSection].Unload());
			
		EndDo;
		
	Else
		
		FillPropertyValues(Receiver, Source);
		
		MetadataObject = Receiver.Metadata();
		
		TabularSections = ObjectTabularSections(MetadataObject);
		
		For Each TabularSection In TabularSections Do
			
			Receiver[TabularSection].Load(Source[TabularSection].Unload());
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
//   Object - CatalogObject
//          - DocumentObject
//          - Arbitrary -  an object of the reference type.
//   ReferenceTypeAttributesTable - ValueTable
//
Procedure RegisterReferenceTypeObjectsByNodeProperties(Object, ReferenceTypeAttributesTable)
	
	InfobaseNode = Object.Ref;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	For Each TableRow In ReferenceTypeAttributesTable Do
		
		If IsBlankString(TableRow.TabularSectionName) Then // 
			
			For Each Item In TableRow.RegistrationAttributesStructure Do
				
				Ref = Object[Item.Key];
				
				If Not Ref.IsEmpty()
					And ExchangePlanCompositionContainsType(ExchangePlanName, TypeOf(Ref)) Then
					
					ExchangePlans.RecordChanges(InfobaseNode, Ref);
					
				EndIf;
				
			EndDo;
			
		Else // 
			
			TabularSection = Object[TableRow.TabularSectionName];
			
			For Each LineOfATabularSection In TabularSection Do
				
				For Each Item In TableRow.RegistrationAttributesStructure Do
					
					Ref = LineOfATabularSection[Item.Key];
					
					If Not Ref.IsEmpty()
						And ExchangePlanCompositionContainsType(ExchangePlanName, TypeOf(Ref)) Then
						
						ExchangePlans.RecordChanges(InfobaseNode, Ref);
						
					EndIf;
					
				EndDo;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function AttributesOfExchangePlanNodeRefType(ExchangePlanNodeObject)
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlanNodeObject.Ref);
	
	// 
	Result = DataExchangeRegistrationServer.SelectiveObjectsRegistrationRulesTableInitialization();
	
	MetadataObject = ExchangePlanNodeObject.Metadata();
	MetadataObjectFullName = MetadataObject.FullName();
	
	// 
	Attributes = ReferenceTypeAttributes(MetadataObject.Attributes, ExchangePlanName);
	
	If Attributes.Count() > 0 Then
		
		TableRow = Result.Add();
		TableRow.ObjectName                     = MetadataObjectFullName;
		TableRow.TabularSectionName              = "";
		TableRow.RegistrationAttributes           = StructureKeysToString(Attributes);
		TableRow.RegistrationAttributesStructure = CopyStructure(Attributes);
		
	EndIf;
	
	// 
	For Each TabularSection In MetadataObject.TabularSections Do
		
		Attributes = ReferenceTypeAttributes(TabularSection.Attributes, ExchangePlanName);
		
		If Attributes.Count() > 0 Then
			
			TableRow = Result.Add();
			TableRow.ObjectName                     = MetadataObjectFullName;
			TableRow.TabularSectionName              = TabularSection.Name;
			TableRow.RegistrationAttributes           = StructureKeysToString(Attributes);
			TableRow.RegistrationAttributesStructure = CopyStructure(Attributes);
			
		EndIf;
		
	EndDo;
	
	DataExchangeOverridable.WhenRedefiningAttributesOfReferenceTypeOfExchangePlanSSUBAsset(ExchangePlanNodeObject, Result);
	
	Return Result;
EndFunction

Function ReferenceTypeAttributes(Attributes, ExchangePlanName)
	
	// 
	Result = New Structure;
	
	For Each Attribute In Attributes Do
		
		TypesArray = Attribute.Type.Types();
		
		IsReference = False;
		
		For Each Type In TypesArray Do
			
			If  Common.IsReference(Type)
				And ExchangePlanCompositionContainsType(ExchangePlanName, Type) Then
				
				IsReference = True;
				
				Break;
				
			EndIf;
			
		EndDo;
		
		If IsReference Then
			
			Result.Insert(Attribute.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function ExchangePlanCompositionContainsType(ExchangePlanName, Type)
	
	Return Metadata.ExchangePlans[ExchangePlanName].Content.Contains(Metadata.FindByType(Type));
	
EndFunction

// Creates a new instance of the Structure object and fills the object with data from the specified structure.
//
// Parameters:
//  SourceStructure - Structure -  structure to get a copy of.
//
// Returns:
//  Structure - 
//
Function CopyStructure(SourceStructure) Export
	
	ResultingStructure = New Structure;
	
	For Each Item In SourceStructure Do
		
		If TypeOf(Item.Value) = Type("ValueTable") Then
			
			ResultingStructure.Insert(Item.Key, Item.Value.Copy());
			
		ElsIf TypeOf(Item.Value) = Type("ValueTree") Then
			
			ResultingStructure.Insert(Item.Key, Item.Value.Copy());
			
		ElsIf TypeOf(Item.Value) = Type("Structure") Then
			
			ResultingStructure.Insert(Item.Key, CopyStructure(Item.Value));
			
		ElsIf TypeOf(Item.Value) = Type("ValueList") Then
			
			ResultingStructure.Insert(Item.Key, Item.Value.Copy());
			
		Else
			
			ResultingStructure.Insert(Item.Key, Item.Value);
			
		EndIf;
		
	EndDo;
	
	Return ResultingStructure;
EndFunction

// Gets a string that contains the keys of the structure, separated by a separator character.
//
// Parameters:
//  Structure - Structure -  a structure whose keys are converted to a string.
//  Separator - String -  a separator that is inserted in the string between the structure keys.
//
// Returns:
//  String - 
//
Function StructureKeysToString(Structure, Separator = ",") Export
	
	Result = "";
	
	For Each Item In Structure Do
		
		SeparatorChar = ?(IsBlankString(Result), "", Separator);
		
		Result = Result + SeparatorChar + Item.Key;
		
	EndDo;
	
	Return Result;
EndFunction

// Compares versions of two objects of the same type.
//
// Parameters:
//  Data1 - CatalogObject
//          - DocumentObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - BusinessProcessObject
//          - TaskObject - 
//  Data2 - CatalogObject
//          - DocumentObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - BusinessProcessObject
//          - TaskObject - 
//  ListOfProperties - String -  a comma-separated list of object properties and table parts.
//                           If the parameter is set, the object properties will
//                           be filled in according to the specified properties, while
//                           the "Exclusionproperties" parameter will be ignored.
//  ExcludeProperties - String -    a comma-separated list of object properties and table parts.
//                           If this parameter is set, the object properties will be filled
//                           in for all properties and table parts, excluding the specified properties.
//
// Returns:
//   Boolean - 
//
Function DataDiffers1(Data1, Data2, ListOfProperties = Undefined, ExcludeProperties = Undefined) Export
	
	If TypeOf(Data1) <> TypeOf(Data2) Then
		Return True;
	EndIf;
	
	MetadataObject = Data1.Metadata(); // MetadataObject
	
	If Common.IsCatalog(MetadataObject) Then
		
		If Data1.IsFolder Then
			Object1 = Catalogs[MetadataObject.Name].CreateFolder();
		Else
			Object1 = Catalogs[MetadataObject.Name].CreateItem();
		EndIf;
		
		If Data2.IsFolder Then
			Object2 = Catalogs[MetadataObject.Name].CreateFolder();
		Else
			Object2 = Catalogs[MetadataObject.Name].CreateItem();
		EndIf;
		
	ElsIf Common.IsDocument(MetadataObject) Then
		
		Object1 = Documents[MetadataObject.Name].CreateDocument();
		Object2 = Documents[MetadataObject.Name].CreateDocument();
		
	ElsIf Common.IsChartOfCharacteristicTypes(MetadataObject) Then
		
		If Data1.IsFolder Then
			Object1 = ChartsOfCharacteristicTypes[MetadataObject.Name].CreateFolder();
		Else
			Object1 = ChartsOfCharacteristicTypes[MetadataObject.Name].CreateItem();
		EndIf;
		
		If Data2.IsFolder Then
			Object2 = ChartsOfCharacteristicTypes[MetadataObject.Name].CreateFolder();
		Else
			Object2 = ChartsOfCharacteristicTypes[MetadataObject.Name].CreateItem();
		EndIf;
		
	ElsIf Common.IsChartOfCalculationTypes(MetadataObject) Then
		
		Object1 = ChartsOfCalculationTypes[MetadataObject.Name].CreateCalculationType();
		Object2 = ChartsOfCalculationTypes[MetadataObject.Name].CreateCalculationType();
		
	ElsIf Common.IsChartOfAccounts(MetadataObject) Then
		
		Object1 = ChartsOfAccounts[MetadataObject.Name].CreateAccount();
		Object2 = ChartsOfAccounts[MetadataObject.Name].CreateAccount();
		
	ElsIf Common.IsExchangePlan(MetadataObject) Then
		
		Object1 = ExchangePlans[MetadataObject.Name].CreateNode();
		Object2 = ExchangePlans[MetadataObject.Name].CreateNode();
		
	ElsIf Common.IsBusinessProcess(MetadataObject) Then
		
		Object1 = BusinessProcesses[MetadataObject.Name].CreateBusinessProcess();
		Object2 = BusinessProcesses[MetadataObject.Name].CreateBusinessProcess();
		
	ElsIf Common.IsTask(MetadataObject) Then
		
		Object1 = Tasks[MetadataObject.Name].CreateTask();
		Object2 = Tasks[MetadataObject.Name].CreateTask();
		
	Else
		
		Raise NStr("en = 'Invalid value in [1] parameter of Common.PropertiesValuesChanged method.';");
		
	EndIf;
	
	FillObjectPropertiesValues(Object1, Data1, ListOfProperties, ExcludeProperties);
	FillObjectPropertiesValues(Object2, Data2, ListOfProperties, ExcludeProperties);
	
	Return InfobaseDataAsString(Object1) <> InfobaseDataAsString(Object2);
	
EndFunction

Function InfobaseDataAsString(Data)
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	
	WriteXML(XMLWriter, Data, XMLTypeAssignment.Explicit);
	
	Return XMLWriter.Close();
	
EndFunction

// Returns an array of table parts of the object.
//
// Parameters:
//   MetadataObject - MetadataObject - :
//     * TabularSections - MetadataObjectCollection of MetadataObjectTabularSection
//
// Returns:
//   Array of String - 
//
Function ObjectTabularSections(MetadataObject) Export
	
	Result = New Array;
	
	For Each TabularSection In MetadataObject.TabularSections Do
		
		Result.Add(TabularSection.Name);
		
	EndDo;
	
	Return Result;
EndFunction

// Parameters:
//   ExchangePlanNode - ExchangePlanObject -  the site plan of exchange.
//   Settings - Structure -  structure with the values of the settings.
//
Procedure SetValueOnNode(ExchangePlanNode, Settings)
	
	// 
	// 
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlanNode.Ref);
	
	For Each Item In Settings Do
		
		Var_Key = Item.Key;
		Value = Item.Value;
		
		If ExchangePlanNode.Metadata().Attributes.Find(Var_Key) = Undefined
			And ExchangePlanNode.Metadata().TabularSections.Find(Var_Key) = Undefined Then
			Continue;
		EndIf;
		
		If TypeOf(Value) = Type("Array") Then
			
			AttributeData = ReferenceTypeFromFirstAttributeOfExchangePlanTabularSection(ExchangePlanName, Var_Key);
			
			If AttributeData = Undefined Then
				Continue;
			EndIf;
			
			NodeTable = ExchangePlanNode[Var_Key];
			
			NodeTable.Clear();
			
			For Each TableRow In Value Do
				
				If TableRow.Use Then
					
					ObjectManager = Common.ObjectManagerByRef(AttributeData.Type.AdjustValue());
					
					AttributeValue = ObjectManager.GetRef(New UUID(TableRow.RefUUID));
					
					NodeTable.Add()[AttributeData.Name] = AttributeValue;
					
				EndIf;
				
			EndDo;
			
		ElsIf TypeOf(Value) = Type("Structure") Then
			
			FillExchangePlanNodeTable(ExchangePlanNode, Value, Var_Key);
			
		Else // 
			
			ExchangePlanNode[Var_Key] = Value;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FillExchangePlanNodeTable(Node, TabularSectionStructure, TableName)
	
	NodeTable = Node[TableName];
	
	NodeTable.Clear();
	
	For Each Item In TabularSectionStructure Do
		
		While NodeTable.Count() < Item.Value.Count() Do
			NodeTable.Add();
		EndDo;
		
		NodeTable.LoadColumn(Item.Value, Item.Key);
		
	EndDo;
	
EndProcedure

Function ReferenceTypeFromFirstAttributeOfExchangePlanTabularSection(Val ExchangePlanName, Val TabularSectionName)
	
	TabularSection = Metadata.ExchangePlans[ExchangePlanName].TabularSections[TabularSectionName];
	
	For Each Attribute In TabularSection.Attributes Do
		
		Type = Attribute.Type.Types()[0];
		
		If Common.IsReference(Type) Then
			
			Return New Structure("Name, Type", Attribute.Name, Attribute.Type);
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
EndFunction

Procedure CheckTroubleshootingOfDocumentProcessingOfEvent(Source, Cancel, PostingMode) Export
	
	// 
	// 
	// 
	
	InformationRegisters.DataExchangeResults.RecordIssueResolved(Source, Enums.DataExchangeIssuesTypes.UnpostedDocument);
	
EndProcedure

Procedure CheckObjectIssueResolvedOnWrite(Source, Cancel) Export
	
	// 
	// 
	// 
	
	InformationRegisters.DataExchangeResults.RecordIssueResolved(Source, Enums.DataExchangeIssuesTypes.BlankAttributes);
	
EndProcedure

// Gets the current value of a set of records in the information database.
//
// Parameters:
//  Data - 
//
// Returns:
//  НаборЗаписей - 
//
Function RecordSet(Val Data)
	
	MetadataObject = Data.Metadata();
	
	RecordSet = RecordSetByType(MetadataObject);
	
	For Each FilterValue In Data.Filter Do
		
		If FilterValue.Use = False Then
			Continue;
		EndIf;
		
		FIlterRow = RecordSet.Filter.Find(FilterValue.Name);
		FIlterRow.Value = FilterValue.Value;
		FIlterRow.Use = True;
		
	EndDo;
	
	RecordSet.Read();
	
	Return RecordSet;
	
EndFunction

// Checks the startup mode, sets the privileged mode, and executes the handler.
//
Procedure ExecuteHandlerInPrivilegedMode(Value, Val HandlerRow)
	
	If CurrentRunMode() = ClientRunMode.ManagedApplication Then
		Raise NStr("en = 'The method is not supported in managed application mode.';");
	EndIf;
	
	If Common.DataSeparationEnabled() Then
		Raise NStr("en = 'The method is not supported in SaaS mode.';");
	EndIf;
	
	SetPrivilegedMode(True);
	
	Execute(HandlerRow);
	
EndProcedure

// 
// 
// 
// 
//
Procedure ExchangePlanNodeModifiedByRefAttributes(ExchangePlanNodeObject, NodeCheckParameters)
	
	If ExchangePlanNodeObject = Undefined Then
		
		Return;
		
	EndIf;
	
	// 
	// 
	NodeCheckParameters.AttributesOfExchangePlanNodeRefType = AttributesOfExchangePlanNodeRefType(ExchangePlanNodeObject);
	
	For Each TableRow In NodeCheckParameters.AttributesOfExchangePlanNodeRefType Do
		
		HasObjectsVersionsChanges = DataExchangeRegistrationServer.DetermineObjectVersionsChanges(ExchangePlanNodeObject, TableRow);
		If HasObjectsVersionsChanges Then
			
			NodeCheckParameters.IsNodeModified = True;
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure ExcludeRegistrationFromLoopedNodes(NodesArrayResult, Object, ExchangePlanName)
	
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	If SSLExchangePlans.Find(ExchangePlanName) = Undefined Then
		Return;
	EndIf;
	
	MetadataObject = Object.Metadata();
	IsRefTypeObject = Common.IsRefTypeObject(MetadataObject);
	
	If Not(Object.DataExchange.Load
		Or Object.AdditionalProperties.Property("DeferredWriting")
		Or Object.AdditionalProperties.Property("DeferredPosting")) Then
		
		Return;
		
	EndIf;
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) 
		And Object.DataExchange.Sender <> Undefined Then
		
		NodeCount = NodesArrayResult.Count();
		For Cnt = 1 To NodeCount Do
			
			IndexOf = NodeCount - Cnt;
			Node = NodesArrayResult.Get(IndexOf);
			
			If Node = Object.DataExchange.Sender Then
				Continue;
			EndIf;
			
			If Not DataExchangeCached.RegistrationWhileLooping(Node) Then
				
				Record = InformationRegisters.ObjectsUnregisteredDuringLoop.CreateRecordManager();
				Record.InfobaseNode = Node;
				
				If IsRefTypeObject Then
						
					Record.Object = Object.Ref;
					Record.ObjectPresentation = Object.Ref;
						
				Else
					
					InformationRegisterKey = New Structure();
					For Each Dimension In MetadataObject.Dimensions Do
						InformationRegisterKey.Insert(Dimension.Name, Object.Filter[Dimension.Name].Value);
					EndDo; 
					
					Var_Key = MetadataObject.Name + ValueToStringInternal(InformationRegisterKey);
					Hash = New DataHashing(HashFunction.MD5);
					Hash.Append(Var_Key);	
					
					Record.InformationRegisterKey = StrReplace(String(Hash.HashSum), " ", "");
					Record.InformationRegisterName = MetadataObject.Name;
					Record.InformationRegisterChanges = New ValueStorage(InformationRegisterKey);
					
					Template = "%1: %2";
					Record.ObjectPresentation = 
						StringFunctions.FormattedString(Template, MetadataObject.Name, String(Object.Filter)); 
					
				EndIf;
				
				Record.Write(True);
					
				NodesArrayResult.Delete(IndexOf);
					
			EndIf;
			
		EndDo;
		
	EndIf;	
	
EndProcedure

#EndRegion

#Region DataChangeConflictsOnExchange

// Checks for collisions during upload
// and provides information about whether there is a collision during exchange.
// 
// Parameters:
//   DataElement - Arbitrary -  arbitrary data.
//   ItemReceive - DataItemReceive
//   Sender - ExchangePlanObject
//   IsGetDataFromMasterNode - Boolean
//
Procedure CheckDataChangesConflict(DataElement, ItemReceive, Val Sender, Val IsGetDataFromMasterNode)
	
	If TypeOf(DataElement) = Type("ObjectDeletion") Then
		
		Return;
		
	ElsIf DataElement.AdditionalProperties.Property("DataExchange") And DataElement.AdditionalProperties.DataExchange.DataAnalysis Then
		
		Return;
		
	EndIf;
	
	Sender = Sender.Ref;
	ObjectMetadata = DataElement.Metadata();
	IsReferenceType = Common.IsRefTypeObject(ObjectMetadata);
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Sender);
	If Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		And Not DataExchangeCached.ExchangePlanContainsObject(ExchangePlanName, ObjectMetadata.FullName()) Then
		Return;
	EndIf;
	
	HasConflict = ExchangePlans.IsChangeRecorded(Sender, DataElement);
	
	// 
	// 
	// 
	If HasConflict Then
		
		If IsReferenceType And Not DataElement.Ref.IsEmpty() Then
			
			ObjectInInfobase = DataElement.Ref.GetObject();
			RefExists = (ObjectInInfobase <> Undefined);
			
		Else
			RefExists = False;
			ObjectInInfobase = Undefined;
		EndIf;
		
		ObjectRowBeforeChange    = ObjectDataAsStringBeforeChange(DataElement, ObjectMetadata, IsReferenceType, RefExists, ObjectInInfobase);
		ObjectRowAfterChange = ObjectDataAsStringAfterChange(DataElement, ObjectMetadata);
		
		// 
		If ObjectRowBeforeChange = ObjectRowAfterChange Then
			
			HasConflict = False;
			
		EndIf;
		
	EndIf;
	
	If HasConflict Then
		
		DataExchangeOverridable.OnDataChangeConflict(DataElement, ItemReceive, Sender, IsGetDataFromMasterNode);
		
		If ItemReceive = DataItemReceive.Auto Then
			ItemReceive = ?(IsGetDataFromMasterNode, DataItemReceive.Accept, DataItemReceive.Ignore);
		EndIf;
		
		WriteObject = (ItemReceive = DataItemReceive.Accept);
		
		RecordWarningAboutConflictInEventLog(DataElement, ObjectMetadata, WriteObject, IsReferenceType);
		
		If Not IsReferenceType Then
			Return;
		EndIf;
			
		If DataExchangeCached.VersioningUsed(Sender) Then
			If RefExists Then
				
				If WriteObject Then
					SynchronizationWarning = NStr("en = 'The previous version (automatic conflict resolution).';");
				Else
					SynchronizationWarning = NStr("en = 'The current version (automatic conflict resolution).';");
				EndIf;
				
				ObjectVersionInfo = New Structure("SynchronizationWarning, ObjectVersionType", SynchronizationWarning, "RejectedConflictData");
				OnCreateObjectVersion(ObjectInInfobase, ObjectVersionInfo, RefExists, Sender);
				
			EndIf;
			
			ObjectVersionInfo = New Structure;
			If WriteObject Then
				ObjectVersionInfo.Insert("VersionAuthor", Sender);
				ObjectVersionInfo.Insert("ObjectVersionType", "ConflictDataAccepted");
				ObjectVersionInfo.Insert("SynchronizationWarning", NStr("en = 'The current version (automatic conflict resolution).';"));
			Else
				ObjectVersionInfo.Insert("VersionAuthor", Sender);
				ObjectVersionInfo.Insert("ObjectVersionType", "RejectedConflictData");
				ObjectVersionInfo.Insert("SynchronizationWarning", NStr("en = 'A rejected version (automatic conflict resolution).';"));
			EndIf;
			If DataExchangeCached.IsDistributedInfobaseNode(Sender) Then
				OnCreateObjectVersion(DataElement, ObjectVersionInfo, RefExists, Sender);
			Else
				DataElement.AdditionalProperties.Insert("ObjectVersionInfo", ObjectVersionInfo);
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Checks for the presence of a ban download by date.
//
// Parameters:
//   DataElement - CatalogObject
//                 - DocumentObject
//                 - InformationRegisterRecordSet -
//                   
//   ItemReceive - DataItemReceive
//   Sender   - ExchangePlanObject
//
Procedure CheckImportRestrictionByDate(DataElement, ItemReceive, Val Sender)
	
	If DataExchangeCached.IsDistributedInfobaseNode(Sender.Ref) Then
		Return;
	EndIf;
	
	IsObjectDeletion = (TypeOf(DataElement) = Type("ObjectDeletion"));
	
	If Not IsObjectDeletion
		And Common.IsConstant(DataElement.Metadata()) Then
		Return;
	EndIf;
	
	If Not IsObjectDeletion 
		And DataElement.AdditionalProperties.Property("DeleteObjectsCreatedByKeyProperties") Then
			Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDates = Common.CommonModule("PeriodClosingDates");
		
		Cancel = False;
		ErrorDescription = "";
		
		ModulePeriodClosingDates.CheckDataImportRestrictionDates(DataElement,
			Sender.Ref, Cancel, ErrorDescription);
		
		If Cancel Then
			RegisterDataImportRestrictionByDate(
				?(IsObjectDeletion, DataElement.Ref.GetObject(), DataElement), Sender, ErrorDescription);
			ItemReceive = DataItemReceive.Ignore;
		EndIf;
		
	EndIf;
	
	If Not IsObjectDeletion Then
		DataElement.AdditionalProperties.Insert("SkipPeriodClosingCheck");
	EndIf;
	
EndProcedure

// Registers the data download ban due to the set date of the data download ban
// in the log. For reference types, if there is a subsystem for versioning objects, it also
// registers it in the exchange problems monitor.
// To check if there is a date-based download ban, see the procedure
// for the general Date-change module.Check the data of the pre-loaded data.
//
// Parameters:
//  Object - an object of the reference type for which the ban is registered.
//  Salobrena Planesense - node information base from which the resulting object.
//  ErrorMessage - String -  detailed description of the reason for refusing to download.
//
Procedure RegisterDataImportRestrictionByDate(DataElement, Sender, ErrorMessage)
	
	WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
		EventLogLevel.Warning, , DataElement, ErrorMessage);
	
	If DataExchangeCached.VersioningUsed(Sender.Ref) And Common.IsRefTypeObject(DataElement.Metadata()) Then
		
		ObjectReference = DataElement.Ref;
		RefExists = Common.RefExists(ObjectReference);
		
		ObjectVersionType = "";
		If RefExists Then
			
			ObjectInInfobase = ObjectReference.GetObject();
			
			SynchronizationWarning = NStr("en = 'The object version is created by data synchronization.';");
			ObjectVersionInfo = New Structure("SynchronizationWarning", SynchronizationWarning);
			
			OnCreateObjectVersion(ObjectInInfobase, ObjectVersionInfo, RefExists, Sender);
			
			ErrorMessageString = ErrorMessage;
			ObjectVersionType = "RejectedDueToPeriodEndClosingDateObjectExistsInInfobase";
			
		Else
			
			ErrorMessageString = NStr("en = 'Cannot import %1 due to data import restriction.%2%2%3';");
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, String(DataElement), Chars.LF, ErrorMessage);
			ObjectVersionType = "RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase";
			
		EndIf;
		
		RejectedByClosingDate = New Map;
		If Not Sender.AdditionalProperties.Property("RejectedByClosingDate") Then
			Sender.AdditionalProperties.Insert("RejectedByClosingDate", RejectedByClosingDate);
		Else
			RejectedByClosingDate = Sender.AdditionalProperties.RejectedByClosingDate;
		EndIf;
		RejectedByClosingDate.Insert(ObjectReference, ObjectVersionType);
		
		ObjectVersionInfo = New Structure;
		ObjectVersionInfo.Insert("VersionAuthor", Common.ObjectManagerByRef(Sender.Ref).FindByCode(Sender.Code));
		ObjectVersionInfo.Insert("ObjectVersionType", ObjectVersionType);
		ObjectVersionInfo.Insert("Comment", "");
		ObjectVersionInfo.Insert("SynchronizationWarning", ErrorMessageString);
		
		If Common.IsDocument(DataElement.Metadata())
			And ObjectVersionType = "RejectedDueToPeriodEndClosingDateObjectDoesNotExistInInfobase" Then
			PropertyPosted = New Structure("Posted", False);
			FillPropertyValues(DataElement, PropertyPosted);
		EndIf;
		
		OnCreateObjectVersion(DataElement, ObjectVersionInfo, RefExists, Sender);
		
	EndIf;
	
EndProcedure

// Parameters:
//   Object - CatalogObject, DocumentObject, и т.п -  data element.
//   ObjectMetadata - MetadataObject -  metadata of the data element.
//   WriteObject - Boolean -  True if the object of this information system was replaced with the received object.
//   IsReferenceType - Boolean -  True if the object is of the reference type.
//
Procedure RecordWarningAboutConflictInEventLog(Object, ObjectMetadata, WriteObject, IsReferenceType)
	
	If WriteObject Then
		
		EventLogWarningText = NStr("en = 'Object synchronization conflict.
		|An object from this infobase is replaced with an object version from the peer infobase.';");
		
	Else
		
		EventLogWarningText = NStr("en = 'Object synchronization conflict.
		|An object from the peer infobase is rejected. The object in this infobase is not changed.';");
		
	EndIf;
	
	Data = ?(IsReferenceType, Object.Ref, Undefined);
		
	WriteLogEvent(DataExchangeServer.DataExchangeEventLogEvent(),
		EventLogLevel.Warning, ObjectMetadata, Data, EventLogWarningText);
	
EndProcedure

// Parameters:
//   Object - Arbitrary
//   ObjectMetadata - MetadataObject
//   IsReferenceType - Boolean
//   RefExists - Boolean
//   ObjectInInfobase - AnyRef
//               - Undefined
//
Function ObjectDataAsStringBeforeChange(Object, ObjectMetadata, IsReferenceType, RefExists, ObjectInInfobase)
	
	// 
	ObjectString = "";
	
	If IsReferenceType Then
		
		If RefExists Then
			
			// 
			ObjectString = Common.ValueToXMLString(ObjectInInfobase);
			
		Else
			
			ObjectString = NStr("en = 'Object deleted';");
			
		EndIf;
		
	ElsIf Common.IsConstant(ObjectMetadata) Then
		
		// 
		ObjectString = XMLString(Constants[ObjectMetadata.Name].Get());
		
	Else // 
		
		PreviousRecordSet = RecordSet(Object);
		ObjectString = Common.ValueToXMLString(PreviousRecordSet);
		
	EndIf;
	
	Return ObjectString;
	
EndFunction

Function ObjectDataAsStringAfterChange(Object, ObjectMetadata)
	
	// 
	ObjectString = "";
	
	If Common.IsConstant(ObjectMetadata) Then
		
		ObjectString = XMLString(Object.Value);
		
	Else
		
		ObjectString = Common.ValueToXMLString(Object);
		
	EndIf;
	
	Return ObjectString;
	
EndFunction

#EndRegion

#EndRegion