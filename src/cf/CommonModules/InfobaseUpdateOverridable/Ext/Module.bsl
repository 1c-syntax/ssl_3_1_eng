///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows you to set General subsystem settings, including the list of initial fill objects, message texts for
// the user, and more.
// 
// Parameters:
//  Parameters - Structure:
//    * UpdateResultNotes - String - 
//                                          
//    * UncompletedDeferredHandlersMessageParameters - Structure - 
//                                          
//                                          :
//       * MessageText                 - String -  the message text displayed to the user. By default
//                                          , the message text is based on the fact that the update can
//                                          be continued, i.e. the parameter disallow Continuation = False.
//       * MessagePicture              - Picture -  the image displayed to the left of the message.
//       * ProhibitContinuation           - Boolean -  if True, you will not be able to continue updating. False by default.
//    * ApplicationChangeHistoryLocation - String -  describes the location of the command that can
//                                          be used to open a form describing changes in the new version of the program.
//    * MultiThreadUpdate           - Boolean -  if True, multiple update handlers can be executed at the same time
//                                          . By default, it is False.
//                                          This affects both the number of threads running update handlers
//                                          and the number of data logging threads to update.
//                                          IMPORTANT: please read the documentation before enabling it.
//    * DefaultInfobaseUpdateThreadsCount - String -  the number of deferred update threads
//                                          used when no value is set for the constant
//                                          The number of streams of updating the information database. The default value is 1.
//   * ObjectsWithInitialFilling - Array -  objects that contain the initial fill code in the Manager module in the initial fill
//                                          procedure for Elements.
//
Procedure OnDefineSettings(Parameters) Export
	
	
	
EndProcedure

// Called before procedures that handle updating is data.
// Here you can place any non-standard logic for updating data - for example,
// otherwise initialize information about the versions of certain subsystems
// by updating the information Database.Versiiib, Updating The Information Database.Install the IIb version,
// and update the information Database.Register a new subsystem.
//
// Example:
//  In order to cancel the regular procedure for switching from another program, we register 
//  information that the main configuration is already the current version:
//  Worshiptogether = Obnovleniyami.Variopedatus();
//  If Worshiptogether.Number () > 0 And Versions Of Subsystems.Find (Metadata.Name, " Subsystem Name") = Undefined Then
//    Updating the information database.Register A New Subsystem (Metadata.Name, Metadata.Version);
//  Conicelli;
//
Procedure BeforeUpdateInfobase() Export
	
EndProcedure

// Called after the is data update is complete.
// Depending on certain conditions, you can disable the regular opening of the form
// with a description of changes in the new version of the program when you first log in to it (after updating),
// as well as perform other actions.
//
// We do not recommend performing any data processing in this procedure.
// Such procedures should be executed by regular update handlers that are executed for each version of"*".
// 
// Parameters:
//   PreviousIBVersion     - String -  version before update. "0.0.0.0" for "empty" is.
//   CurrentIBVersion        - String -  version after the update. As a rule, corresponds to the Metadata.Version.
//   UpdateIterations     - Array - 
//                                     :
//       * Subsystem              - String -  name of the library or configuration.
//       * Version                  - String -  for example, "2.1.3.39". Version number of the library (configuration).
//       * IsMainConfiguration - Boolean -  True if this is the main configuration and not the library.
//       * Handlers             - ValueTable - 
//                                   
//       * CompletedHandlers  - ValueTree - 
//                                   
//                                   
//       * MainServerModuleName - String -  name of the library module (configuration) that provides
//                                        basic information about it: name, version, and so on.
//       * MainServerModule      - CommonModule -  a General library module (configuration) that provides
//                                        basic information about the library: name, version, and so on.
//       * PreviousVersion             - String -  for example, "2.1.3.30". Version number of the library (configuration) before the update.
//   OutputUpdatesDetails - Boolean -  if set to False, the form
//                                describing changes in the new version of the program will not be opened. By default, True.
//   ExclusiveMode           - Boolean -  indicates that the update was performed in exclusive mode.
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
//  		
//  		
//  	
//  
//
Procedure AfterUpdateInfobase(Val PreviousIBVersion, Val CurrentIBVersion,
	Val UpdateIterations, OutputUpdatesDetails, Val ExclusiveMode) Export
	
	
EndProcedure

// Called when preparing a document with a description of changes in the new version of the program,
// which is displayed to the user when they first log in to the program (after the update).
//
// Parameters:
//   Template - SpreadsheetDocument -  description of changes in the new version of the program, automatically
//                               generated from the General layout of the description of system Changes.
//                               The layout can be programmatically modified or replaced with another one.
//
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

// Called before creating a list of deferred handlers.
// Allows you to organize additional checks of the list of deferred handlers.
//
// Parameters:
//   UpdateIterations     - Array - 
//                                     :
//       * Subsystem              - String -  name of the library or configuration.
//       * Version                  - String -  for example, "2.1.3.39". Version number of the library (configuration).
//       * IsMainConfiguration - Boolean -  True if this is the main configuration and not the library.
//       * Handlers             - ValueTable - 
//                                   
//       * CompletedHandlers  - ValueTree - 
//                                   
//                                   
//       * MainServerModuleName - String -  name of the library module (configuration) that provides
//                                        basic information about it: name, version, and so on.
//       * MainServerModule      - CommonModule -  a General library module (configuration) that provides
//                                        basic information about the library: name, version, and so on.
//       * PreviousVersion             - String -  for example, "2.1.3.30". Version number of the library (configuration) before the update.
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
//		
//  
//
Procedure BeforeGenerateDeferredHandlersList(UpdateIterations) Export
	
EndProcedure

// This is necessary in order to upload new or changed descriptions
// of update handlers to the code by processing the description of update Handlers
// only for those subsystems that are being developed in this configuration.
// 
//
// Parameters:
//   SubsystemsToDevelop - Array of String -  names of the subsystems being developed in the current configuration, 
//                                                  The name of the subsystem as it is specified in the general module 
//                                                  Updating the information database.
//
Procedure WhenFormingAListOfSubsystemsUnderDevelopment(SubsystemsToDevelop) Export
	
	
	
EndProcedure

// 
//   
//
// Parameters:
//   PrioritizingMetadataTypes - Map of KeyAndValue - :
//                   * Key - 
//                   * Value - Number - 
//
// Example:
//   									
//
Procedure WhenPrioritizingMetadataTypes(PrioritizingMetadataTypes) Export
	
EndProcedure

// Called when the update information Database function is executed.Object processed.
// Allows you to write custom logic to block changes to an object by the user
// while the program is being updated.
//
// Parameters:
//  FullObjectName - String -  name of the object to check for.
//  BlockUpdate - Boolean -  if set to True, the object
//                         will be read-only. The default value is False.
//  MessageText   - String -  a message that will be displayed to the user when the object is opened.
//
Procedure OnExecuteCheckObjectProcessed(FullObjectName, BlockUpdate, MessageText) Export
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  FullObjectName - String -  the name of the object to be filled in for.
//  Settings - Structure:
//   * OnInitialItemFilling - Boolean -  if True,
//      the individual filling procedure will be called for each element at the beginning of the element Filling.
//   * PredefinedData - ValueTable -  the data filled in in the procedure for the initial filling of the elements.
//
Procedure OnSetUpInitialItemsFilling(FullObjectName, Settings) Export
	
EndProcedure

// 
//  
// 
//
// Parameters:
//  FullObjectName - String -  the name of the object to be filled in for.
//  LanguagesCodes - Array -  list of configuration languages. Relevant for multilingual configurations.
//  Items   - ValueTable -  fill-in data. The composition of the columns corresponds to the set of object details.
//  TabularSections - Structure - :
//   * Key - String -  name of the table part;
//   * Value - ValueTable - 
//                                  :
//                                  
//                                  
//                                  
//
Procedure OnInitialItemsFilling(FullObjectName, LanguagesCodes, Items, TabularSections) Export
	
EndProcedure

// 
// 
// 
//
// Parameters:
//  FullObjectName - String -  the name of the object to be filled in for.
//  Object                  - the object to fill in.
//  Data                  - ValueTableRow -  data for filling in the object.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable -  the data filled in in the procedure for the initial filling of the elements.
//
Procedure OnInitialItemFilling(FullObjectName, Object, Data, AdditionalParameters) Export
	
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
// Parameters:
//  Objects - See InfobaseUpdate.AddObjectPlannedForDeletion.Objects
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
//  
//		
//		
//			
//
Procedure OnPopulateObjectsPlannedForDeletion(Objects) Export
	
	
	
EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated. 
// 
//
Procedure OnGenerateListOfSubsystemsToDevelop(SubsystemsToDevelop) Export
	
	
EndProcedure

#EndRegion

#EndRegion
