///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Defines the default prefix for codes and numbers of database objects.
//
// Parameters:
//  Prefix - String, 2 -  prefix of codes and numbers of information database objects by default.
//
Procedure OnDetermineDefaultInfobasePrefix(Prefix) Export
	
	
	
EndProcedure

// Defines a list of exchange plans that use the functionality of the data exchange subsystem.
//
// Parameters:
//  SubsystemExchangePlans - Array of MetadataObjectExchangePlan -  array of configuration exchange plans
//                          that use the functionality of the data exchange subsystem.
//                          The elements of the array are objects metadata exchange plans.
//
// Example:
//   Playonlinepokerup.Add (Metadata.Exchange plans.Exchange of usesreferencesexternal links);
//   Playonlinepokerup.Add (Metadata.Exchange plans.Exchange of standardsystem libraries);
//   Playonlinepokerup.Add (Metadata.Exchange plans.Distributed information database);
//
Procedure GetExchangePlans(SubsystemExchangePlans) Export
	
	
	
EndProcedure

// Handler for uploading data.
// Used to override the default processing of discharge data.
// This handler must implement data upload logic:
// fetching data for uploading, serializing data to a message file, or serializing data to a stream.
// After executing the handler, the uploaded data will be sent to the recipient by the data exchange subsystem.
// The message format for uploading can be arbitrary.
// In case of errors when sending data, you must interrupt the execution of the handler
// use the call Exception method with the error description.
//
// Parameters:
//
//  StandardProcessing - Boolean -  this parameter is passed to indicate that standard (system)
//                                 event processing is performed.
//   If this parameter is set to False in the body of the handler procedure, standard
//   event processing will not be performed. Rejecting standard processing does not cancel the action.
//   The default value is True.
//
//  Recipient - ExchangePlanRef -  the exchange plan node for which data is being uploaded.
//
//  MessageFileName - String -  name of the file to upload data to.
//   If this parameter is filled in, the system expects
//   the data to be uploaded to a file. After uploading, the system will send data from this file.
//   If the parameter is empty, the system expects data to be uploaded to the message Data parameter.
//
//  MessageData - Arbitrary -  if the message File_name parameter is empty,
//   the system expects data to be uploaded to this parameter.
//
//  TransactionItemsCount - Number -  specifies the maximum number of data items
//   that can be placed in a message within a single database transaction.
//   If necessary, the handler should implement the logic
//   of setting transactional locks on the uploaded data.
//   The parameter value is set in the settings of the data exchange subsystem.
//
//  EventLogEventName - String -  name of the log event for the current data exchange session.
//   Used for logging data (errors, warnings, and information) with the specified event name.
//   Corresponds to the EventName parameter of the global context method of log Recordingregistration.
//
//  SentObjectsCount - Number -  counter of sent objects.
//   Used to determine the number of objects sent
//   for subsequent fixation in the exchange Protocol.
//
Procedure OnDataExport(StandardProcessing,
								Recipient,
								MessageFileName,
								MessageData,
								TransactionItemsCount,
								EventLogEventName,
								SentObjectsCount) Export
	
EndProcedure

// Handler for when data is loaded.
// Used to override the default processing of the load data.
// This handler must implement data loading logic:
// necessary checks before loading data, serialization of data from a message file, or serialization of data from
// a stream.
// The format of the message to upload can be arbitrary.
// In case of errors when receiving data, the handler should be aborted
// use the call Exception method with an error description.
//
// Parameters:
//
//  StandardProcessing - Boolean -  this parameter is passed to indicate
//   that standard (system) event processing is performed.
//   If this parameter is set to False in the body of the handler procedure,
//   standard event processing will not be performed.
//   Rejecting standard processing does not cancel the action.
//   The default value is: True.
//
//  Sender - ExchangePlanRef - 
//
//  MessageFileName - String -  the name of the file from which to load data.
//   If the parameter is not filled in, the data to upload is passed through the message Data parameter.
//
//  MessageData - Arbitrary -  this parameter contains the data to load.
//   If the message File_name parameter is empty,
//   data for uploading is passed through this parameter.
//
//  TransactionItemsCount - Number -  specifies the maximum number of data elements
//   that can be read from a message and written to the database in a single transaction.
//   If necessary, the handler should implement the logic for writing data in a transaction.
//   The parameter value is set in the settings of the data exchange subsystem.
//
//  EventLogEventName - String -  name of the log event for the current data exchange session.
//   Used for logging data (errors, warnings, and information) with the specified event name.
//   Corresponds to the EventName parameter of the global context method of log Recordingregistration.
//
//  ReceivedObjectsCount - Number -counter of received objects.
//   Used to determine the number of uploaded objects
//   for subsequent commit in the exchange Protocol.
//
Procedure OnDataImport(StandardProcessing,
								Sender,
								MessageFileName,
								MessageData,
								TransactionItemsCount,
								EventLogEventName,
								ReceivedObjectsCount) Export
	
EndProcedure

// Handler for registering changes for the initial data upload.
// Used to override the standard change registration processing.
// During standard processing, changes to all data from the exchange plan will be registered.
// If the exchange plan has data migration restriction filters,
// using this handler will improve the performance of the initial data upload.
// In the handler, you should implement change registration based on data migration restriction filters.
// If the exchange plan uses migration restrictions by date or by date and company,
// you can use the universal procedure
// Abendanimation.Register your data to be sent to the shipping companies.
// The handler is only used for universal data exchange using exchange rules
// and for universal data exchange without exchange rules, and is not used for exchanges in the rib.
// Using the handler allows you to increase the performance
// of the initial data upload by an average of 2-4 times.
//
// Parameters:
//
//   Recipient - ExchangePlanRef -  the site plan of exchange to which you want to upload data.
//   StandardProcessing - Boolean -  this parameter is passed to indicate that standard
//                          (system) event processing is performed.
//                          If this parameter is set to False in the body of the handler procedure,
//                          standard event processing will not be performed.
//                          Rejecting standard processing does not cancel the action.
//                          The default value is True.
//   Filter - Array of MetadataObject
//         - MetadataObject - 
//           
//
Procedure InitialDataExportChangesRegistration(Val Recipient, StandardProcessing, Filter) Export
	
	
	
EndProcedure

// Handler when the conflicting changes to the data.
// The event occurs when data is received if the same object
// that was received from the exchange message is changed in the current information database and these objects are different.
// Used to override the standard handling of data change collisions.
// Standard collision handling involves receiving changes from the master node
// and ignoring changes received from the slave node.
// This handler must override the get Element parameter
// if you want to change the default behavior.
// In this handler, you can set the behavior of the system when there is a collision of data changes in the data section,
// in the section of data properties, in the section of senders, or for the entire information database as a whole, or for all data as a
// whole.
// The handler is called both in the exchange in the distributed information database (rib),
// and in all other exchanges, including exchanges according to the exchange rules.
//
// Parameters:
//  DataElement - Arbitrary -  a data element read from a data exchange message.
//                  Data elements can be Contentmanagernet.< Constant name>,
//                  database objects (other than the "Delete object" object), sets of register entries,
//                  sequences, or recalculations.
//
//  ItemReceive - DataItemReceive -  determines whether the read data item will be written to the database
//                                               or not in the event of a collision.
//   When calling the handler, the parameter is set to Auto, which means default actions
//   (accept from the master, ignore from the slave).
//   The value of this parameter can be overridden in the handler.
//
//  Sender - ExchangePlanRef -  the exchange plan node that receives data on behalf of.
//
//  GetDataFromMasterNode - Boolean -    in a distributed information database, it indicates whether data is received from the main
//                                node.
//   True - data is received from the master node, False - from the subordinate node.
//   In exchanges based on exchange rules, it is set to True if the object's priority
//   in case of collision is set to "Higher" (the default value) or not specified in the exchange rules;
//   False - if the object's priority in the exchange rules is set to "Lower" or "the Same" in case of a collision.
//   In all other types of data exchange, this parameter is set to True.
//
Procedure OnDataChangeConflict(Val DataElement, ItemReceive, Val Sender, Val GetDataFromMasterNode) Export
	
	
	
EndProcedure

// Handler for the initial configuration of the IB after creating the rib node.
// Called when the subordinate rib node is first started (including the APM).
//
Procedure OnSetUpSubordinateDIBNode() Export
	
EndProcedure

// Retrieves available versions of the universal EnterpriseData format.
//
// Parameters:
//   FormatVersions - Map -  matches the format version number
//                   to the General module that contains the upload/download handlers for this version.
//
// Example:
//   Version of the format.Insert ("1.2", <General Modulespravilamiconversion Name>);
//
Procedure OnGetAvailableFormatVersions(FormatVersions) Export
	
	
	
EndProcedure

// Retrieves available extensions for the universal EnterpriseData format.
//
// Parameters:
//   FormatExtensions - Map of KeyAndValue:
//     * Key - String -  URI of the format extension schema namespace.
//     * Value - String -  number of the extensible version of the format.
//
Procedure OnGetAvailableFormatExtensions(FormatExtensions) Export
	
	
	
EndProcedure

// 
// 
//
// Parameters:
//   PreviousValue - Boolean - 
//   NewCurrent - Boolean - 
//   StandardProcessing - Boolean -  
//                                   
//
Procedure WhenChangingOfflineModeOption(PreviousValue, NewCurrent, StandardProcessing) Export
	
	
	
EndProcedure

//  
// (See InformationRegisters.DataExchangeResults.RecordIssueResolved)
//
// Parameters:
//  Types - Array of MetadataObject 
//	
Procedure WhenFillingInTypesExcludedFromCheckProblemIsFixed(Types) Export
	
	
	
EndProcedure

// 
//  
// 
//
// Parameters:
//   ExchangePlanName - String -  
//                    
//   SettingID- String - 
//   FoundNameOfExchangePlan - String - 
//       
//       
//       
//
Procedure WhenSearchingForNameOfExchangePlanThroughUniversalFormat(
	ExchangePlanName, SettingID, FoundNameOfExchangePlan) Export
	
	

EndProcedure

// 
// 
//
// Parameters:
//   ExchangePlanNodeObject - ExchangePlanObject - 
//   Result - ValueTable - :
//      * Order - Number
//      * ObjectName - String - 
//      * ObjectTypeString - String
//      * ExchangePlanName - String
//      * TabularSectionName - String - 
//      * RegistrationAttributes - String - 
//      * RegistrationAttributesStructure - Structure:
//         * Key - String - 
//         * Value - AnyRef - 
//
Procedure WhenRedefiningAttributesOfReferenceTypeOfExchangePlanSSUBAsset(ExchangePlanNodeObject, Result) Export 

EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. 
// 
// 
// 
// 
// Parameters:
//   ExchangePlanName - String -  
//                             
//   SettingsMode - String - 
//                               
//   ExchangePlanIsRecognized - Boolean - 
//
Procedure WhenCheckingCorrectnessOfNameOfEnterpriseDataExchangePlan(ExchangePlanName, SettingsMode, ExchangePlanIsRecognized) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

