///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows you to configure the General settings of the subsystem.
//
// Parameters:
//  CommonParameters - Structure:
//      * ShouldIncludeFullStackInLongRunningOperationErrors  - Boolean -  
//               
//              
//              
//              
//      * AskConfirmationOnExit - Boolean -  
//              
//              
//      * PersonalSettingsFormName  - String - 
//      * MinPlatformVersion    - String - 
//              
//              
//              
//               
//               
//              
//      * DisableMetadataObjectsIDs - Boolean -  disables filling in the object IDs of Metadata and extension object IDs directories 
//              , as well as the procedure for uploading and loading in the rib nodes.
//              For partial embedding of individual library functions in the configuration without setting up support.
//      * RecommendedPlatformVersion              - String - 
//               
//              
//      * RecommendedRAM       - Number -  
//               
//
//    :
//      * MinPlatformVersion1    - String - 
//                                                           
//      * MustExit               - Boolean -  the initial value is False.
//
Procedure OnDetermineCommonCoreParameters(CommonParameters) Export
	
	
	
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
//
//
////
//
//	
//  
//		
//		
//  
//	
//
//
// Parameters:
//  Handlers - Map of KeyAndValue:
//    * Key     - String -  in the format of "<Oneparametric>|<Nachnominierung*>".
//                   The '* ' character is used at the end of the session parameter name and indicates
//                   that a single handler will be called to initialize all session parameters
//                   with a name beginning with the word Beginningparameterseance.
//
//    * Value - String -  in the format " <Modulename>.Setting the session parameters".
//
//  Example:
//   Handlers.Insert ("Current User", " Service User.Ustanavlivaetsya");
//
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	
	
EndProcedure

// Allows you to set the values of parameters required for the client code
// to work when running the configuration (in the event handlers before the system starts Working and before the system starts Working) 
// without additional server calls. 
// To get the values of these parameters from the client code
// See StandardSubsystemsClient.ClientParametersOnStart.
//
// Important: you must not use commands to reset the cache of reusable modules, 
// otherwise running it may lead to unpredictable errors and unnecessary server calls.
//
// Parameters:
//   Parameters - Structure - 
//                           :
//                           
//
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	
	
EndProcedure

// Allows you to set the values of parameters required for the client
// configuration code to work without additional server calls.
// To get these parameters from the client code
// See StandardSubsystemsClient.ClientRunParameters.
//
// Parameters:
//   Parameters - Structure - 
//                           :
//                           
//
Procedure OnAddClientParameters(Parameters) Export
	
	
	
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
// 
//
//  
// 
// 
//  
// 
//
Procedure BeforeStartApplication() Export

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
// 
// 
//
// Parameters:
//   RefSearchExclusions - Array - 
//       
//       
//
// Example:
//   
//   
//   
//
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  SubordinateObjects - See Common.SubordinateObjects
//
// Example:
//	Relatedexternal links = New Match;
//	Relation of a subordinate object.Paste("Polevoi");
//	Subordinate object = Subordinate objects.Add();
//	Subordinate object.Subordinate Object = Metadata.Guides.<Podchinennymi>;
//	Subordinate object.Link Fields = Link Of The Subordinate Object;
//	Subordinate object.Perform An Automatic Linkexample = True;
//
//	Relatedexternal links = new array;
//	Relation of a subordinate object.Paste("Polevoi");
//	Subordinate object = Subordinate objects.Add();
//	Subordinate object.Subordinate Object = Metadata.Guides.<Podchinennymi>;
//	Subordinate object.Link Fields = Link Of The Subordinate Object;
//	Subordinate object.Perform An Automatic Linkexample = True;
//
//	Subordinate object = Subordinate objects.Add();
//	Subordinate object.Subordinate Object = Metadata.Guides.<Podchinennymi>;
//	Subordinate object.Passveta = "Polevoi";
//	Subordinate object.Prepossession = "<Abdimomun>";
// 	
Procedure OnDefineSubordinateObjects(SubordinateObjects) Export

	

EndProcedure

// Performed after replacing the links before the objects are deleted.
// 
// Parameters:
//  Result - See Common.ReplaceReferences
//  ExecutionParameters - See Common.RefsReplacementParameters
//  SearchTable - See Common.UsageInstances
//
Procedure AfterReplaceRefs(Result, ExecutionParameters, SearchTable) Export

	

EndProcedure

// 
//  
// 
// 
//
//  
// 
//
// Parameters:
//  Total - ValueTable -  the renaming table to fill in.
//                           See Common.AddRenaming.
//
// Example:
//	
//		
//		
//
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	
	
EndProcedure

// 
//  
// 
//
//  
// 
//
// Parameters:
//   DisabledSubsystems - Map of KeyAndValue:
//     * Key - String -  name of the subsystem to disable
//     * Value - Boolean - True
//
Procedure OnDetermineDisabledSubsystems(DisabledSubsystems) Export
	
	
	
EndProcedure

// Called before loading priority data in a subordinate rib node
// and is intended for filling in the settings for placing a data exchange message or
// for implementing non-standard loading of priority data from the main rib node.
//
// Priority data includes predefined elements, as well
// as elements of the reference list of object IDs and Metadata.
//
// Parameters:
//  StandardProcessing - Boolean -  the initial value is True; if set to False, 
//                the default loading of priority data using the subsystem
//                The command will be skipped (it will also be
//                skipped if the subsystem is not in the configuration).
//
Procedure BeforeImportPriorityDataInSubordinateDIBNode(StandardProcessing) Export
	
	
	
EndProcedure

// 
//
// Parameters:
//  SupportedVersions - Structure -  the key specifies the name of the program interface,
//                                     and the values specify an array of strings with supported versions of this interface.
//
// Example:
//
//  
//  
//  
//   
//  
//  
//
Procedure OnDefineSupportedInterfaceVersions(SupportedVersions) Export
	
EndProcedure

// 
// 
// 
// 
//
// 
// 
//
// Parameters:
//   InterfaceOptions - Structure -  values of parameters of functional options set for the command interface.
//       The key of the structure element defines the parameter name, and the element value defines the current parameter value.
//
Procedure OnDetermineInterfaceFunctionalOptionsParameters(InterfaceOptions) Export
	
EndProcedure


// 
// 
// 
// 
//
// Parameters:
//  Notifications - Map of KeyAndValue:
//   * Key     - String - 
//   * Value - See ServerNotifications.NewServerNotification
//
// Example:
//	
//		
//	
//	
//	
//	
//	
//
Procedure OnAddServerNotifications(Notifications) Export
	
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
//
// Parameters:
//  Parameters - Map of KeyAndValue:
//    * Key     - String       - 
//    * Value - Arbitrary - 
//  Results - Map of KeyAndValue:
//    * Key     - String       - 
//    * Value - Arbitrary - 
//
// Example:
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
//
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Additional handler for an event of the same name that occurs when data is exchanged in a distributed information database.
// Executed after executing the library's basic algorithms.
// Fails if sending the data item was ignored earlier.
//
// Parameters:
//  Source                  - ExchangePlanObject -  the node for which the exchange is being performed.
//  DataElement             - Arbitrary - see the description of the handler of the same name in the syntax assistant.
//  ItemSend          - DataItemSend - see the description of the handler of the same name in the syntax assistant.
//  InitialImageCreating  - Boolean - see the description of the handler of the same name in the syntax assistant.
//
Procedure OnSendDataToSlave(Source, DataElement, ItemSend, InitialImageCreating) Export
	
EndProcedure

// Additional handler for an event of the same name that occurs when data is exchanged in a distributed information database.
// Executed after executing the library's basic algorithms.
// Fails if sending the data item was ignored earlier.
//
// Parameters:
//  Source          - ExchangePlanObject -  the node for which the exchange is being performed.
//  DataElement     - Arbitrary - see the description of the handler of the same name in the syntax assistant.
//  ItemSend  - DataItemSend - see the description of the handler of the same name in the syntax assistant.
//
Procedure OnSendDataToMaster(Source, DataElement, ItemSend) Export
	
EndProcedure

// Additional handler for an event of the same name that occurs when data is exchanged in a distributed information database.
// Executed after executing the library's basic algorithms.
// Not executed if getting the data item was ignored earlier.
//
// Parameters:
//  Source          - ExchangePlanObject -  the node for which the exchange is being performed.
//  DataElement     - Arbitrary - see the description of the handler of the same name in the syntax assistant.
//  ItemReceive - DataItemReceive - see the description of the handler of the same name in the syntax assistant.
//  SendBack     - Boolean - see the description of the handler of the same name in the syntax assistant.
//
Procedure OnReceiveDataFromSlave(Source, DataElement, ItemReceive, SendBack) Export
	
EndProcedure

// Additional handler for an event of the same name that occurs when data is exchanged in a distributed information database.
// Executed after executing the library's basic algorithms.
// Not executed if getting the data item was ignored earlier.
//
// Parameters:
//  Source          - ExchangePlanObject -  the node for which the exchange is being performed.
//  DataElement     - Arbitrary - see the description of the handler of the same name in the syntax assistant.
//  ItemReceive - DataItemReceive - see the description of the handler of the same name in the syntax assistant.
//  SendBack     - Boolean - see the description of the handler of the same name in the syntax assistant.
//
Procedure OnReceiveDataFromMaster(Source, DataElement, ItemReceive, SendBack) Export
	
EndProcedure

// Allows you to change the indication that the version of the program is, or is not, basic.
//
// Parameters:
//  ThisIsBasic - Boolean -  indicates that the program version is basic. By default, True if the
//                        program name contains the word "Basic".
// 
Procedure WhenDefiningAFeatureThisIsTheBasicVersionOfTheConfiguration(ThisIsBasic) Export 
	
EndProcedure

#EndRegion
