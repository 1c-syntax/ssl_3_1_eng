///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private
////////////////////////////////////////////////////////////////////////////////
// 

Function Ping()
	Return "";
EndFunction

Function ConnectionCheckUp(ErrorMessage)
	
	ErrorMessage = "";
	
	// 
	Try
		DataExchangeInternal.CheckCanSynchronizeData();
	Except
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	// 
	Try
		DataExchangeInternal.CheckInfobaseLockForUpdate();
	Except
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function GetDataImportResult(BackgroundJobIdentifier, ErrorMessage)
	
	Return DataExchangeInternal.GetDataReceiptExecutionStatus(BackgroundJobIdentifier, ErrorMessage);
	
EndFunction

// PutFilePart
//
Function ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage)
	
	Return DataExchangeInternal.ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage);
	
EndFunction

// PutData
//
Function ImportDataToInfobase(FileID, BackgroundJobIdentifier, ErrorMessage)
	
	ErrorMessage = "";
	
	ParametersStructure = DataExchangeInternal.InitializeWebServiceParameters();
	ParametersStructure.TempStorageFileID = DataExchangeInternal.PrepareFileForImport(FileID, ErrorMessage);
	ParametersStructure.NameOfTheWEBService                          = "EnterpriseDataUpload_1_0_1_1";
	
	// 
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("WebServiceParameters", ParametersStructure);
	ProcedureParameters.Insert("ErrorMessage",   ErrorMessage);

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(New UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("en = 'Import data to the infobase using the ""Enterprise Data Upload"" web service';");
	ExecutionParameters.BackgroundJobKey = String(New UUID);
	
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground    = True;

	BackgroundJob = TimeConsumingOperations.ExecuteInBackground(
		"DataExchangeInternal.ImportXDTODateToInfobase",
		ProcedureParameters,
		ExecutionParameters);
	BackgroundJobIdentifier = String(BackgroundJob.JobID);
	
	Return "";
	
EndFunction

#EndRegion