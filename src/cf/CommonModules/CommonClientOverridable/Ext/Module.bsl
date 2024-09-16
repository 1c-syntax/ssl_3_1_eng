///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

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
//  Parameters - Structure:
//   * Cancel         - Boolean -  returned value. If set to True, the program will be terminated.
//   * Restart - Boolean -  returned value. If set to True and the Failure parameter is also set
//                              to True, the program is restarted.
// 
//   * AdditionalParametersOfCommandLine - String -  returned value. Makes sense when Failure
//                              and Restart are set to True.
//
//   * InteractiveHandler - NotifyDescription - 
//                              
//                               
//
//   * ContinuationHandler   - NotifyDescription - 
//                               
//
//   * Modules                 - Array -  references to modules in which you need to call the same procedure after returning.
//                              Modules can be added only as part of a call to the procedure of an overridden module.
//                              It is used to simplify the implementation of several consecutive asynchronous calls
//                              to different subsystems. See the example of integration of the Client system.Before starting the work of the system.
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
//		
//		
//	
//
Procedure BeforeStart(Parameters) Export
	
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
//  Parameters - Structure:
//   * Cancel         - Boolean -  returned value. If set to True, the program will be terminated.
//   * Restart - Boolean - 
//                              
//
//   * AdditionalParametersOfCommandLine - String -  returned value. It makes sense
//                              when Failure and Restart are set to True.
//
//   * InteractiveHandler - NotifyDescription -  the return value. To open a window that blocks entry
//                              into the program, assign a description of the notification handler
//                              that opens the window to this parameter. See the example in the front of the system operation.
//
//   * ContinuationHandler   - NotifyDescription - 
//                              
//                              
//   * Modules                 - Array -  references to modules in which you need to call the same procedure after returning.
//                              Modules can be added only as part of a call to the procedure of an overridden module.
//                              It is used to simplify the implementation of several consecutive asynchronous calls
//                              to different subsystems. See the example of integration of the Client system.Before starting the work of the system.
//
Procedure OnStart(Parameters) Export
	
	
	
	
	
EndProcedure

// 
//  
// 
//
// Parameters:
//  StartupParameters  - Array of String - 
//                      
//  Cancel             - Boolean -  if set to True, the launch will be aborted.
//
Procedure LaunchParametersOnProcess(StartupParameters, Cancel) Export
	
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
Procedure AfterStart() Export
	
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
//  Cancel          - Boolean -  if you set this parameter to True, the program will not be 
//                            finished.
//  Warnings - Array of See StandardSubsystemsClient.WarningOnExit - 
//                            you can add information about the appearance of the warning and what to do next.
//
Procedure BeforeExit(Cancel, Warnings) Export
	
EndProcedure

// 
//
// Parameters:
//  ApplicationCaption - String - 
//  OnStart          - Boolean - 
//                                 
//                                  
//                                 
//                                  
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
Procedure ClientApplicationCaptionOnSet(ApplicationCaption, OnStart) Export
	
	
	
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
// Parameters:
//  Parameters - Map of KeyAndValue:
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
Procedure BeforeRecurringClientDataSendToServer(Parameters) Export
	
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
Procedure AfterRecurringReceiptOfClientDataOnServer(Results) Export
	
EndProcedure

#EndRegion
