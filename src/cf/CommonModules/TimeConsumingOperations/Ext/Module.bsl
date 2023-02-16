///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

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
//
// Parameters:
//  ExecutionParameters - ClientApplicationForm -
//                      - UUID - 
//                      - Structure - See FunctionExecutionParameters
//  FunctionName - String - a name of the export function in a common module, object manager module, 
//                        or data processor module that you want to start in a background job.
//                        Examples: "MyCommonModule.MyProcedure", "Report.ImportedData.Generate"
//                        or "DataProcessor.DataImport.Import". 
//
//  Parameter1 - Arbitrary - arbitrary parameters of the function call. The number of parameters can be from 0 to 7.
//  Parameter2 - Arbitrary
//  Parameter3 - Arbitrary
//  Parameter4 - Arbitrary
//  Parameter5 - Arbitrary
//  Parameter6 - Arbitrary
//  Parameter7 - Arbitrary
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//   * ResultAddress       - String - the address of the temporary storage where the function result must be
//                                      stored.
//   * BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//   * DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//
// Example:
//  In general, the process of starting and processing the result of a long-running operation in the form module looks like this:
//
//   1) The function that will be executed in the background is located in the object manager module or in the server common module:
//    Function CalculateValue(Val MyParameter1, Val MyParameter2) Export
//     …
//     Return Result;
//    EndFunction
//
//   2) Starting the operation on the server and attaching the idle handler:
//    &AtClient
//    Procedure CalculateValue()
//     TimeConsumingOperation = StartExecutionAtServer();
//     CompletionNotification = New NotifyDescription("ProcessResult", ThisObject);
//     IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
//     TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
//    EndProcedure
//
//    &AtServer
//    Function StartExecutionAtServer()
//     ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
//     Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "DataProcessor.MyDataProcessor.CalculateValue", 
//      MyParameter1, MyParameter2);
//    EndFunction
//    
//   3) The result processing of a long-running operation:
//    &AtClient
//    Procedure ProcessResult(Result, AdditionalParameters) Export
//     If Result = Undefined Then
//      Return;
//     EndIf;
//     OutputResult(Result.ResultAddress);
//    EndProcedure 
//  
Function ExecuteFunction(Val ExecutionParameters, FunctionName, Val Parameter1 = Undefined,
	Val Parameter2 = Undefined, Val Parameter3 = Undefined, Val Parameter4 = Undefined,
	Val Parameter5 = Undefined, Val Parameter6 = Undefined, Val Parameter7 = Undefined) Export
	
	CallParameters = ParametersList(Parameter1, Parameter2, Parameter3, Parameter4,
		Parameter5, Parameter6, Parameter7);
		
	ExecutionParameters = PrepareExecutionParameters(ExecutionParameters, True);
	
	Return ExecuteInBackground(FunctionName, CallParameters, ExecutionParameters);
	
EndFunction

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
//
//  ExecutionParameters - See TimeConsumingOperations.ProcedureExecutionParameters
//
//  ProcedureName - String - a name of the export procedure in a common module, object manager module, 
//                          or data processor module that you want to start in a background job.
//                          Examples: "MyCommonModule.MyProcedure", "Report.ImportedData.Generate"
//                          or "DataProcessor.DataImport.Import". 
//
//  Parameter1 - Arbitrary - arbitrary parameters of the procedure call. The number of parameters can be from 0 to 7.
//  Parameter2 - Arbitrary
//  Parameter3 - Arbitrary
//  Parameter4 - Arbitrary
//  Parameter5 - Arbitrary
//  Parameter6 - Arbitrary
//  Parameter7 - Arbitrary
//
// Returns:
//  Structure -  
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//   * BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//   * DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//
// Example:
//  In general, running a long-running operation in the form module and processing its results is organized as follows:
//
//   1) The procedure to run in the background is added to the object manager module or common server module:
//    Procedure ExecuteCalculation(Val MyParameter1, Val MyParameter2) Export
//     …
//    EndProcedure
//
//   2) The operation is started on the server, and the idle handler is attached (if necessary):
//    &AtClient
//    Procedure ExecuteCalculation()
//     TimeConsumingOperation = StartExecuteAtServer();
//     CompletionNotification = New NotifyDescription("ProcessResult", ThisObject);
//     IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
//     TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
//    EndProcedure
//
//    &AtServer
//    Function StartExecuteAtServer()
//     Return TimeConsumingOperations.ExecuteProcedure(, "DataProcessor.MyDataProcessor.ExecuteCalculation", 
//      MyParameter1, MyParameter2);
//    EndFunction
//    
//   3) The result of a long-running operation is processed:
//    &AtClient
//    Procedure ProcessResult(Result, AdditionalParameters) Export
//     If Result = Undefined Then
//      Return;
//     EndIf;
//     OnCalculaionCompletion();
//    EndProcedure 
//   
Function ExecuteProcedure(Val ExecutionParameters = Undefined, ProcedureName, Val Parameter1 = Undefined,
	Val Parameter2 = Undefined, Val Parameter3 = Undefined, Val Parameter4 = Undefined,
	Val Parameter5 = Undefined, Val Parameter6 = Undefined, Val Parameter7 = Undefined) Export
	
	CallParameters = ParametersList(Parameter1, Parameter2, Parameter3, Parameter4,
		Parameter5, Parameter6, Parameter7);
		
	ExecutionParameters = PrepareExecutionParameters(ExecutionParameters, False);
	
	Return ExecuteInBackground(ProcedureName, CallParameters, ExecutionParameters);
	
EndFunction

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
//  FunctionName - String - the name of the export function in a common module, object manager module, 
//                        or data processor module that you want to start in a background job.
//                        Example: "MyCommonModule.MyProcedure", "Reports.ImportedData.Generate"
//                        or "DataProcessors.DataImport.ObjectModule.Import". 
//  ExecutionParameters - See FunctionExecutionParameters
//  FunctionSettings - Map of KeyAndValue - Custom set of function call parameters:
//    * Key - Arbitrary - Set key.
//    * Value - Array - Up to 7 function call parameters.
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//   * ResultAddress       - String - Address of the temporary storage to save the Map to:
//                                      ** Key - Arbitrary
//                                      ** Value - See ExecuteFunction
//   * BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//   * DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//
Function ExecuteFunctionInMultipleThreads(FunctionName, Val ExecutionParameters, Val FunctionSettings = Undefined) Export
	
	If FunctionSettings <> Undefined And TypeOf(FunctionSettings) <> Type("Map") Then
		Raise NStr("en = 'Invalid type of parameter set is passed';");
	EndIf;
	
	If Common.DataSeparationEnabled() And Not Common.SeparatedDataUsageAvailable() Then
		Raise NStr("en = 'Multi-threaded long-running operations in a shared session are not supported.';");
	EndIf;

	ProcessID = ?(ValueIsFilled(ExecutionParameters.FormIdentifier),
		ExecutionParameters.FormIdentifier,
		New UUID);
		
	ExecutionParametersChildThreads = BackgroundExecutionParameters(ProcessID);
	ExecutionParametersChildThreads.WaitCompletion = 0;
	ExecutionParametersChildThreads.ResultAddress = PutToTempStorage(Undefined, New UUID);
	ExecutionParametersChildThreads.MultiThreadOperation = True;
	
	AddressResults = New Map;
	
	If FunctionSettings <> Undefined Then
		For Each ParameterFunctions In FunctionSettings Do
			StreamResultAddr = PutToTempStorage(Undefined, New UUID);
			AddressResults.Insert(ParameterFunctions.Key, StreamResultAddr);
		EndDo;
	EndIf;
	
	MultithreadOperationParameters = MultithreadOperationParameters(ProcessID);
	MultithreadOperationParameters.MethodName = FunctionName;
	MultithreadOperationParameters.ForFunction = True;
	MultithreadOperationParameters.OperationParametersList = ExecutionParameters;
	MultithreadOperationParameters.MethodParameters = FunctionSettings;
	MultithreadOperationParameters.ResultAddress = ExecutionParametersChildThreads.ResultAddress;
	MultithreadOperationParameters.AbortExecutionIfError = ExecutionParameters.AbortExecutionIfError;
	MultithreadOperationParameters.AddressResults = AddressResults;
	MultithreadOperationParameters.MultiThreadOperation = True;
	
	PrepareMultiThreadOperationForStartup(FunctionName, MultithreadOperationParameters, ProcessID, FunctionSettings);
	
	RunResult = ExecuteFunction(ExecutionParametersChildThreads, MultithreadProcessMethodName(), MultithreadOperationParameters);
	
	If RunResult.Status = TimeConsumingOperationStatus().Running Then
		ScheduleStartOfLongRunningOperationThreads(RunResult.JobID, RunResult, MultithreadOperationParameters);
	EndIf;
	
	Return RunResult;
	
EndFunction

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
//  ProcedureName - String - Name of the export procedure that you want to start in the background. 
//                          The procedure can belong to a common module, object manager module, or data processor module.
//  ExecutionParameters - See ProcedureExecutionParameters
//  ProcedureSettings - Map of KeyAndValue - Custom set of procedure call parameters:
//    * Key - Arbitrary - Set key.
//    * Value - Array - Up to 7 procedure call parameters.
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//   * ResultAddress       - String - Address of the temporary storage to save the Map to:
//                                       ** Key - Arbitrary
//                                       ** Value - See ExecuteProcedure
//   * BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//   * DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//
Function ExecuteProcedureinMultipleThreads(ProcedureName, Val ExecutionParameters, Val ProcedureSettings = Undefined) Export
	
	If ProcedureSettings <> Undefined And TypeOf(ProcedureSettings) <> Type("Map") Then
		Raise NStr("en = 'Invalid type of parameter set is passed';");
	EndIf;
	
	If Common.DataSeparationEnabled() And Not Common.SeparatedDataUsageAvailable() Then
		Raise NStr("en = 'Multi-threaded long-running operations in a shared session are not supported.';");
	EndIf;
	
	ProcessID = ?(ValueIsFilled(ExecutionParameters.FormIdentifier),
		ExecutionParameters.FormIdentifier,
		New UUID);
		
	ExecutionParametersChildThreads = BackgroundExecutionParameters(ProcessID);
	ExecutionParametersChildThreads.WaitCompletion = 0;
	ExecutionParametersChildThreads.ResultAddress = PutToTempStorage(Undefined, New UUID);
	ExecutionParametersChildThreads.MultiThreadOperation = True;
	
	AddressResults = New Map;
	
	If ProcedureSettings <> Undefined Then
		For Each ParameterFunctions In ProcedureSettings Do
			StreamResultAddr = PutToTempStorage(Undefined, New UUID);
			AddressResults.Insert(ParameterFunctions.Key, StreamResultAddr);
		EndDo;
	EndIf;
	
	MultithreadOperationParameters = MultithreadOperationParameters(ProcessID);
	MultithreadOperationParameters.MethodName = ProcedureName;
	MultithreadOperationParameters.ForFunction = False;
	MultithreadOperationParameters.OperationParametersList = ExecutionParameters;
	MultithreadOperationParameters.MethodParameters = ProcedureSettings;
	MultithreadOperationParameters.ResultAddress = ExecutionParametersChildThreads.ResultAddress;
	MultithreadOperationParameters.AbortExecutionIfError = ExecutionParameters.AbortExecutionIfError;
	MultithreadOperationParameters.AddressResults = AddressResults;
	
	PrepareMultiThreadOperationForStartup(ProcedureName, MultithreadOperationParameters, ProcessID, ProcedureSettings);
	
	RunResult = ExecuteFunction(ExecutionParametersChildThreads, MultithreadProcessMethodName(), MultithreadOperationParameters);
	
	If RunResult.Status = TimeConsumingOperationStatus().Running Then
		ScheduleStartOfLongRunningOperationThreads(RunResult.JobID, RunResult, MultithreadOperationParameters);
	EndIf;
	
	Return RunResult;
	
EndFunction

// Constructor of the FunctionExecutionParameters collection for the ExecuteFunction function.
//
// If RunInBackground = False and RunNotInBackground = False, the job will be executed in the background if possible.
// A job runs in the main thread if any of the following conditions is met:
//  * the procedure is called in a file infobase through an external connection (this mode has no background job support);
//  * the application runs in debug mode (see /C DebugMode command-line parameter) for configuration debug purposes;
//  * the file infobase already has active background jobs (to avoid slow application response to user actions);
//  * the function belongs to an external data processor module or an external report module.
//
// Parameters:
//   FormIdentifier - UUID - a UUID of the form 
//                               containing the temporary storage where the procedure puts its result.
//
// Returns:
//   Structure - 
//     * FormIdentifier  - UUID - a UUID of the form
//                             containing the temporary storage where the procedure puts its result.
//     * WaitCompletion   - Number - a background job completion timeout, in seconds.
//                             Wait for completion if Undefined.
//                             If set to 0, do not wait for completion.
//                             The default value is 2 seconds (4 seconds for slow connection).
//     * BackgroundJobDescription - String - the description of the background job. The default value is the procedure name.
//     * BackgroundJobKey - String - the unique key for active background jobs that have the same procedure name.
//                                      Not set by default.
//     * ResultAddress     - String - an address of the temporary storage where the procedure
//                                      result must be stored. If the address is not set, it is generated automatically.
//     * RunInBackground           - Boolean - If True, the job always runs in the background, except for the following cases:
//                                  a) the procedure is called in the file infobase through an external connection 
//                                  (this mode has no background job support);
//                                  b) the function belongs to an external data processor module or an external report module.
//                                  In the file mode, if any other background jobs are running,
//                                  the new job is queued and does not start running until all the previous jobs are completed.
//                                  If False, the job will be executed in the background if possible. 
//     * RunNotInBackground1         - Boolean - If True, the job always runs naturally
//                                  without using background jobs.
//     * NoExtensions            - Boolean - If True, no configuration extensions
//                                  are attached to run the background job. Has priority over the RunNotInBackground parameter. 
//     * WithDatabaseExtensions  - Boolean - If True, the background job will run with the latest version of
//                                  the configuration extensions. Has priority over the RunNotInBackground parameter.
//     * AbortExecutionIfError - Boolean - If True, when an error occurs in a child job, the multithread background job is aborted.
//                                  The running child jobs will be aborted.
//                                  Applicable to function RunFunctionInMultithreading.
//                                  
//
Function FunctionExecutionParameters(Val FormIdentifier) Export
	
	Result = CommonBackgroundExecutionParameters();
	AddExecutionParametersToReturnResult(Result, FormIdentifier);
	
	Return Result;
	
EndFunction

// Constructor of the FunctionExecutionParameters collection for the ExecuteFunction function.
//
// If RunInBackground = False and RunNotInBackground = False, the job will be executed in the background if possible.
// A job runs in the main thread if any of the following conditions is met:
//  * the procedure is called in a file infobase through an external connection (this mode has no background job support);
//  * the application runs in debug mode (see /C DebugMode command-line parameter) for configuration debug purposes;
//  * the file infobase already has active background jobs (to avoid slow application response to user actions);
//  * the function belongs to an external data processor module or an external report module.
//
// Returns:
//   Structure - 
//     * WaitCompletion   - Number  - a background job completion timeout, in seconds.
//                                      Wait for completion if Undefined.
//                                      If set to 0, do not wait for completion.
//                                      The default value is 2 seconds (4 seconds for slow connection).
//     * BackgroundJobDescription - String - the description of the background job. The default value is the procedure name.
//     * BackgroundJobKey - String - the unique key for active background jobs that have the same procedure name.
//                                      Not set by default.
//     * RunInBackground           - Boolean - If True, the job always runs in the background, except for the following cases:
//                                  a) the procedure is called in the file infobase through an external connection 
//                                  (this mode has no background job support);
//                                  b) the function belongs to an external data processor module or an external report module.
//                                  In the file mode, if any other background jobs are running,
//                                  the new job is queued and does not start running until all the previous jobs are completed.
//                                  If False, the job will be executed in the background if possible. 
//     * RunNotInBackground1         - Boolean - If True, the job always runs naturally
//                                  without using background jobs.
//     * NoExtensions            - Boolean - If True, no configuration extensions
//                                  are attached to run the background job. Has priority over the RunNotInBackground parameter. 
//     * WithDatabaseExtensions  - Boolean - If True, the background job will run with the latest version of
//                                  the configuration extensions. Has priority over the RunNotInBackground parameter. 
//     * AbortExecutionIfError - Boolean - If True, when an error occurs in a child job, the multithread background job is aborted.
//                                  The running child jobs will be aborted.
//                                  Applicable to function RunProcedureInMultithreading.
//                                  
//
Function ProcedureExecutionParameters() Export
	
	Return CommonBackgroundExecutionParameters();
	
EndFunction

// 
// 
// 
// 
// 
// 
// Parameters:
//  ProcedureName           - String    - a name of the export procedure in a common module, object manager module, 
//                                       or data processor module that you want to start in a background job.
//                                       Examples: "MyCommonModule.MyProcedure", "Report.ImportedData.Generate"
//                                       or "DataProcessor.DataImport.Import". 
//                                       The procedure must have two or three formal parameters:
//                                        * Parameters       - Structure - arbitrary parameters ProcedureParameters;
//                                        * ResultAddress - String    - the address of the temporary storage where the procedure
//                                          puts its result. Required;
//                                        * AdditionalResultAddress - String - If ExecutionParameters include 
//                                          the AdditionalResult parameter, this parameter contains the address of the additional temporary
//                                          storage where the procedure puts its result. This parameter is optional.
//                                       If you need to run a function in background, it is recommended that you wrap it in a function
//                                       and return its result in the second parameter ResultAddress.
//  ProcedureParameters     - Structure - arbitrary parameters used to call the ProcedureName procedure.
//  ExecutionParameters    - See TimeConsumingOperations.BackgroundExecutionParameters
//
// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is running;
//                                     "Completed " if the job has completed;
//                                     "Error" if the job has completed with error;
//                                     "Canceled" if job is canceled by a user or by an administrator.
//   * JobID  - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//   * ResultAddress       - String - the address of the temporary storage to which the procedure result must be placed
//                                      (or is already placed if Status = "Completed").
//   * AdditionalResultAddress - String - If the AdditionalResult parameter is set, 
//                                      it contains the address of the additional temporary storage
//                                      , to which the procedure result must be placed
//                                      (or is already placed if Status = "Completed").
//   * BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//   * DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
//   * Messages - FixedArray -
//                                      
// 
// Example:
//  In general, running a long-running operation and processing its results is organized as follows:
//
//   1) The procedure to run in the background is added to the object manager module or common server module:
//    Procedure ExecuteAction(Parameters, ResultAddress) Export
//     …
//     PutToTempStorage(Result, ResultAddress);
//    EndProcedure
//
//   2) The operation is started on the server, and the idle handler is attached:
//    &AtClient
//    Procedure ExecuteAction()
//     TimeConsumingOperation = StartExecuteAtServer();
//     IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
//     …
//     CompletionNotification = New NotifyDescription("ExecuteActionCompletion", ThisObject);
//     TimeConsumingOperationsClient.WaitForCompletion(TimeConsumingOperation, CompletionNotification, IdleParameters);
//    EndProcedure
//
//    &AtServer
//    Function StartExecuteAtServer()
//     ProcedureParameters = New Structure;
//     …
//     ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
//     …
//     Return TimeConsumingOperations.ExecuteInBackground("DataProcessors.MyDataProcessor.ExecuteAction", 
//     ProcedureParameters, ExecutionParameters);
//    EndFunction
//    
//   3) The operation result is processed:
//    &AtClient
//    Procedure ExecuteActionCompletion(Result, AdditionalParameters) Export
//     If Result = Undefined Then
//      Return;
//     EndIf;
//     OutputResult(Result);
//    EndProcedure 
//  
Function ExecuteInBackground(Val ProcedureName, Val ProcedureParameters, Val ExecutionParameters) Export
	
	// 
	If ExecutionParameters.Property("WaitForCompletion") And ExecutionParameters.WaitForCompletion <> -1 Then
		ExecutionParameters.WaitCompletion = ExecutionParameters.WaitForCompletion;
	EndIf;
	
	CommonClientServer.CheckParameter("TimeConsumingOperations.ExecuteInBackground", "ExecutionParameters", 
		ExecutionParameters, Type("Structure")); 
	If ExecutionParameters.RunNotInBackground1 And ExecutionParameters.RunInBackground Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Parameters ""%1"" and ""%2""
			|cannot have value %3 in %4 at the same time.';"),
			"RunNotInBackground1", "RunInBackground", "True", "TimeConsumingOperations.ExecuteInBackground");
	EndIf;
	If ExecutionParameters.NoExtensions And ExecutionParameters.WithDatabaseExtensions Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Parameters ""%1"" and ""%2""
			|cannot have value %3 in %4 at the same time.';"),
			"NoExtensions", "WithDatabaseExtensions", "True", "TimeConsumingOperations.ExecuteInBackground");
	EndIf;
#If ExternalConnection Then
	FileInfobase = Common.FileInfobase();
	If ExecutionParameters.NoExtensions And FileInfobase Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Cannot start a background job with ""NoExtensions"" parameter
			|%1in a file infobase in %2.';"),
			"NoExtensions", "TimeConsumingOperations.ExecuteInBackground");
	ElsIf ExecutionParameters.WithDatabaseExtensions And FileInfobase Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
			"en = 'Cannot start a background job with ""NoExtensions"" parameter
			|%1in a file infobase in %2.';"),
			"WithDatabaseExtensions", "TimeConsumingOperations.ExecuteInBackground");
	EndIf;
#EndIf
	
	Result = New Structure;
	Result.Insert("MultiThreadOperation", ExecutionParameters.MultiThreadOperation);
	Result.Insert("Status", "Running");
	Result.Insert("JobID", Undefined);
	If ExecutionParameters.Property("ResultAddress") Then
		If ExecutionParameters.ResultAddress = Undefined Then
			If Not ValueIsFilled(ExecutionParameters.FormIdentifier) And Common.DebugMode() Then
				Try
					Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"en = 'Form UUID is not specified in the %1 parameter and temporary storage address is not specified
						|in the %2 parameter in %3.
						|Make sure that the temporary storage is cleared explicitly with the %4 method on result processing.';"),
						"ExecutionParameters.FormIdentifier", "ExecutionParameters.ResultAddress",
						"TimeConsumingOperations.ExecuteInBackground", "DeleteFromTempStorage");
				Except
					// ACC:154-on Recommendation: Log an a warning, not as an error.
					WriteLogEvent(NStr("en = 'Long-running operations.Diagnostics';", Common.DefaultLanguageCode()),
						EventLogLevel.Warning, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					// ACC:154-on 
				EndTry;
			EndIf;
			ExecutionParameters.ResultAddress = PutToTempStorage(Undefined, ExecutionParameters.FormIdentifier);
		ElsIf Not IsTempStorageURL(ExecutionParameters.ResultAddress) Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"en = 'Temporary storage address is not specified in the %1 parameter
				|in %2.';"),
				"ExecutionParameters.ResultAddress", "TimeConsumingOperations.ExecuteInBackground");
		EndIf;	
		Result.Insert("ResultAddress", ExecutionParameters.ResultAddress);
	EndIf;
	If ExecutionParameters.Property("AdditionalResult") Then
		Result.Insert("AdditionalResultAddress", "");
	EndIf;
	Result.Insert("BriefErrorDescription", "");
	Result.Insert("DetailErrorDescription", "");
	Result.Insert("Messages", New FixedArray(New Array));
	
	If ExecutionParameters.NoExtensions Then
		ExecutionParameters.NoExtensions = ValueIsFilled(SessionParameters.AttachedExtensions);
		
	ElsIf Not ExecutionParameters.WithDatabaseExtensions
	        And Not ExecutionParameters.RunNotInBackground1
	        And StandardSubsystemsServer.ThisIsSplitSessionModeWithNoDelimiters() Then
		
		ExecutionParameters.WithDatabaseExtensions = True;
	EndIf;
	
	ExportProcedureParameters = ProcedureParameters;
	If Not ExecutionParameters.Property("IsFunction") Then
		ExportProcedureParameters = New Array;
		ExportProcedureParameters.Add(ProcedureParameters);
		ExportProcedureParameters.Add(ExecutionParameters.ResultAddress);
	EndIf;
	
	If ExecutionParameters.Property("AdditionalResult") And ExecutionParameters.AdditionalResult Then
		Result.AdditionalResultAddress = PutToTempStorage(Undefined, ExecutionParameters.FormIdentifier);
		ExportProcedureParameters.Add(Result.AdditionalResultAddress);
	EndIf;
	
#If ExternalConnection Then
	ExecuteWithoutBackgroundJob = FileInfobase 
		Or Common.DebugMode() Or ExecutionParameters.RunNotInBackground1
		Or (BackgroundJobsExistInFileIB() And Not ExecutionParameters.RunInBackground) 
		Or Not CanRunInBackground(ProcedureName);
#Else
	ExecuteWithoutBackgroundJob = Not ExecutionParameters.NoExtensions
		And Not ExecutionParameters.WithDatabaseExtensions
		And (Common.DebugMode() Or ExecutionParameters.RunNotInBackground1
			Or (BackgroundJobsExistInFileIB() And Not ExecutionParameters.RunInBackground) 
			Or Not CanRunInBackground(ProcedureName));
#EndIf

	// Executing in the main thread.
	If ExecuteWithoutBackgroundJob Then
		Try
			If ExecutionParameters.Property("IsFunction") And ExecutionParameters.IsFunction Then
				CallFunction(ProcedureName, ExportProcedureParameters, ExecutionParameters.ResultAddress);
			Else
				CallProcedure(ProcedureName, ExportProcedureParameters);
			EndIf;
			Result.Status = "Completed2";
		Except
			Result.Status = "Error";
			Result.BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Result.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteLogEvent(NStr("en = 'Long-running operations.Runtime error';", Common.DefaultLanguageCode()),
				EventLogLevel.Error, , , Result.DetailErrorDescription);
		EndTry;
		Return Result;
	EndIf;
	
	// Executing in background.
	SafeMode = SafeMode();
	SetSafeModeDisabled(True);
	Try
		Job = RunBackgroundJobWithClientContext(ProcedureName,
			ExecutionParameters, ExportProcedureParameters, SafeMode,
			ExecutionParameters.WaitCompletion <> Undefined);
	Except
		Result.Status = "Error";
		If Job <> Undefined And Job.ErrorInfo <> Undefined Then
			Result.BriefErrorDescription = ErrorProcessing.BriefErrorDescription(Job.ErrorInfo);
			Result.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
		Else
			Result.BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Result.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndIf;
		Return Result;
	EndTry;
	SetSafeModeDisabled(False);
	
	If Job <> Undefined And Job.ErrorInfo <> Undefined Then
		Result.Status = "Error";
		Result.BriefErrorDescription = ErrorProcessing.BriefErrorDescription(Job.ErrorInfo);
		Result.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
		Return Result;
	EndIf;
	
	Result.JobID = Job.UUID;
	JobCompleted = False;
	
	If ExecutionParameters.WaitCompletion <> 0 Then
		Job = Job.WaitForExecutionCompletion(ExecutionParameters.WaitCompletion);
		If Job.State <> BackgroundJobState.Active Then
			JobCompleted = True;
		EndIf;
	EndIf;
	
	If JobCompleted Then
		If ExecutionParameters.WaitCompletion <> Undefined Then
			Messages = GetFromNotifications(True, Job.UUID, "Messages");
		Else
			Messages = Job.GetUserMessages(True);
		EndIf;
		Result.Messages = Messages;
	EndIf;
	
	FillPropertyValues(Result, ActionCompleted(Job.UUID), , "Messages");
	Return Result;
	
EndFunction

// Returns a new structure for the ExecutionParameters parameter of the ExecuteInBackground function.
//
// If RunInBackground = False and RunNotInBackground = False, the job will be executed in the background if possible.
// A job runs in the main thread if any of the following conditions is met:
//  * the procedure is called in the file infobase through an external connection (this mode has no background job support);
//  * the application runs in the debug mode (see /C DebugMode command-line parameter) for configuration debug purposes;
//  * the file infobase already has active background jobs (to avoid slow application response to user actions);
//  * the function belongs to an external data processor module or an external report module.
//
// Parameters:
//   FormIdentifier - UUID - a UUID of the form to whose temporary storage 
//                                                  the procedure result must be placed.
//                      - Undefined - 
//                                       
//                                       
//                                       
// Returns:
//   Structure:
//     * FormIdentifier      - UUID - a UUID of the form 
//                                 containing the temporary storage where the procedure puts its result.
//     * AdditionalResult - Boolean     - the flag that indicates whether additional temporary storage is to be used to pass 
//                                 the result from the background job to the parent session. The default value is False.
//     * WaitCompletion       - Number
//                               - Undefined - timeout in seconds for the background task to complete. 
//                                 If set to Undefined, wait until the task is completed. 
//                                 If set to 0, you do not need to wait for the task to complete. 
//                                 By default, it is 2 seconds; and for a low connection speed, it is 4 seconds. 
//     * BackgroundJobDescription - String - the description of the background job. The default value is the procedure name.
//     * BackgroundJobKey      - String    - the unique key for active background jobs that have the same procedure name.
//                                              Not set by default.
//     * ResultAddress          - String - the address of the temporary storage to which the procedure
//                                           result must be placed. If the address is not set, it is generated automatically 
//                                           for the lifetime of the form using the FormID ID.
//     * RunInBackground           - Boolean - If True, the job always runs in the background, except for the following cases:
//                                  a) the procedure is called in the file infobase through an external connection 
//                                  (this mode has no background job support);
//                                  b) the function belongs to an external data processor module or an external report module.
//                                  In the file mode, if any other background jobs are running,
//                                  the new job is queued and does not start running until all the previous jobs are completed.
//                                  If False, the job will be executed in the background if possible. 
//     * RunNotInBackground1         - Boolean - If True, the job always runs naturally
//                                  without using background jobs.
//     * NoExtensions            - Boolean - If True, no configuration extensions
//                                  are attached to run the background job. Has priority over the RunNotInBackground parameter. 
//     * WithDatabaseExtensions  - Boolean - If True, the background job will run with the latest version of
//                                  the configuration extensions. Has priority over the RunNotInBackground parameter. 
//
Function BackgroundExecutionParameters(Val FormIdentifier = Undefined) Export
	
	Result = CommonBackgroundExecutionParameters();
	AddExecutionParametersToReturnResult(Result, FormIdentifier);
	Result.Insert("AdditionalResult", False);
	
	Return Result;
	
EndFunction

// 
//  
// 
// 
// 
// 
//
//  
// (See TimeConsumingOperationsClient.IdleParameters)
//
// Parameters:
//  Percent                 - Number        - progress percentage.
//  Text                   - String       - details on the current action.
//  AdditionalParameters - Arbitrary - any additional information that must be passed to the client. 
//                                           The value must be serialized into the XML string.
//
Procedure ReportProgress(Val Percent = Undefined, Val Text = Undefined, Val AdditionalParameters = Undefined) Export
	
	If Not StandardSubsystemsCached.IsLongRunningOperationSession() Then
		Return;
	EndIf;
	
	ValueToPass = New Structure;
	If Percent <> Undefined Then
		ValueToPass.Insert("Percent", Percent);
	EndIf;
	If Text <> Undefined Then
		ValueToPass.Insert("Text", Text);
	EndIf;
	If AdditionalParameters <> Undefined Then
		ValueToPass.Insert("AdditionalParameters", AdditionalParameters);
	EndIf;
	
	SetPrivilegedMode(True);
	SetSafeModeDisabled(True);
	DateSent = SessionParameters.TimeConsumingOperations.ProgressMessageSendDate;
	SetSafeModeDisabled(False);
	SetPrivilegedMode(False);
	
	NewSendDate = CurrentSessionDate();
	If NewSendDate < DateSent + 3 Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	SetSafeModeDisabled(True);
	Properties = New Structure(SessionParameters.TimeConsumingOperations);
	Properties.ProgressMessageSendDate = NewSendDate;
	SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
	SetSafeModeDisabled(False);
	SetPrivilegedMode(False);
	
	SendClientNotification("Progress", ValueToPass);
	
EndProcedure

//  
// 
//
// 
// 
//
// Parameters:
//   JobID - UUID - a background job ID.
//
// Returns:
//   Undefined, Structure - 
//    * Percent                 - Number  - optional. Progress percentage.
//    * Text                   - String - optional. Details on the current action.
//    * AdditionalParameters - Arbitrary - optional. Any additional information.
//
Function ReadProgress(Val JobID) Export
	
	Return GetFromNotifications(True, JobID, "Progress");
	
EndFunction

// Cancels background job execution by the passed ID.
// If the transactions are opened in long-running operation, the last open transaction will be rolled back.
//
// Thus, if the long-running operation is processing (recording) data, record in one transaction
// to cancel the whole operation completely (in this case the whole operation will be canceled).
// If it is enough not to cancel long-running operation completely, but to cancel it at the achieved level,
// then it is not required to open one long-running transaction.
// 
// Parameters:
//  JobID - UUID -
//                           
// 
Procedure CancelJobExecution(Val JobID) Export 
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	If SessionParameters.TimeConsumingOperations.CanceledJobs.Find(JobID) = Undefined Then
		Properties = New Structure(SessionParameters.TimeConsumingOperations);
		CanceledJobs = New Array(Properties.CanceledJobs);
		CanceledJobs.Add(JobID);
		Properties.CanceledJobs = New FixedArray(CanceledJobs);
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
	EndIf;
	SetPrivilegedMode(False);
	
	Job = FindJobByID(JobID);
	If Job = Undefined Or Job.State <> BackgroundJobState.Active Then
		Return;
	EndIf;
	
	Try
		Job.Cancel();
	Except
		// The job might have been completed at that moment and no error occurred.
		WriteLogEvent(NStr("en = 'Long-running operations.Cancel background job';", Common.DefaultLanguageCode()),
			EventLogLevel.Information, , , ErrorProcessing.BriefErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

// Checks background job state by the passed ID.
// If the job terminates abnormally, raises the exception that was generated
// or a common exception "Cannot perform the operation. See the event log for details". 
//
// Parameters:
//  JobID - UUID - a background job ID. 
//
// Returns:
//  Boolean - 
// 
Function JobCompleted(Val JobID) Export
	
	Job = Undefined;
	Result = ActionCompleted(JobID, Job);
	
	If Result.Status = "Running" Then
		Return False;
	ElsIf Result.Status = "Completed2" Then
		Return True;
	EndIf;
	
	If Result.Status = "Canceled" Then
		ErrorText = NStr("en = 'Operation canceled';");
		
	ElsIf Job = Undefined Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1
			           |
			           |Technical details:
			           |%2
			           |
			           |See also the event log.';"),
			Result.BriefErrorDescription,
			Result.DetailErrorDescription);
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1
			           |
			           |Technical details:
			           |An error occurred while executing background job %2 with ID %3. Reason:
			           |%4
			           |
			           |See the Event log for details.';"),
			Result.BriefErrorDescription,
			Job.MethodName,
			String(JobID),
			Result.DetailErrorDescription);
	EndIf;
	
	Raise ErrorText;
	
EndFunction

// 
//
// 
// 
// 
// Parameters:
//  ToDeleteGetting    - Boolean                  - the flag indicates whether the received messages need to be deleted.
//  JobID - UUID - the ID of the background job corresponding to a long-running 
//                                                   operation that generates messages intended for the user. 
//                                                   If not set, the messages intended for the user are returned
//                                                   from the current user session.
// 
// Returns:
//  FixedArray - 
//
// Example:
//   Operation = TimeConsumingOperations.ExecuteInBackground(…);
//   …
//   Messages = TimeConsumingOperations.MessageToUsers(True, Operation.JobID);
//
Function UserMessages(ToDeleteGetting = False, JobID = Undefined) Export
	
	If ValueIsFilled(JobID) Then
		Return GetFromNotifications(ToDeleteGetting, JobID, "Messages");
	EndIf;
	
	Return GetUserMessages(ToDeleteGetting);
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use ExecuteInBackground instead.
//
// Executes procedures in a background job.
// Similar to ExecuteInBackground but with less functionality. Intended for backward compatibility.
// 
// Parameters:
//  FormIdentifier     - UUID - the ID of the form 
//                           used to start the long-running operation. 
//  ExportProcedureName - String - the name of the export procedure 
//                           that must be run in background.
//  Parameters              - Structure - all parameters required 
//                           to execute the ExportProcedureName procedure.
//  JobDescription    - String - the description of the background job. 
//                           If JobDescription is not specified it is equal to ExportProcedureName. 
//  UseAdditionalTempStorage - Boolean - the flag indicates whether
//                           additional temporary storage is to be used to pass data from the background job
//                           to the parent session. The default value is False.
//
// Returns:
//  Structure              -  
//   * StorageAddress  - String     - the address of the temporary storage where the job result must be
//                                    stored;
//   * StorageAddressAdditional - String - the address of the additional temporary storage
//                                    where the job result must be stored (can only be used 
//                                    when UseAdditionalTempStorage is set);
//   * JobID - UUID - the unique ID of the running background job;
//   * JobCompleted - Boolean - True if the job is completed successfully during the function call.
// 
Function StartBackgroundExecution(Val FormIdentifier, Val ExportProcedureName, Val Parameters,
	Val JobDescription = "", UseAdditionalTempStorage = False) Export
	
	StorageAddress = PutToTempStorage(Undefined, FormIdentifier);
	
	Result = New Structure;
	Result.Insert("StorageAddress",       StorageAddress);
	Result.Insert("JobCompleted",     False);
	Result.Insert("JobID", Undefined);
	
	If Not ValueIsFilled(JobDescription) Then
		JobDescription = ExportProcedureName;
	EndIf;
	
	ExportProcedureParameters = New Array;
	ExportProcedureParameters.Add(Parameters);
	ExportProcedureParameters.Add(StorageAddress);
	
	If UseAdditionalTempStorage Then
		StorageAddressAdditional = PutToTempStorage(Undefined, FormIdentifier);
		ExportProcedureParameters.Add(StorageAddressAdditional);
	EndIf;
	
	JobsRunning = 0;
	If Common.FileInfobase()
		And Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		JobsRunning = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	
	If Common.DebugMode()
		Or JobsRunning > 0 Then
		Common.ExecuteConfigurationMethod(ExportProcedureName, ExportProcedureParameters);
		Result.JobCompleted = True;
	Else
		Timeout = ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 2);
		ExecutionParameters = BackgroundExecutionParameters(Undefined);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		SafeMode = SafeMode();
		SetSafeModeDisabled(True);
		Job = RunBackgroundJobWithClientContext(ExportProcedureName,
			ExecutionParameters, ExportProcedureParameters, SafeMode);
		SetSafeModeDisabled(False);
		
		Job = Job.WaitForExecutionCompletion(Timeout);
		
		Status = ActionCompleted(Job.UUID);
		Result.JobCompleted = Status.Status = "Completed2";
		Result.JobID = Job.UUID;
	EndIf;
	
	If UseAdditionalTempStorage Then
		Result.Insert("StorageAddressAdditional", StorageAddressAdditional);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

// Parameters:
//  JobID - UUID
//  Job - BackgroundJob -
//          - Undefined - 
//
// Returns:
//   See OperationNewRuntimeResult
//
Function ActionCompleted(Val JobID, Job = Undefined) Export
	
	Result = OperationNewRuntimeResult();
	
	Job = FindJobByID(JobID);
	If Job = Undefined Then
		ResultFromNotification = GetFromNotifications(False,
			JobID, "TimeConsumingOperationCompleted");
		If ResultFromNotification <> Undefined Then
			FillPropertyValues(Result, ResultFromNotification);
			Return Result;
		EndIf;
		Result.BriefErrorDescription =
			NStr("en = 'Cannot perform the operation due to abnormal termination of a background job.';");
		Result.DetailErrorDescription = Result.BriefErrorDescription + Chars.LF
			+ NStr("en = 'The background job does not exist';") + ": " + String(JobID);
		WriteLogEvent(NStr("en = 'Long-running operations.Background job not found';", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , Result.DetailErrorDescription);
		Result.Status = "Error";
		Return Result;
	EndIf;
	
	WritePendingUserMessages(Job.UUID);
	
	If Job.State = BackgroundJobState.Active Then
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Canceled Then
		SetPrivilegedMode(True);
		If SessionParameters.TimeConsumingOperations.CanceledJobs.Find(JobID) = Undefined Then
			Result.Status = "Error";
			If Job.ErrorInfo <> Undefined Then
				Result.BriefErrorDescription   = NStr("en = 'Operation canceled by administrator.';");
				Result.DetailErrorDescription = Result.BriefErrorDescription;
			EndIf;
		Else
			Result.Status = "Canceled";
		EndIf;
		SetPrivilegedMode(False);
		Return Result;
	EndIf;
	
	If Job.State = BackgroundJobState.Failed 
		Or Job.State = BackgroundJobState.Canceled Then
		
		Result.Status = "Error";
		If Job.ErrorInfo <> Undefined Then
			Result.BriefErrorDescription   = ErrorProcessing.BriefErrorDescription(Job.ErrorInfo);
			Result.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
		EndIf;
		Return Result;
	EndIf;
	
	Result.Status = "Completed2";
	Return Result;
	
EndFunction

Procedure RunDataProcessorObjectModuleProcedure(Parameters, StorageAddress) Export 
	
	If SafeMode() <> False Then
		SafeMode = SafeMode();
	ElsIf Parameters.Property("SafeMode") And Parameters.SafeMode <> False Then
		SafeMode = Parameters.SafeMode;
	Else
		SafeMode = False;
	EndIf;
	
	If Parameters.IsExternalDataProcessor Then
		Ref = CommonClientServer.StructureProperty(Parameters, "AdditionalDataProcessorRef");
		If ValueIsFilled(Ref) And Common.SubsystemExists("StandardSubsystems.AdditionalReportsAndDataProcessors") Then
			DataProcessor = Common.CommonModule("AdditionalReportsAndDataProcessors").ExternalDataProcessorObject(Ref);
		Else
			VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
			DataProcessor = ExternalDataProcessors.Create(Parameters.DataProcessorName, SafeMode);
		EndIf;
	Else
		DataProcessor = DataProcessors[Parameters.DataProcessorName].Create();
	EndIf;
	
	If SafeMode() = False And SafeMode <> False Then
		SetSafeMode(SafeMode);
	EndIf;
	
	Try
		FullProcedureName = DataProcessor.Metadata().FullName() + "." + Parameters.MethodName;
	Except
		FullProcedureName = Parameters.MethodName;
	EndTry;
	
	SetFullNameOfAppliedProcedure(FullProcedureName);
	
	MethodParameters = New Array;
	MethodParameters.Add(Parameters.ExecutionParameters);
	MethodParameters.Add(StorageAddress);
	Common.ExecuteObjectMethod(DataProcessor, Parameters.MethodName, MethodParameters);
	
EndProcedure

Procedure RunReportObjectModuleProcedure(Parameters, StorageAddress) Export
	
	If SafeMode() <> False Then
		SafeMode = SafeMode();
	ElsIf Parameters.Property("SafeMode") And Parameters.SafeMode <> False Then
		SafeMode = Parameters.SafeMode;
	Else
		SafeMode = False;
	EndIf;
	
	If Parameters.IsExternalReport Then
		VerifyAccessRights("InteractiveOpenExtReports", Metadata);
		Report = ExternalReports.Create(Parameters.ReportName, SafeMode);
	Else
		Report = Reports[Parameters.ReportName].Create();
	EndIf;
	
	If SafeMode() = False And SafeMode <> False Then
		SetSafeMode(SafeMode);
	EndIf;
	
	Try
		FullProcedureName = Report.Metadata().FullName() + "." + Parameters.MethodName;
	Except
		FullProcedureName = Parameters.MethodName;
	EndTry;
	
	SetFullNameOfAppliedProcedure(FullProcedureName);
	
	MethodParameters = New Array;
	MethodParameters.Add(Parameters.ExecutionParameters);
	MethodParameters.Add(StorageAddress);
	Common.ExecuteObjectMethod(Report, Parameters.MethodName, MethodParameters);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	If ParameterName = "TimeConsumingOperations" Then
		Properties = New Structure;
		Properties.Insert("CanceledJobs", New FixedArray(New Array));
		Properties.Insert("ReceivedNotifications", New FixedMap(New Map));
		Properties.Insert("ProgressMessageSendDate", '00010101');
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
		SpecifiedParameters.Add("TimeConsumingOperations");
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddServerNotifications
Procedure OnAddServerNotifications(Notifications) Export
	
	Notification = ServerNotifications.NewServerNotification(NameOfAlert());
	Notification.NotificationSendModuleName  = "";
	Notification.NotificationReceiptModuleName = "TimeConsumingOperationsClient";
	
	Notifications.Insert(Notification.Name, Notification);
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// See JobsQueueOverridable.OnDefineHandlerAliases
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert(
		Metadata.ScheduledJobs.StartThreadsOfLongRunningOperations.MethodName);
	
EndProcedure

#EndRegion

#Region Private

Function OperationNewRuntimeResult() Export
	
	Result = New Structure;
	Result.Insert("Status", "Running");
	Result.Insert("BriefErrorDescription", Undefined);
	Result.Insert("DetailErrorDescription", Undefined);
	Result.Insert("Progress", Undefined);
	Result.Insert("Messages", Undefined);
	
	Return Result;
	
EndFunction

// 
// 
// Returns:
//  Structure:
//   * MethodName - String
//   * ForFunction - Boolean
//   * OperationParametersList -  See FunctionExecutionParameters
//   * MethodParameters - Map
//   * ResultAddress - String
//   * AbortExecutionIfError - Boolean
//   * AddressResults - String
//
Function MultithreadOperationParameters(ProcessID, SavedParameters1 = Undefined) 
	
	MultithreadOperationParameters = New Structure;
	MultithreadOperationParameters.Insert("MethodName",                    "");
	MultithreadOperationParameters.Insert("ForFunction",                   False);
	MultithreadOperationParameters.Insert("OperationParametersList",            FunctionExecutionParameters(ProcessID));
	MultithreadOperationParameters.Insert("MethodParameters",              New Map());
	MultithreadOperationParameters.Insert("ResultAddress",              "");
	MultithreadOperationParameters.Insert("AbortExecutionIfError", False);
	MultithreadOperationParameters.Insert("AddressResults",             "");
	MultithreadOperationParameters.Insert("MultiThreadOperation",        False);
	
	If TypeOf(SavedParameters1) = Type("Structure") Then
		FillPropertyValues(MultithreadOperationParameters, SavedParameters1);
	EndIf;
	
	Return MultithreadOperationParameters;
	
EndFunction

// See CommonOverridable.OnReceiptRecurringClientDataOnServer
Procedure OnReceiptRecurringClientDataOnServer(Parameters, Results) Export
	
	CheckParameters = Parameters.Get( // See TimeConsumingOperationsClient.ПараметрыПроверкиДлительныхОпераций
		"StandardSubsystems.Core.LongRunningOperationCheckParameters");
	
	If CheckParameters = Undefined Then
		Return;
	EndIf;
	
	Results.Insert("StandardSubsystems.Core.LongRunningOperationCheckResult",
		LongRunningOperationCheckResult(CheckParameters));
	
EndProcedure

// Parameters:
//  Parameters - See TimeConsumingOperationsClient.ПараметрыПроверкиДлительныхОпераций
//
// Returns:
//  Map of KeyAndValue:
//   * Key     - UUID -
//   * Value - See ActionCompleted
//  
Function LongRunningOperationCheckResult(Parameters) Export
	
	Result = New Map;
	For Each JobID In Parameters.JobsToCheck Do
		Result.Insert(JobID, ActionCompleted(JobID));
	EndDo;
	
	For Each JobID In Parameters.JobsToCancel Do
		CancelJobExecution(JobID);
		Result.Insert(JobID, New Structure("Status", "Canceled"));
	EndDo;
	
	Return Result;
	
EndFunction

Function RunBackgroundJobWithClientContext(ProcedureName,
			ExecutionParameters, ProcedureParameters = Undefined, SafeMode = False, ShouldSendNotifications = False) Export
	
	BackgroundJobKey = ExecutionParameters.BackgroundJobKey;
	BackgroundJobDescription = ?(IsBlankString(ExecutionParameters.BackgroundJobDescription),
		ProcedureName, ExecutionParameters.BackgroundJobDescription);
	
	ClientParameters = StandardSubsystemsServer.ClientParametersAtServer(False);
	If ShouldSendNotifications And Not ValueIsFilled(ClientParameters.Get("ParentSessionKey")) Then
		ClientParameters = New Map(ClientParameters);
		ClientParameters.Insert("ParentSessionKey", ServerNotifications.SessionKey());
		ClientParameters = New FixedMap(ClientParameters);
	EndIf;
	
	AllParameters = New Structure;
	AllParameters.Insert("ProcedureName",       ProcedureName);
	AllParameters.Insert("ProcedureParameters", ProcedureParameters);
	AllParameters.Insert("ClientParametersAtServer", ClientParameters);
	AllParameters.Insert("ExecutionParameters", ExecutionParameters);
	AllParameters.Insert("SafeMode",     SafeMode);
	
	If Not ExecutionParameters.NoExtensions
		And Not ExecutionParameters.WithDatabaseExtensions Then		
		Catalogs.ExtensionsVersions.InsertARegisteredSetOfInstalledExtensions(AllParameters);
	EndIf;
	
	BackgroundJobProcedureParameters = New Array;
	BackgroundJobProcedureParameters.Add(AllParameters);
	
	NameOfTheBackgroundTaskProcedure = NameOfLongRunningOperationBackgroundJobProcedure();
	
	Return RunBackgroundJob(ExecutionParameters,
		NameOfTheBackgroundTaskProcedure, BackgroundJobProcedureParameters,
		BackgroundJobKey, BackgroundJobDescription);
	
EndFunction

// 
// 
// 
//
Function ShouldSkipHandlerBeforeAppStartup() Export
	
	If CurrentRunMode() <> Undefined Then
		Return False;
	EndIf;
	
	BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
	If BackgroundJob = Undefined Then
		Return False;
	EndIf;
	
	MethodName = Lower(BackgroundJob.MethodName);
	If MethodName = Lower(NameOfLongRunningOperationBackgroundJobProcedure()) Then
		Return True;
	EndIf;
	
	For Each ScheduledJob In Metadata.ScheduledJobs Do
		If MethodName = Lower(ScheduledJob.MethodName) Then
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

Function NameOfLongRunningOperationBackgroundJobProcedure()
	
	Return "TimeConsumingOperations.ExecuteWithClientContext";
	
EndFunction

// Returns:
//  String
//
Function FullNameOfLongRunningOperationAppliedProcedure() Export
	
	If Not StandardSubsystemsCached.IsLongRunningOperationSession() Then
		Return "";
	EndIf;
	
	FullName = StandardSubsystemsServer.ClientParametersAtServer(False).Get(
		"FullNameOfLongRunningOperationAppliedProcedure");
	
	Return String(FullName);
	
EndFunction

Procedure SetFullNameOfAppliedProcedure(FullProcedureName)
	
	If Not StandardSubsystemsCached.IsLongRunningOperationSession() Then
		Return;
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	ClientParameters = New Map(SessionParameters.ClientParametersAtServer);
	ClientParameters.Insert("FullNameOfLongRunningOperationAppliedProcedure", FullProcedureName);
	SessionParameters.ClientParametersAtServer = New FixedMap(ClientParameters);
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// Continuation of the RunBackgroundJobWithClientContext procedure.
Procedure ExecuteWithClientContext(AllParameters) Export
	
	ClientParameters = AllParameters.ClientParametersAtServer;
	If ValueIsFilled(ClientParameters.Get("ParentSessionKey"))
	   And Not ValueIsFilled(ClientParameters.Get("MultithreadProcessJobID")) Then
		
		BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
		If BackgroundJob <> Undefined
		   And AllParameters.ProcedureName = MultithreadProcessMethodName() Then
			ClientParameters = New Map(ClientParameters);
			ClientParameters.Insert("MultithreadProcessJobID",
				BackgroundJob.UUID);
			ClientParameters = New FixedMap(ClientParameters);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	SessionParameters.ClientParametersAtServer = ClientParameters;
	Catalogs.ExtensionsVersions.RestoreTheRegisteredCompositionOfInstalledExtensions(AllParameters);
	Catalogs.ExtensionsVersions.RegisterExtensionsVersionUsage();
	SetPrivilegedMode(False);
	
	If SafeMode() = False And AllParameters.SafeMode <> False Then
		If Upper(AllParameters.ProcedureName) = Upper("TimeConsumingOperations.RunDataProcessorObjectModuleProcedure")
		 Or Upper(AllParameters.ProcedureName) = Upper("TimeConsumingOperations.RunReportObjectModuleProcedure") Then
			
			AllParameters.ProcedureParameters[0].Insert("SafeMode", AllParameters.SafeMode);
		Else
			SetSafeMode(AllParameters.SafeMode);
		EndIf;
	EndIf;
	
	SetFullNameOfAppliedProcedure(AllParameters.ProcedureName);
	Result = OperationNewRuntimeResult();
	Try
		If AllParameters.ExecutionParameters.Property("IsFunction") And AllParameters.ExecutionParameters.IsFunction Then
			CallFunction(AllParameters.ProcedureName, AllParameters.ProcedureParameters, AllParameters.ExecutionParameters.ResultAddress);
		Else
			CallProcedure(AllParameters.ProcedureName, AllParameters.ProcedureParameters);
		EndIf;
		Result.Status = "Completed2";
	Except
		ErrorInfo = ErrorInfo();
		Result.Status = "Error";
		Result.BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		Result.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		SetFullNameOfAppliedProcedure(NameOfLongRunningOperationBackgroundJobProcedure());
		SendClientNotification("TimeConsumingOperationCompleted", Result);
		Raise;
	EndTry;
	
	SetFullNameOfAppliedProcedure(NameOfLongRunningOperationBackgroundJobProcedure());
	SendClientNotification("TimeConsumingOperationCompleted", Result);
	
EndProcedure

Procedure CallProcedure(ProcedureName, CallParameters)
	
	NameParts = StrSplit(ProcedureName, ".");
	IsDataProcessorModuleProcedure = (NameParts.Count() = 4) And Upper(NameParts[2]) = "OBJECTMODULE";
	If Not IsDataProcessorModuleProcedure Then
		Common.ExecuteConfigurationMethod(ProcedureName, CallParameters);
		Return;
	EndIf;
	
	IsDataProcessor = Upper(NameParts[0]) = "DATAPROCESSOR";
	IsReport = Upper(NameParts[0]) = "REPORT";
	If IsDataProcessor Or IsReport Then
		ObjectManager = ?(IsReport, Reports, DataProcessors);
		DataProcessorReportObject = ObjectManager[NameParts[1]].Create();
		Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], CallParameters);
		Return;
	EndIf;
	
	IsExternalDataProcessor = Upper(NameParts[0]) = "EXTERNALDATAPROCESSOR";
	IsExternalReport = Upper(NameParts[0]) = "EXTERNALREPORT";
	If IsExternalDataProcessor Or IsExternalReport Then
		VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
		ObjectManager = ?(IsExternalReport, ExternalReports, ExternalDataProcessors);
		DataProcessorReportObject = ObjectManager.Create(NameParts[1], SafeMode());
		Common.ExecuteObjectMethod(DataProcessorReportObject, NameParts[3], CallParameters);
		Return;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invalid format of the %2 parameter (passed value: %1).';"), ProcedureName, "ProcedureName");
	
EndProcedure

Procedure CallFunction(FunctionName, ProcedureParameters, ResultAddress)
	
	NameParts = StrSplit(FunctionName, ".");
	IsDataProcessorModuleProcedure = (NameParts.Count() = 4) And Upper(NameParts[2]) = "OBJECTMODULE";
	If Not IsDataProcessorModuleProcedure Then
		Result = Common.CallConfigurationFunction(FunctionName, ProcedureParameters);
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	IsDataProcessor = Upper(NameParts[0]) = "DATAPROCESSOR";
	IsReport = Upper(NameParts[0]) = "REPORT";
	If IsDataProcessor Or IsReport Then
		ObjectManager = ?(IsReport, Reports, DataProcessors);
		DataProcessorReportObject = ObjectManager[NameParts[1]].Create();
		Result = Common.CallObjectFunction(DataProcessorReportObject, NameParts[3], ProcedureParameters);
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	IsExternalDataProcessor = Upper(NameParts[0]) = "EXTERNALDATAPROCESSOR";
	IsExternalReport = Upper(NameParts[0]) = "EXTERNALREPORT";
	If IsExternalDataProcessor Or IsExternalReport Then
		VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
		ObjectManager = ?(IsExternalReport, ExternalReports, ExternalDataProcessors);
		DataProcessorReportObject = ObjectManager.Create(NameParts[1], SafeMode());
		Result = Common.CallObjectFunction(DataProcessorReportObject, NameParts[3], ProcedureParameters);
		PutToTempStorage(Result, ResultAddress);
		Return;
	EndIf;
	
	Raise StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Invalid format of the %2 parameter (passed value: %1).';"), FunctionName, "FunctionName");
	
EndProcedure

Function FindJobByID(Val JobID)
	
	If TypeOf(JobID) = Type("String") Then
		JobID = New UUID(JobID);
	EndIf;
	
	Job = BackgroundJobs.FindByUUID(JobID);
	Return Job;
	
EndFunction

Function GetFromNotifications(ShouldSkipReceivedNotifications, JobID, NotificationsType)
	
	WritePendingUserMessages(JobID);
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	LastAlert = Undefined;
	If ShouldSkipReceivedNotifications Then
		LastNotifications = SessionParameters.TimeConsumingOperations.ReceivedNotifications.Get(JobID);
		If LastNotifications <> Undefined Then
			LastAlert = LastNotifications[NotificationsType];
		EndIf;
	EndIf;
	Notifications = ServerNotifications.ServerNotificationForClient(JobID, LastAlert);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	NotificationsMessages = New Array;
	If NotificationsType = "Messages" Then
		Result = New FixedArray(NotificationsMessages);
	Else
		Result = Undefined;
	EndIf;
	
	For Each Notification In Notifications Do
		Parameters = Notification.Content.Result;
		If TypeOf(Parameters) <> Type("Structure")
		 Or Not Parameters.Property("Result")
		 Or TypeOf(Parameters.Result) <> Type("Structure") Then
			Continue;
		EndIf;
		If NotificationsType = "TimeConsumingOperationCompleted"
		   And Parameters.Property("NotificationKind")
		   And Parameters.NotificationKind = NotificationsType Then
			Return Parameters.Result;
		EndIf;
		If Not Parameters.Result.Property(NotificationsType)
		 Or NotificationsType = "Messages"
		   And TypeOf(Parameters.Result[NotificationsType]) <> Type("FixedArray")
		 Or NotificationsType = "Progress"
		   And TypeOf(Parameters.Result[NotificationsType]) <> Type("Structure") Then
			Continue;
		EndIf;
		If NotificationsType = "Messages" Then
			For Each Message In Parameters.Result.Messages Do
				NotificationsMessages.Add(Message)
			EndDo;
			Result = New FixedArray(NotificationsMessages);
		Else
			Result = Parameters.Result.Progress;
		EndIf;
	EndDo;
	
	If ShouldSkipReceivedNotifications And ValueIsFilled(Notification) Then
		Notification.Delete("Content");
		SetSafeModeDisabled(True);
		SetPrivilegedMode(True);
		Properties = New Structure(SessionParameters.TimeConsumingOperations);
		ReceivedNotifications = New Map(Properties.ReceivedNotifications);
		LastNotifications = ReceivedNotifications.Get(JobID);
		If LastNotifications = Undefined Then
			LastNotifications = New Structure("Messages, Progress");
		Else
			LastNotifications = New Structure(LastNotifications);
		EndIf;
		LastNotifications[NotificationsType] = New FixedStructure(Notification);
		ReceivedNotifications.Insert(JobID, New FixedStructure(LastNotifications));
		KeysOfObsoleteNotifications = New Array;
		For Each KeyAndValue In ReceivedNotifications Do
			ReceivedNotification = ?(KeyAndValue.Value.Messages = Undefined,
				KeyAndValue.Value.Progress, KeyAndValue.Value.Messages);
			If ReceivedNotification.AddedOn + 60*60 < CurrentSessionDate() Then
				KeysOfObsoleteNotifications.Add(KeyAndValue.Key);
			EndIf;
		EndDo;
		For Each Var_Key In KeysOfObsoleteNotifications Do
			ReceivedNotifications.Delete(Var_Key);
		EndDo;
		Properties.ReceivedNotifications = New FixedMap(ReceivedNotifications);
		SessionParameters.TimeConsumingOperations = New FixedStructure(Properties);
		SetPrivilegedMode(False);
		SetSafeModeDisabled(False);
	EndIf;
	
	Return Result;
	
EndFunction

Function NameOfAlert()
	
	Return "StandardSubsystems.Core.TimeConsumingOperations";
	
EndFunction

// Parameters:
//  Data - See ServerNotifications.MessageNewData
// 
// Returns:
//  Boolean
//
Function ShouldSkipNotification(Data) Export
	
	// 
	// 
	// 
	// 
	// 
	// 
	// 
	// 
	
	Return Data.NameOfAlert = NameOfAlert()
	      And Data.Result.NotificationKind = "TimeConsumingOperationCompleted"
	      And Not ServerNotifications.CollaborationSystemConnected();
	
EndFunction

Procedure SendClientNotification(NotificationKind, ValueToPass, BackgroundJob = Undefined) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	WriteUserMessages = BackgroundJob <> Undefined And NotificationKind = "UserMessage";
	If WriteUserMessages Then
		ParentSessionKey = ServerNotifications.SessionKey();
		MainJobID = BackgroundJob.UUID;
	Else
		ParentSessionKey = StandardSubsystemsServer.ClientParametersAtServer(False).Get(
			"ParentSessionKey");
		If Not ValueIsFilled(ParentSessionKey) Then
			Return;
		EndIf;
		BackgroundJob = GetCurrentInfoBaseSession().GetBackgroundJob();
		If BackgroundJob = Undefined Then
			Return;
		EndIf;
		MultithreadProcessJobID =
			StandardSubsystemsServer.ClientParametersAtServer(False).Get(
				"MultithreadProcessJobID");
		MainJobID = ?(ValueIsFilled(MultithreadProcessJobID),
			MultithreadProcessJobID, BackgroundJob.UUID);
	EndIf;
	
	If NotificationKind = "TimeConsumingOperationCompleted" Then
		If ValueIsFilled(MultithreadProcessJobID) Then
			Return;
		EndIf;
		Result = ValueToPass;
	Else
		Result = OperationNewRuntimeResult();
	EndIf;
	If NotificationKind = "UserMessage" Then
		Result.Messages = New FixedArray(
			CommonClientServer.ValueInArray(ValueToPass));
	ElsIf NotificationKind = "Progress" Then
		Messages = BackgroundJob.GetUserMessages(True);
		For Each Message In Messages Do
			SendClientNotification("UserMessage", Message);
		EndDo;
		Result.Messages = New FixedArray(New Array);
		Result.Progress = ValueToPass;
	ElsIf NotificationKind = "TimeConsumingOperationCompleted" Then
		Messages = BackgroundJob.GetUserMessages(True);
		For Each Message In Messages Do
			SendClientNotification("UserMessage", Message);
		EndDo;
	EndIf;
	
	NotificationParameters = New Structure("NotificationKind, JobID, Result",
		NotificationKind, MainJobID, Result);
	
	SessionsKeys = CommonClientServer.ValueInArray(ParentSessionKey);
	SMSMessageRecipients = New Map;
	SMSMessageRecipients.Insert(InfoBaseUsers.CurrentUser().UUID, SessionsKeys);
	
	ServerNotifications.SendServerNotificationWithGroupID(NameOfAlert(),
		NotificationParameters, SMSMessageRecipients, Not WriteUserMessages, MainJobID);
	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
EndProcedure

// 
// 
//
// Parameters:
//  JobID - UUID
//
Procedure WritePendingUserMessages(JobID)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	If BackgroundJob <> Undefined Then
		Messages = BackgroundJob.GetUserMessages(True);
		For Each Message In Messages Do
			SendClientNotification("UserMessage", Message, BackgroundJob);
		EndDo;
	EndIf;
	
EndProcedure

Function BackgroundJobsExistInFileIB()
	
	JobsRunningInFileIB = 0;
	If Common.FileInfobase() And Not InfobaseUpdate.InfobaseUpdateRequired() Then
		Filter = New Structure;
		Filter.Insert("State", BackgroundJobState.Active);
		JobsRunningInFileIB = BackgroundJobs.GetBackgroundJobs(Filter).Count();
	EndIf;
	Return JobsRunningInFileIB > 0;

EndFunction

Function CanRunInBackground(ProcedureName)
	
	NameParts = StrSplit(ProcedureName, ".");
	If NameParts.Count() = 0 Then
		Return False;
	EndIf;
	
	IsExternalDataProcessor = (Upper(NameParts[0]) = "EXTERNALDATAPROCESSOR");
	IsExternalReport = (Upper(NameParts[0]) = "EXTERNALREPORT");
	Return Not (IsExternalDataProcessor Or IsExternalReport);

EndFunction

Function RunBackgroundJob(ExecutionParameters, MethodName, Parameters, Var_Key, Description)
	
	If CurrentRunMode() = Undefined
		And Common.FileInfobase() Then
		
		Session = GetCurrentInfoBaseSession();
		If ExecutionParameters.WaitCompletion = Undefined And Session.ApplicationName = "BackgroundJob" Then
			Raise NStr("en = 'In a file infobase, only one background job can run at a time.';");
		ElsIf Session.ApplicationName = "COMConnection" Then
			Raise NStr("en = 'In a file infobase, background jobs can only be started from the client application.';");
		EndIf;
		
	EndIf;
	
	If ExecutionParameters.NoExtensions Then
		Return ConfigurationExtensions.ExecuteBackgroundJobWithoutExtensions(MethodName, Parameters, Var_Key, Description);
	
	ElsIf ExecutionParameters.WithDatabaseExtensions Then
		Return ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(MethodName, Parameters, Var_Key, Description);
	Else
		Return BackgroundJobs.Execute(MethodName, Parameters, Var_Key, Description);
	EndIf;
	
EndFunction

Function ParametersList(Val Parameter1, Val Parameter2, Val Parameter3, Val Parameter4,
	Val Parameter5, Val Parameter6, Val Parameter7)
	
	PassedParameters = New Array;
	PassedParameters.Add(Parameter7);
	PassedParameters.Add(Parameter6);
	PassedParameters.Add(Parameter5);
	PassedParameters.Add(Parameter4);
	PassedParameters.Add(Parameter3);
	PassedParameters.Add(Parameter2);
	PassedParameters.Add(Parameter1);
	
	Result = New Array;
	
	For Each Parameter In PassedParameters Do
		If Result.Count() = 0 And Parameter = Undefined Then
			Continue;
		EndIf;
		Result.Insert(0, Parameter);
	EndDo;
	
	Return Result;

EndFunction

Function PrepareExecutionParameters(PassedParameter, ForFunction)
	
	Result = CommonBackgroundExecutionParameters();
	
	If ValueIsFilled(PassedParameter) Then
		If TypeOf(PassedParameter) = Type("Structure") Then
			Result = PassedParameter;
		ElsIf ForFunction Then
			Id = Undefined;
			If TypeOf(PassedParameter) = Type("ClientApplicationForm") Then
				Id = PassedParameter.UUID;
			ElsIf TypeOf(PassedParameter) = Type("UUID") Then
				Id = PassedParameter;
			EndIf;
			AddExecutionParametersToReturnResult(Result, Id);
		EndIf;
	EndIf;
	
	Result.Insert("IsFunction", ForFunction);
	Return Result;
	
EndFunction

Function CommonBackgroundExecutionParameters()
	
	Result = New Structure;
	Result.Insert("WaitCompletion", ?(GetClientConnectionSpeed() = ClientConnectionSpeed.Low, 4, 0.8));
	Result.Insert("BackgroundJobDescription", "");
	Result.Insert("BackgroundJobKey", "");
	Result.Insert("RunNotInBackground1", False);
	Result.Insert("RunInBackground", False);
	Result.Insert("NoExtensions", False);
	Result.Insert("WithDatabaseExtensions", False);
	Result.Insert("AbortExecutionIfError", False);
	Result.Insert("MultiThreadOperation", False);
	Result.Insert("WaitForCompletion", -1); // 
	
	Return Result;
	
EndFunction

Procedure AddExecutionParametersToReturnResult(Parameters, FormIdentifier)
	
	Parameters.Insert("FormIdentifier", FormIdentifier); 
	Parameters.Insert("ResultAddress", Undefined);
	
EndProcedure

// Multithread operations.

Function MultithreadProcessMethodName()
	Return "TimeConsumingOperations.ExecuteMultithreadedProcess";
EndFunction

Function ExecuteMultithreadedProcess(OperationParametersList) Export
	
	DeleteNonExistingThreads();
	
	ProcessID = OperationParametersList.OperationParametersList.FormIdentifier;
	
	Portions = OperationParametersList.MethodParameters;
	Results = New Map();
	
	FinishEarly = False;
	
	Threads = TreadsPendingProcessing(ProcessID);
	HasThreadsToHandle = Threads.Count() > 0;
	
	NumberofPortionsProcessed = Portions.Count() - Threads.Count();
	
	Try
		
		While HasThreadsToHandle Do
			
			For Each Stream In Threads Do
				
				ThreadKey        = Stream.ThreadKey.Get();
 				OperationParametersList = MultithreadOperationParameters(ProcessID, Stream.ExecutionParameters.Get());
				
				Result = ExecuteThread(Stream);
				
				If Result.Status = TimeConsumingOperationStatus().Error Then
					
					UpdateInfoAboutThread(Stream, Result);
					If OperationParametersList.AbortExecutionIfError Then
						FinishEarly = True;
						Break;
					EndIf; 
					
				EndIf;
				
				JobID = Result.JobID;
				SendThreadMessages(JobID);
				
				// 
				StatusWaiting = WaitForAvailableThread(ProcessID, JobID, OperationParametersList.AbortExecutionIfError);
				
				If StatusWaiting = Undefined Then
					FinishEarly = True;
					Break;
				EndIf;
				
				NumberofPortionsProcessed = NumberofPortionsProcessed + 1;
				Percent = Round(NumberofPortionsProcessed * 100 / Portions.Count());
				Percent = ?(Percent < 100, Percent, 99);
				ReportProgress(Percent, String(ThreadKey), "ProgressofMultithreadedProcess");
			
			EndDo;
			
			If FinishEarly Then
				Break;
			EndIf; 

			// 
			WaitForAllThreadsCompletion(ProcessID, OperationParametersList.AbortExecutionIfError);
			
			// @skip-
			Threads = TreadsPendingProcessing(ProcessID);
			HasThreadsToHandle = Threads.Count() > 0;
			
		EndDo;
		
	Except
		
		CancelAllThreadsExecution(ProcessID);
		
		Raise;
		
	EndTry;
	
	If FinishEarly Then
		CancelAllThreadsExecution(ProcessID);
	EndIf;
	
	ReportProgress(100, "", "ProgressofMultithreadedProcess");
	
	//  
	
	ThreadsProcess = ThreadsLongOperations(ProcessID); 
	ResultLongOperation = NewResultLongOperation();
	Results = New Map();
	
	For Each Stream In ThreadsProcess Do
		
		Var_Key = Stream.ThreadKey.Get();
		Results.Insert(Var_Key, New Structure(New FixedStructure(ResultLongOperation)));
		Results[Var_Key].ResultAddress = PutToTempStorage(Stream.Result.Get(), Stream.ResultAddress);
		
		FillPropertyValues(Results[Var_Key], Stream, 
			"Status, DetailErrorDescription, BriefErrorDescription, JobID");
		DeleteThread(Stream);
	EndDo;
	
	Return Results;
	
EndFunction

// Run the given thread.
//
// Parameters:
//  
//  Stream - InformationRegisterRecordSet.TimeConsumingOperations
//  
// 
// Returns:
//   See ExecuteInBackground
//
Function ExecuteThread(Stream)
	
	StreamParameters = MultithreadOperationParameters(Stream.ProcessID, Stream.ExecutionParameters.Get());
	
	ExecutionParameters = BackgroundExecutionParameters(StreamParameters.OperationParametersList.FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = Stream.Description;
	ExecutionParameters.WaitCompletion = 0; 
	If Common.FileInfobase() Then
		ExecutionParameters.ResultAddress = PutToTempStorage(Undefined);
	Else
		ExecutionParameters.ResultAddress = Stream.ResultAddress;
	EndIf;
		
	If TypeOf(Stream.ThreadKey) = Type("ValueStorage") Then
		ExecutionParameters.BackgroundJobKey = Stream.ThreadKey.Get();
	EndIf;
	
	If TypeOf(Stream.StreamParameters) = Type("ValueStorage") Then
		MethodParameters = Stream.StreamParameters.Get();
	Else
		MethodParameters = New Array;
	EndIf;
	
	ExecutionParameters = PrepareExecutionParameters(ExecutionParameters, StreamParameters.ForFunction);
	
	SetFullNameOfAppliedProcedure(StreamParameters.MethodName);
	RunResult = ExecuteInBackground(StreamParameters.MethodName, MethodParameters, ExecutionParameters);
	SetFullNameOfAppliedProcedure(MultithreadProcessMethodName());
	UpdateInfoAboutThread(Stream, RunResult);
	
	Return RunResult;
	
EndFunction

Function StatusFromState(State)
	
	If State = BackgroundJobState.Completed Then
		Return TimeConsumingOperationStatus().Completed2;
	ElsIf State = BackgroundJobState.Canceled Then
		Return TimeConsumingOperationStatus().Canceled;
	ElsIf State = BackgroundJobState.Active Then
		Return TimeConsumingOperationStatus().Running;
	EndIf;
	
	Return TimeConsumingOperationStatus().Error;

EndFunction

Procedure UpdateInfoAboutThread(Stream, RunResult = Undefined)
	
	If RunResult = Undefined Then
		
		RunResult = NewResultLongOperation(); 
		RunResult.ResultAddress = Stream.ResultAddress;
		RunResult.JobID = Stream.JobID;
		
		If ValueIsFilled(Stream.JobID) Then
			Job = FindJobByID(Stream.JobID);
			
			If Job <> Undefined Then
				
				RunResult.Status = StatusFromState(Job.State);
				If Job.ErrorInfo  <> Undefined Then
					RunResult.BriefErrorDescription   = ErrorProcessing.BriefErrorDescription(Job.ErrorInfo);
					RunResult.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(Job.ErrorInfo);
				EndIf;
				
			Else
				RunResult.Status = TimeConsumingOperationStatus().Error;
			EndIf;
		Else
			RunResult.Status = TimeConsumingOperationStatus().CreatedOn;
		EndIf;
	
	EndIf;
	
	ThreadID = Stream.ThreadID;
	ProcessID = Stream.ProcessID;
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.TimeConsumingOperations"); 
	LockItem.SetValue("ProcessID", ProcessID);
	LockItem.SetValue("ThreadID", ThreadID);
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		SetPrivilegedMode(True);
		
		RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
		RecordSet.Filter.ProcessID.Set(ProcessID);
		RecordSet.Filter.ThreadID.Set(ThreadID);
		
		RecordSet.Read();
		
		If RecordSet.Count() > 0 Then
			
			Record = RecordSet.Get(0);
			Record.Status = RunResult.Status;
			Record.JobID = RunResult.JobID;
			If RunResult.Status = TimeConsumingOperationStatus().Error Then
				Record.DetailErrorDescription = RunResult.DetailErrorDescription;
				Record.BriefErrorDescription = RunResult.BriefErrorDescription; 
				Record.AttemptNumber = Record.AttemptNumber + 1;
			ElsIf RunResult.Status = TimeConsumingOperationStatus().Running Then
				Record.AttemptNumber = Record.AttemptNumber + 1;
			ElsIf RunResult.Status = "Completed2" Then
				Record.Result = New ValueStorage(GetFromTempStorage(RunResult.ResultAddress));
			EndIf; 
			
			FillPropertyValues(Stream, Record);
			
			RecordSet.Write();
			
		EndIf;
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Waits until the number of active threads drops below the maximum limit.
//
// Parameters:
//  Groups - Map
//
Function WaitForAvailableThread(ProcessID, JobID, EndEarlyIfError)
	
	Threads = ActiveThreads();
	MaxThreads = AllowedNumberofThreads();
	
	If Threads.Count() >= MaxThreads Then
		WaitForFreeThread = True;
		While WaitForFreeThread Do
			
			HasCompletedThreads = HasCompletedThreads(Threads, EndEarlyIfError);
			
			If EndEarlyIfError And HasCompletedThreads = Undefined Then
				Return Undefined; // 
			EndIf;
			
			If HasCompletedThreads Then
				Return False;
			EndIf;
			
			SendThreadMessages(JobID);
			
			WaitForFreeThread = Not WaitForThreadCompletion(Threads[0]);
			If Not WaitForFreeThread Then
				UpdateInfoAboutThread(Threads[0]);
				Return False;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return False;
	
EndFunction

// 
// 
//
// Parameters:
//  JobID - UUID
//
Procedure SendThreadMessages(Val JobID)
	
	If Not ValueIsFilled(JobID) Then
		Return;
	EndIf;
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	If BackgroundJob = Undefined Then
		Return;
	EndIf;
	
	Messages = BackgroundJob.GetUserMessages(True);
	For Each Message In Messages Do
		SendClientNotification("UserMessage", Message);
	EndDo;

EndProcedure

// Waits for completion of all threads.
//
// Parameters:
//  Groups - Map
//
Procedure WaitForAllThreadsCompletion(ProcessID, EndEarlyIfError)
	
	Threads = ActiveThreads(ProcessID);
	
	CancelAllThreads = False;
	While Threads.Count() > 0 Do
		HasCompletedThreads = HasCompletedThreads(Threads, EndEarlyIfError);
		
		If HasCompletedThreads = Undefined Then
			CancelAllThreads = True;
			Break;
		EndIf;
		
		If Not HasCompletedThreads Then
			WaitForThreadCompletion(Threads[0]);
		EndIf;
		
	EndDo;
	
	If CancelAllThreads Then
		CancelAllThreadsExecution(ProcessID);
	EndIf;
	
EndProcedure

// Waits the specified duration for a thread to stop.
//
// Parameters:
//   Stream - ValueTableRow - the thread.
//   Duration - Number - timeout duration, in seconds.
//
// Returns:
//  Boolean - 
//
Function WaitForThreadCompletion(Stream, Duration = 1)
	
	If ValueIsFilled(Stream.JobID) Then
		
		SendThreadMessages(Stream.JobID);
		
		Job = BackgroundJobs.FindByUUID(Stream.JobID);
		
		If Job <> Undefined Then
			Job = Job.WaitForExecutionCompletion(Duration);
			IsJobCompleted = (Job.State <> BackgroundJobState.Active);
			Return IsJobCompleted;
		EndIf;
		
	EndIf;
	
	Return True;
	
EndFunction

Function HasCompletedThreads(Threads, EndEarlyIfError)
	
	HasCompletedThreads = False;
	
	IndexOf = Threads.Count() - 1;
	
	While IndexOf >= 0 Do
		Stream = Threads[IndexOf];
		
		JobID = Stream.JobID;
		
		If ValueIsFilled(JobID) Then
			
			Try
				
				JobCompleted = JobCompleted(JobID);
				
			Except
				
				ErrorInfo = ErrorInfo();
				WriteError(ErrorProcessing.DetailErrorDescription(ErrorInfo));
				
				JobCompleted = Undefined;
				
			EndTry;
			
			If JobCompleted = True Then
		
				UpdateInfoAboutThread(Stream);
				Threads.Delete(Stream);
				HasCompletedThreads = True;
				
			ElsIf JobCompleted = Undefined Then
				
				UpdateInfoAboutThread(Stream);
				
				If EndEarlyIfError = True Then
					Return Undefined;
				EndIf;
				
				Threads.Delete(Stream);
				HasCompletedThreads = True;
				
			EndIf;
			
		EndIf;
		
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return HasCompletedThreads;
	
EndFunction

// Terminates active threads.
// 
// Parameters:
//  
//  
// 
Procedure CancelAllThreadsExecution(FormIdentifier) Export
	
	SetPrivilegedMode(True);
	
	Threads = ThreadsLongOperations(FormIdentifier);
	
	StreamIndex = Threads.Count() - 1;
	While StreamIndex >= 0 Do
		Stream = Threads[StreamIndex];
		
		If ValueIsFilled(Stream.JobID) Then
			CancelJobExecution(Stream.JobID);
		EndIf;
		
		ThreadKey = Stream.ThreadKey.Get();
		
		If ThreadKey <> Undefined Then
		
			UpdateInfoAboutThread(Stream);
		
		EndIf;
		
		DeleteThread(Stream);
		Threads.Delete(StreamIndex);
		StreamIndex = StreamIndex -1;
		
	EndDo;
	
EndProcedure

// Remove details of running threads.
// 
Procedure DeleteNonExistingThreads()
	
	SetPrivilegedMode(True);
	
	Threads = ThreadsLongOperations();
	TimeoutDate = CurrentSessionDate() - 86400; // 
	
	StreamIndex = Threads.Count() - 1;
	While StreamIndex >= 0 Do
		
		Stream = Threads[StreamIndex];
		
		If Stream.CreationDate <= TimeoutDate Then
			
			Job = FindJobByID(Stream.JobID);
			If Job <> Undefined And Job.Status = TimeConsumingOperationStatus().Running Then
				CancelJobExecution(Stream.JobID);
			EndIf;
			DeleteThread(Stream);
			StreamIndex = StreamIndex -1;
			Continue;
			
		EndIf;
		
		If Stream.Status = TimeConsumingOperationStatus().Completed2 And Not ValueIsFilled(Stream.JobID) Then
			DeleteThread(Stream);
		ElsIf Stream.Status = TimeConsumingOperationStatus().Running And ValueIsFilled(Stream.MethodName) Then
			Job = FindJobByID(Stream.JobID);
			
			If Job = Undefined
				 Or Job.State <> BackgroundJobState.Active Then
					DeleteThread(Stream);
			EndIf;
			
		EndIf;
		
		StreamIndex = StreamIndex -1;
		
	EndDo;
	
EndProcedure

Procedure DeleteThread(Stream)

	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
	RecordSet.Filter.ProcessID.Set(Stream.ProcessID);
	RecordSet.Filter.ThreadID.Set(Stream.ThreadID);
	RecordSet.Write();
	
EndProcedure

// Returns the thread count for a multithread long-running operation.
//
// Returns:
//  Number - 
//
Function AllowedNumberofThreads()
	
	If Common.DataSeparationEnabled() 
		Or Common.FileInfobase() Then
			Return 1;
	EndIf;
	
	AllowedNumberofThreads = Constants.LongRunningOperationsThreadCount.Get();
	
	Return NumberofThreadsincludingtheControlThread(AllowedNumberofThreads);
	
EndFunction

Function NumberofThreadsincludingtheControlThread(AllowedNumberofThreads)
	
	If AllowedNumberofThreads > 1 Then
		Return AllowedNumberofThreads - 1;
	ElsIf AllowedNumberofThreads = 1 Then
		Return AllowedNumberofThreads;
	EndIf;
	
	// 
	Return 3;
	
EndFunction

// 
//
// Returns:
//    ValueTable - description of streams with the following columns:
//      * Description - String - custom thread name (used in the name of the background task).
//      * JobID - UUID - unique ID of the background task.
//      * ProcessID - UUID - 
//      * ThreadID - UUID -
//      * MethodParameters - Arbitrary -
//      * ResultAddress - String - address of the temporary storage to save the result of the background task.
//      * MethodName - String -
//      * ThreadKey - Arbitrary -
//      * ExecutionParameters - ValueStorage
//      * Result - ValueStorage
//      * AttemptNumber - Number
//      * DetailErrorDescription - String
//      * BriefErrorDescription - String
//      * StreamParameters - ValueStorage
//      * CreationDate - Date
//      * Status- String
//
Function ThreadsLongOperations(ProcessID = Undefined)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	TimeConsumingOperations.ResultAddress AS ResultAddress,
		|	TimeConsumingOperations.Description AS Description,
		|	TimeConsumingOperations.ExecutionParameters AS ExecutionParameters,
		|	TimeConsumingOperations.JobID AS JobID,
		|	TimeConsumingOperations.ProcessID AS ProcessID,
		|	TimeConsumingOperations.ThreadID AS ThreadID,
		|	TimeConsumingOperations.ThreadKey AS ThreadKey,
		|	TimeConsumingOperations.MethodName AS MethodName,
		|	TimeConsumingOperations.Result AS Result,
		|	TimeConsumingOperations.AttemptNumber AS AttemptNumber,
		|	TimeConsumingOperations.DetailErrorDescription AS DetailErrorDescription,
		|	TimeConsumingOperations.BriefErrorDescription AS BriefErrorDescription,
		|	TimeConsumingOperations.StreamParameters AS StreamParameters,
		|	TimeConsumingOperations.CreationDate AS CreationDate,
		|	TimeConsumingOperations.Status AS Status
		|FROM
		|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations";
	
	If ValueIsFilled(ProcessID) Then
		
		Query.Text = Query.Text + "
		|WHERE
		|	TimeConsumingOperations.ProcessID = &ProcessID";
		
		Query.Parameters.Insert("ProcessID", ProcessID);
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns:
//  Structure: 
//   * Status               - String - "Running" if the job is in progress.
//                                     "Completed " if the job completed successfully.
//                                     "Error" if the job failed.
//                                     "Canceled" if a user or administrator canceled the job.
//                                      Empty string if the job hasn't been started.
//   * JobID - UUID - contains 
//                                     the ID of the running background job if Status = "Running".
//                          - Undefined - 
//   * ResultAddress       - String - Address of the temporary storage to save the Map to:
//                                      ** Key - Arbitrary 
//                                      ** Value - Structure
//   * BriefErrorDescription   - String - contains brief description of the exception if Status = "Error".
//   * DetailErrorDescription - String - contains detailed description of the exception if Status = "Error".
//   * Messages - FixedArray - If Status <> "Running", then the MessageToUser array of objects
//                                      that were generated in the background job.
//
Function NewResultLongOperation()
	
	Result = New Structure;
	Result.Insert("Status",                       "");
	Result.Insert("JobID",         Undefined);
	Result.Insert("ResultAddress",              "");
	Result.Insert("BriefErrorDescription",   "");
	Result.Insert("DetailErrorDescription", "");
	Result.Insert("Messages", New FixedArray(New Array));
	
	Return Result;
	
EndFunction

Function ActiveThreads(ProcessID = Undefined)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	QueryText = "SELECT
		|	TimeConsumingOperations.ThreadID,
		|	TimeConsumingOperations.ResultAddress,
		|	TimeConsumingOperations.JobID,
		|	TimeConsumingOperations.ProcessID,
		|	TimeConsumingOperations.MethodName,
		|	TimeConsumingOperations.UserName,
		|	TimeConsumingOperations.ThreadKey,
		|	TimeConsumingOperations.Description,
		|	TimeConsumingOperations.AttemptNumber,
		|	TimeConsumingOperations.ExecutionParameters,
		|	TimeConsumingOperations.StreamParameters,
		|	TimeConsumingOperations.Status
		|FROM
		|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
		|WHERE
		|	TimeConsumingOperations.Status = &Running AND TimeConsumingOperations.MethodName <> """"";
		
	If ValueIsFilled(ProcessID) Then
		
		QueryText = QueryText + "
		|AND 	TimeConsumingOperations.ProcessID = &ProcessID"; 
		
		Query.Parameters.Insert("ProcessID", ProcessID);
		
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("Running", TimeConsumingOperationStatus().Running);
	
	Return Query.Execute().Unload()
	
EndFunction

Function TreadsPendingProcessing(ProcessID = Undefined)
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	
	QueryText = "SELECT
		|	TimeConsumingOperations.ThreadID,
		|	TimeConsumingOperations.ResultAddress,
		|	TimeConsumingOperations.JobID,
		|	TimeConsumingOperations.ProcessID,
		|	TimeConsumingOperations.MethodName,
		|	TimeConsumingOperations.UserName,
		|	TimeConsumingOperations.ThreadKey,
		|	TimeConsumingOperations.Description,
		|	TimeConsumingOperations.AttemptNumber,
		|	TimeConsumingOperations.ExecutionParameters,
		|	TimeConsumingOperations.StreamParameters,
		|	TimeConsumingOperations.Status
		|FROM
		|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
		|WHERE
		|	TimeConsumingOperations.Status = &Created OR 
		|	(TimeConsumingOperations.Status = &Error 
		|	 AND TimeConsumingOperations.AttemptNumber < &AttemptsNumber)";
			
	If ValueIsFilled(ProcessID) Then
		
		QueryText = QueryText + "
		|AND TimeConsumingOperations.ProcessID = &ProcessID";
		
		Query.Parameters.Insert("ProcessID", ProcessID);
		
	EndIf;
		
	Query.Text = QueryText;
	
	Query.SetParameter("Created",            TimeConsumingOperationStatus().CreatedOn);
	Query.SetParameter("Error",            TimeConsumingOperationStatus().Error);
	Query.SetParameter("AttemptsNumber", AttemptsNumber());
	
	Return Query.Execute().Unload();
	
	
EndFunction

Procedure PrepareMultiThreadOperationForStartup(Val MethodName, MultithreadOperationParameters, Val ProcessID, Val Portions)
	
	UserName =  "";
	If Not Users.IsFullUser() Then
		UserName = InfoBaseUsers.CurrentUser().Name;
	EndIf;
	
	DeleteNonExistingThreads();
	
	SetPrivilegedMode(True);
	
	RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
	RecordSet.Filter.ProcessID.Set(ProcessID);
	
	For Each KeyValue In Portions Do
		
		Record = RecordSet.Add();
		
		Record.ProcessID = ProcessID;
		Record.ThreadID   = New UUID;
		Record.MethodName             = MethodName;
		Record.ThreadKey            = New ValueStorage(KeyValue.Key);
		Record.ResultAddress       = MultithreadOperationParameters.AddressResults[KeyValue.Key];
		Record.Status                = TimeConsumingOperationStatus().CreatedOn;
		Record.AttemptNumber          = 0;
		Record.Description          = String(KeyValue.Key);
		Record.CreationDate          = CurrentSessionDate();
		Record.UserName       = UserName;
		Record.ExecutionParameters   = New ValueStorage(MultithreadOperationParameters);
		Record.StreamParameters       = New ValueStorage(KeyValue.Value);
		
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

// Returns:
//  Structure:
//   * CreatedOn     - String
//   * Running - String
//   * Completed2   - String
//   * Error      - String
//   * Canceled    - String
//
Function TimeConsumingOperationStatus()
	
	Result = New Structure();
	Result.Insert("CreatedOn",     "");
	Result.Insert("Running", "Running");
	Result.Insert("Completed2",   "Completed2");
	Result.Insert("Error",      "Error");
	Result.Insert("Canceled",    "Canceled");
	
	Return Result;
	
EndFunction

Function AttemptsNumber()
	Return 3;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

// 
//
Procedure StartThreadsOfLongRunningOperations() Export
	
	Common.OnStartExecuteScheduledJob(
			Metadata.ScheduledJobs.StartThreadsOfLongRunningOperations);
	
	RestartManagingThreads();
	
EndProcedure

Procedure RestartManagingThreads()
	
	Threads = ActiveManagingThreads();
	
	If Threads.Count() = 0 Then
		Return;
	EndIf;
	
	For Each Stream In Threads Do

		Job = FindJobByID(Stream.JobID);

		If Job <> Undefined Then

			If Job.State = BackgroundJobState.Active Then
				ScheduleStartOfLongRunningOperationThreads(Stream.JobID);

			ElsIf Job.State = BackgroundJobState.Failed And Stream.AttemptNumber
				<= AttemptsNumber() Then
				
				RestartManagingThread(Stream);
				
			Else
				
				DeleteDataAboutThreads(Stream.ProcessID, Stream.ThreadID);
				
			EndIf;
		Else
			
			DeleteDataAboutThreads(Stream.ProcessID);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure DeleteDataAboutThreads(ProcessID, ThreadID = Undefined)

	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.TimeConsumingOperations");
	LockItem.SetValue("ProcessID", ProcessID);
	
	If ValueIsFilled(ThreadID) Then
		LockItem.SetValue("ThreadID", ThreadID);
	EndIf;
	
	BeginTransaction();
	
	Try
	
		Block.Lock();
		
		SetPrivilegedMode(True);
		
		RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
		RecordSet.Filter.ProcessID.Set(ProcessID);
		
		If ValueIsFilled(ThreadID) Then
			RecordSet.Filter.ThreadID.Set(ThreadID);
		EndIf;
		
		RecordSet.Write();

		CommitTransaction();

	Except

		RollbackTransaction();
		Raise;

	EndTry;
	
EndProcedure

Function RestartManagingThread(Stream)
	
	RunResult = Undefined;
	
	ExecutionParameters = MultithreadOperationParameters(Stream.ProcessID, Stream.ExecutionParameters.Get());
	
	FormIdentifier = ExecutionParameters.OperationParametersList.FormIdentifier;
	
	ExecutionParametersChildThreads = BackgroundExecutionParameters(FormIdentifier);
	ExecutionParametersChildThreads.WaitCompletion = 0;
	ExecutionParametersChildThreads.ResultAddress   = PutToTempStorage(Undefined, Stream.ResultAddress);
	
	RunResult = ExecuteFunction(ExecutionParametersChildThreads, MultithreadProcessMethodName(), ExecutionParameters);
	
	If RunResult <> Undefined Then
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.TimeConsumingOperations"); 
		LockItem.SetValue("ProcessID", Stream.ProcessID);
		LockItem.SetValue("ThreadID", Stream.ThreadID);
		
		BeginTransaction();
		
		Try
			
			Block.Lock();
			
			SetPrivilegedMode(True);
			
			RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
			RecordSet.Filter.ProcessID.Set(Stream.ProcessID);
			RecordSet.Filter.ThreadID.Set(Stream.ThreadID);
			RecordSet.Read();
			
			If RecordSet.Count() > 0 Then
				Record                      = RecordSet.Get(0);
				Record.JobID = RunResult.JobID;
				Record.Status               = RunResult.Status;
				Record.AttemptNumber         = Record.AttemptNumber + 1;
				RecordSet.Write();
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			Raise;
			
		EndTry;
		
		If RunResult.Status = TimeConsumingOperationStatus().Running Then
			ScheduleStartOfLongRunningOperationThreads(RunResult.JobID);
		EndIf;
		
	EndIf;
	
	Return RunResult;

EndFunction

Procedure ScheduleStartOfLongRunningOperationThreads(JobID, RunResult = Undefined, MultithreadOperationParameters = Undefined)
	
	UserName = "";
	If Not Users.IsFullUser() Then
		UserName = InfoBaseUsers.CurrentUser().Name;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If RunResult <> Undefined Then
		
		ThreadID   = New UUID;
		ProcessID = MultithreadOperationParameters.OperationParametersList.FormIdentifier;
		
		SetPrivilegedMode(True);
		
		RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
		RecordSet.Filter.ProcessID.Set(ProcessID);
		RecordSet.Filter.ThreadID.Set(ThreadID);
		
		Record                       = RecordSet.Add();
		Record.ResultAddress       = RunResult.ResultAddress;
		Record.JobID  = RunResult.JobID;
		Record.ThreadID   = ThreadID;
		Record.Status                = RunResult.Status;
		Record.AttemptNumber          = 1;
		Record.CreationDate          = CurrentSessionDate();
		Record.UserName       = UserName;
		Record.ProcessID = ProcessID;
		Record.ExecutionParameters   = New ValueStorage(MultithreadOperationParameters);
		RecordSet.Write();
			
	EndIf;
	
	JobMetadata = Metadata.ScheduledJobs.StartThreadsOfLongRunningOperations;
	
	Filter = New Structure;
	Filter.Insert("Metadata", JobMetadata);
	
	Var_Key = "";
	If ValueIsFilled(UserName) Then
		Var_Key = InfoBaseUsers.CurrentUser().UUID;
		Filter.Insert("Key", Var_Key);
	EndIf;
	
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	
	Schedule = New JobSchedule;
	Schedule.DaysRepeatPeriod = 0;
	Schedule.BeginDate  = CurrentSessionDate();
	Schedule.BeginTime = CurrentSessionDate() + 60; // 
	
	JobParameters = New Structure;
	JobParameters.Insert("Schedule",                               Schedule);
	
	If ValueIsFilled(UserName) Then
		JobParameters.Insert("UserName", UserName);
	EndIf;
	
	If Jobs.Count() > 0 Then
		
		ScheduledJobsServer.ChangeJob(JobMetadata, JobParameters);
		
	Else
		
		JobParameters.Insert("Use",                            True);
		JobParameters.Insert("RestartIntervalOnFailure",    60);
		JobParameters.Insert("RestartCountOnFailure", 3);
		JobParameters.Insert("Key",                                     Var_Key);
		JobParameters.Insert("Metadata",                               JobMetadata);
		
		ScheduledJobsServer.AddJob(JobParameters);
		
	EndIf;
	
EndProcedure

Function ActiveManagingThreads()
	
	Block = New DataLock;
	Block.Add("InformationRegister.TimeConsumingOperations");
	
	BeginTransaction();
	
	Try
		
		Block.Lock();
		
		SetPrivilegedMode(True);
		
		Query = New Query;
		QueryText = "SELECT
		|	TimeConsumingOperations.ThreadID,
		|	TimeConsumingOperations.ResultAddress,
		|	TimeConsumingOperations.JobID,
		|	TimeConsumingOperations.ProcessID,
		|	TimeConsumingOperations.ThreadKey,
		|	TimeConsumingOperations.Description,
		|	TimeConsumingOperations.AttemptNumber,
		|	TimeConsumingOperations.ExecutionParameters
		|FROM
		|	InformationRegister.TimeConsumingOperations AS TimeConsumingOperations
		|WHERE
		|	TimeConsumingOperations.MethodName = """" AND
		|	TimeConsumingOperations.Status = &Running";
		
		Query.Text = QueryText;
		Query.SetParameter("Running", TimeConsumingOperationStatus().Running);
		
		ActiveManagingThreads = Query.Execute().Unload();
		
		If ActiveManagingThreads.Count() = 0 Then
			
			RecordSet = InformationRegisters.TimeConsumingOperations.CreateRecordSet();
			RecordSet.Write();
			
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	Return ActiveManagingThreads;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure WriteError(Val Text)
	
	EventLog.AddMessageForEventLog(EventLogEvent(), EventLogLevel.Error,,, Text);
	
EndProcedure

// Returns a string constant for generating event log messages.
//
// Returns:
//   String
//
Function EventLogEvent() Export
	
	Return NStr("en = 'Multithreaded long-running operations';", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion