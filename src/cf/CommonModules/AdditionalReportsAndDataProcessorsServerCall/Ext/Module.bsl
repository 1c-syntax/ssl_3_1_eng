///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Enables external processing (report).
// More detailed  See AdditionalReportsAndDataProcessors.AttachExternalDataProcessor.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors -  plug-in processing.
//
// Returns: 
//   String       - 
//   
//
Function AttachExternalDataProcessor(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.AttachExternalDataProcessor(Ref);
	
EndFunction

// Creates and returns an instance of external processing (report).
// More detailed  See AdditionalReportsAndDataProcessors.ExternalDataProcessorObject.
//
// Parameters:
//   Ref - CatalogRef.AdditionalReportsAndDataProcessors -  plug-in report or processing.
//
// Returns:
//   ExternalDataProcessor 
//   External Report     
//   Undefined     - if an invalid link is passed.
//
Function ExternalDataProcessorObject(Ref) Export
	
	Return AdditionalReportsAndDataProcessors.ExternalDataProcessorObject(Ref);
	
EndFunction

#EndRegion

#Region Private

// Executes the processing command and puts the result in temporary storage.
//   More detailed -  See AdditionalReportsAndDataProcessors.ExecuteCommand.
//
Function ExecuteCommand(CommandParameters, ResultAddress = Undefined) Export
	
	Return AdditionalReportsAndDataProcessors.ExecuteCommand(CommandParameters, ResultAddress);
	
EndFunction

// Places binary data from an additional report or processing in temporary storage.
Function PutInStorage(Ref, FormIdentifier) Export
	If TypeOf(Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") 
		Or Ref = Catalogs.AdditionalReportsAndDataProcessors.EmptyRef() Then
		Return Undefined;
	EndIf;
	If Not AdditionalReportsAndDataProcessors.CanExportDataProcessorToFile(Ref) Then
		Raise(NStr("en = 'Insufficient rights to export additional report or data processor files.';"),
			ErrorCategory.AccessViolation);
	EndIf;
	
	DataProcessorStorage = Common.ObjectAttributeValue(Ref, "DataProcessorStorage");
	
	Return PutToTempStorage(DataProcessorStorage.Get(), FormIdentifier);
EndFunction

// Starts a long-running operation.
Function StartTimeConsumingOperation(Val UUID, Val CommandParameters) Export
	MethodName = "AdditionalReportsAndDataProcessors.ExecuteCommand";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.WaitCompletion = 0;
	StartSettings1.BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Running %1 additional report or data processor, command name: %2.';"),
		String(CommandParameters.AdditionalDataProcessorRef),
		CommandParameters.CommandID);
	
	Return TimeConsumingOperations.ExecuteInBackground(MethodName, CommandParameters, StartSettings1);
EndFunction

#EndRegion
