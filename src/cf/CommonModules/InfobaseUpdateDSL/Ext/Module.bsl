///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ForCallsFromOtherSubsystems

////////////////////////////////////////////////////////////////////////////////
// 

// Fills in basic information about the library or main configuration.
// A library whose name matches the name of the configuration in the metadata is defined as the main configuration.
// 
// Parameters:
//  LongDesc - Structure:
//
//   * Name                 - String -  name of the library, for example, "standard Subsystems".
//   * Version              - String -  version in 4-digit format, for example, "2.1.3.1".
//
//   * OnlineSupportID - String -  unique name of the program in Internet support services.
//   * RequiredSubsystems1 - Array -  names of other libraries (String) that this library depends on.
//                                    Update handlers for such libraries must be called earlier
//                                    than the update handlers for this library.
//                                    If there are cyclic dependencies or, on the contrary, there are no dependencies,
//                                    the order of calling update handlers is determined by the order of adding modules
//                                    in the procedure for adding General module Subsystems
//                                    Configuration subsystems are undefined.
//   * DeferredHandlersExecutionMode - String -  "Sequentially" - deferred update handlers are executed
//                                    sequentially in the range from the version number of the information database to
//                                    the configuration version number inclusive, or "in Parallel" - the deferred
//                                    handler passes control to the next handler after processing the first batch of data, and after
//                                    the last handler is executed, the cycle repeats again.
//
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name    = "DataSyncLibrary";
	LongDesc.Version = "1.0.3.534";
	LongDesc.OnlineSupportID = "DSL";
	LongDesc.DeferredHandlersExecutionMode = "Parallel";
	LongDesc.ParallelDeferredUpdateFromVersion = "1.0.1.1";
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
// Example:
//  To add your own handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = " 1.1.0.0";
//  Handler.Procedure = "Update".Reinversion_1_1_0_0";
//  Handler.Execution Mode = " Fast";
//
Procedure OnAddUpdateHandlers(Handlers) Export
	
	
	
EndProcedure

// See InfobaseUpdateOverridable.BeforeUpdateInfobase.
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
//   PreviousVersion     - String -  version before update. "0.0.0.0" for "empty" is.
//   CurrentVersion        - String -  version after the update. As a rule, corresponds to the Metadata.Version.
//   CompletedHandlers - ValueTree:
//     * InitialFilling - Boolean -  if True, the handler should be triggered when running on an "empty" database.
//     * Version              - String -  for example, "2.1.3.39". The number of the configuration version
//                                      that the update handler procedure should be performed when switching to.
//                                      If an empty string is specified, it is a handler only for initial filling
//                                      (the initial Fill property must be specified).
//     * Procedure           - String -  full name of the update/initial fill handler procedure. 
//                                      For Example, " Updating The Information Base Of The PPI.Fill in the new requisit"
//                                      It must be exported.
//     * ExecutionMode     - String - :
//                                      
//                                      
//     * SharedData         - Boolean -  if True, the handler must be triggered before
//                                      any handlers that use split data are executed.
//                                      You can only specify it for handlers with the Exclusive and Fast execution mode.
//                                      If you set the value to True for a handler with
//                                      Deferred execution mode, an exception is thrown.
//     * HandlerManagement - Boolean -  if True, then the handler must have a parameter of the Structure type, which
//                                          has the Separated Handlers property - a table of values with the structure
//                                          returned by this function.
//                                      In this case, the Version column is ignored. If it is necessary to execute
//                                      a split handler, a row with
//                                      a description of the handler procedure must be added to this table.
//                                      It makes sense only for mandatory (Version = *) update handlers 
//                                      with the General Data flag set.
//     * Comment         - String -  description of actions performed by the update handler.
//     * Id       - UUID -  you need to fill in for deferred update handlers,
//                                                 but you don't need to fill in for the rest of them. Required to identify
//                                                 the handler if it is renamed.
//     
//     * ObjectsToLock  - String -  you need to fill in for deferred update handlers,
//                                      but you don't need to fill in for the rest of them. Full names of objects separated by commas 
//                                      that should be blocked from being modified until the data processing procedure is completed.
//                                      If filled in, you also need to fill in the check Procedure property.
//     * CheckProcedure   - String - 
//                                       
//                                       
//                                       
//                                      
//                                      :
//                                          See InfobaseUpdate.MetadataAndFilterByData.
//     * UpdateDataFillingProcedure - String -  specifies the procedure that registers the data to
//                                      be updated by this handler.
//     * ExecuteInMasterNodeOnly  - Boolean -  only for deferred update handlers with Parallel execution mode.
//                                      Specify True if the update handler should only be executed on the main
//                                      rib node.
//     * RunAlsoInSubordinateDIBNodeWithFilters - Boolean -  only for deferred update handlers with
//                                      Parallel execution mode.
//                                      Specify True if the update handler must also be executed in
//                                      a subordinate rib node with filters.
//     * ObjectsToRead              - String -  objects that the update handler will read when processing data.
//     * ObjectsToChange            - String -  objects that the update handler will change when processing data.
//     * ExecutionPriorities         - ValueTable -  a table of execution priorities between deferred handlers
//                                      modifying or reading the same data. For more information, see in the comments
//                                      to the Information Database update function.Priority of the handler's execution.
//     * ExecuteInMandatoryGroup - Boolean -  specify if the handler needs
//                                      to be executed in the same group as handlers on the "* " version.
//                                      You can also change the order in which the handler is executed
//                                      relative to others by changing the priority.
//     * Priority           - Number  -  for internal use.
//     * ExclusiveMode    - Undefined
//                           - Boolean -  
//                                      
//                                      :
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
//   OutputUpdatesDetails - Boolean -  if set to False, the form
//                                describing changes in the new version of the program will not be opened. By default, True.
//   ExclusiveMode           - Boolean -  indicates that the update was performed in exclusive mode.
//
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion, Val CompletedHandlers, OutputUpdatesDetails, Val ExclusiveMode) Export
	
	
	
EndProcedure

// See InfobaseUpdateOverridable.OnPrepareUpdateDetailsTemplate.
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
	
	
EndProcedure

// Allows you to override the data update mode of the information database.
// For use in rare (non-standard) cases of transition that are not provided for in
// the standard procedure for determining the update mode.
//
// Parameters:
//   DataUpdateMode - String - :
//              
//              
//               
//                                          
//
//   StandardProcessing  - Boolean -  if set to False, the standard procedure
//                                    for determining the update mode is not performed, 
//                                    but the value of the data update Mode is used.
//
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
	
	
EndProcedure

// Adds transition handler procedures from another program (with a different configuration name) to the list.
// For example, to switch between different but related configurations: basic - > Prof. - > Corp.
// Called before starting updating the information security data.
//
// Parameters:
//  Handlers - ValueTable:
//    * PreviousConfigurationName - String -  name of the configuration to be migrated from;
//                                           or " * " if you want to perform it when switching from any configuration.
//    * Procedure                 - String -  full name of the transition handler procedure from the program
//                                           Premiumecigarette.
//                                  For Example, " Updating The Information Base Of The PPI.Fill in the accounting policy"
//                                  It must be exported.
//
// Example:
//  Handler = Handlers.Add();
//  Handler.Premiumecigarette = "Upravlyatora";
//  Handler.Procedure = " Updating The Information Base Of The DPP.Fill in the accounting policy";
//
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
	
	
	
EndProcedure

// Called after all transition handler procedures have been executed from another program (with a different configuration name),
// and before the start of updating the is data.
//
// Parameters:
//  PreviousConfigurationName    - String -  name of the configuration before the transition.
//  PreviousConfigurationVersion - String -  name of the previous configuration (before the transition).
//  Parameters                    - Structure:
//    * ExecuteUpdateFromVersion   - Boolean -  by default, True. If set to False, 
//        only the required update handlers (with the "* " version) will be executed.
//    * ConfigurationVersion           - String -  version number after the transition. 
//        By default, it is equal to the value of the configuration version in the metadata properties.
//        To run, for example, all update handlers from the previous configuration Version, 
//        set the parameter value to previous configuration Version.
//        To run all update handlers at all, set the value to "0.0.0.1".
//    * ClearPreviousConfigurationInfo - Boolean -  by default, True. 
//        If the previous configuration matches the name of the subsystem in the current configuration,
//        specify False.
//
Procedure OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion
