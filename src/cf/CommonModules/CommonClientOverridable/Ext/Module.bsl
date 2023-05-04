///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Is executed before a user starts interactive work with a data area or in the local mode.
// Corresponds to the BeforeStart handler.
//
// Parameters:
//  Parameters - Structure:
//   * Cancel         - Boolean - a return value. If True, the application is terminated.
//   * Restart - Boolean - a return value. If True and the Cancel parameter
//                              is True, restarts the application.
// 
//   * AdditionalParametersOfCommandLine - String - a return value. Has a point when Cancel
//                              and Restart are True.
//
//   * InteractiveHandler - NotifyDescription - a return value. To open the window that locks the application
//                              start, pass the notification description
//                              handler that opens the window. See the example below.
//
//   * ContinuationHandler   - NotifyDescription - If there is a window that blocks signing in to an application, this window close
//                              handler must execute the ContinuationHandler notification. See the example below.
//
//   * Modules                 - Array - references to the modules that will run the procedure after the return.
//                              You can add modules only by calling an overridable module procedure.
//                              It helps to simplify the design where a sequence of asynchronous calls
//                              are made to a number of subsystems. See the example for SSLSubsystemsIntegrationClient.BeforeStart. 
//
// Example:
//  The below code opens a window that blocks signing in to an application.
//
//		If OpenWindowOnStart Then
//			Parameter.InteractiveHandler = New NotificationDetails("OpenWindow", ThisObject);
//		EndIf;
//
//	Procedure OpenWindow(Parameters, AdditionalParameters) Export
//		// Showing the window. Once the window is closed, calling the OpenWindowCompletion notification handler.
//		Notification = New NotificationDetails("OpenWindowCompletion", ThisObject, Parameters);
//		Form = OpenForm(… ,,, … Notification);
//		If Not Form.IsOpen() Then // If OnCreateAtServer Cancel is True.
//			ExecuteNotifyProcessing(Parameters.ContinuationHandler);
//		EndIf;
//	EndProcedure
//
//	Procedure OpenWindowCompletion(Result, Parameters) Export
//		…
//		ExecuteNotifyProcessing(Parameters.ContinuationHandler);
//		
//	EndProcedure
//
Procedure BeforeStart(Parameters) Export
	
EndProcedure

// The procedure is executed when a user accesses a data area interactively or starts the application in the local mode.
// Corresponds to the OnStart handler.
//
// Parameters:
//  Parameters - Structure:
//   * Cancel         - Boolean - a return value. If True, the application is terminated.
//   * Restart - Boolean - a return value. If True and the Cancel parameter
//                              is True, restarts the application.
//
//   * AdditionalParametersOfCommandLine - String - a return value. Has a point
//                              when Cancel and Restart are True.
//
//   * InteractiveHandler - NotifyDescription - a return value. To open the window that locks the application
//                              start, pass the notification description handler
//                              that opens the window. See the BeforeStart for an example. 
//
//   * ContinuationHandler   - NotifyDescription - If there is a window that blocks signing in to an application,
//                              this window close handler must execute the ContinuationHandler notification.
//                              See the CommonClientOverridable.BeforeStart for an example.
//                              
//   * Modules                 - Array - references to the modules that will run the procedure after the return.
//                              You can add modules only by calling an overridable module procedure.
//                              It helps to simplify the design where a sequence of asynchronous calls
//                              are made to a number of subsystems. See the example for SSLSubsystemsIntegrationClient.BeforeStart. 
//
Procedure OnStart(Parameters) Export
	
	
	
	
	
EndProcedure

// The procedure is called to process the application startup parameters
// passed in the /C command line. For example, 1cv8.exe … /CDebugMode.
//
// Parameters:
//  StartupParameters  - Array - an array of strings separated with semicolons ";" in the start parameter
//                      passed to the configuration using the /C command line key.
//  Cancel             - Boolean - If True, the start is aborted.
//
Procedure LaunchParametersOnProcess(StartupParameters, Cancel) Export
	
EndProcedure

// The procedure is executed when a user accesses a data area interactively or starts the application in the local mode.
// It is called after OnStart handler execution.
// Attaches the idle handlers that are only required
// after OnStart.
//
// The home page is not open at the moment, that is why you cannot open
// forms directly but use an idle handler instead.
// This event is not allowed for user interaction
// (for example, for ShowQueryBox). For such scenarios, place your code in the OnStart procedure.
//
Procedure AfterStart() Export
	
EndProcedure

// Is executed before the user logged off from the data area or exits the application in the local mode.
// Corresponds to the BeforeExit handler.
// Defines the list of user warnings on exit.
//
// Parameters:
//  Cancel          - Boolean - If True, the application exit 
//                            is interrupted.
//  Warnings - Array of See StandardSubsystemsClient.WarningOnExit - 
//                            you can add information about the warning appearance and the next steps.
//
Procedure BeforeExit(Cancel, Warnings) Export
	
EndProcedure

// Used to override application captions.
//
// Parameters:
//  ApplicationCaption - String - the text displayed on the title bar;
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
