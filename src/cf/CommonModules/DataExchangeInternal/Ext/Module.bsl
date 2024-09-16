///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns an error flag at startup:
// 1) Error loading message exchange:
//    - error loading IDs of the metadata objects in the information sharing
//    - error checking of IDs of the metadata objects
//    - error message download exchange before upgrading IB,
//    - error message download sharing before you upgrade to IB mode when the version has not changed;
// 2) Error updating the IB after successfully uploading the exchange message.
//
Function RetryDataExchangeMessageImportBeforeStart() Export

	SetPrivilegedMode(True);

	Return Constants.RetryDataExchangeMessageImportBeforeStart.Get();

EndFunction

// Parameters:
//  ParameterName - String
//  SpecifiedParameters - Array of String
//
Procedure SessionParametersSetting(ParameterName, SpecifiedParameters) Export
	
	// 

	If ParameterName = "DataExchangeMessageImportModeBeforeStart" Then
		SessionParameters.DataExchangeMessageImportModeBeforeStart = New FixedStructure(New Structure);
		SpecifiedParameters.Add("DataExchangeMessageImportModeBeforeStart");
		Return;
	EndIf;

	If Common.SeparatedDataUsageAvailable() Then
		
		// 
		RefreshObjectsRegistrationMechanismCache();
		
		// 
		// 
		SpecifiedParameters.Add("ObjectsRegistrationRules");
		SpecifiedParameters.Add("ORMCachedValuesRefreshDate");

		SessionParameters.DataSynchronizationPasswords = New FixedMap(New Map);
		SpecifiedParameters.Add("DataSynchronizationPasswords");

		SessionParameters.PriorityExchangeData = New FixedArray(New Array);
		SpecifiedParameters.Add("PriorityExchangeData");

		SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationSessionParameters");

		CheckStructure =New Structure;
		CheckStructure.Insert("CheckVersionDifference", False);
		CheckStructure.Insert("HasError", False);
		CheckStructure.Insert("ErrorText", "");

		SessionParameters.VersionDifferenceErrorOnGetData = New FixedStructure(CheckStructure);
		SpecifiedParameters.Add("VersionDifferenceErrorOnGetData");

	Else

		SessionParameters.DataSynchronizationPasswords = New FixedMap(New Map);
		SpecifiedParameters.Add("DataSynchronizationPasswords");

		SessionParameters.DataSynchronizationSessionParameters = New ValueStorage(New Map);
		SpecifiedParameters.Add("DataSynchronizationSessionParameters");
	EndIf;

EndProcedure

// Checks whether the object registration mechanism Cache is up-to-date.
// If the cache is outdated, the Cache is initialized with the current values.
//
// Parameters:
//  No.
// 
Procedure CheckObjectsRegistrationMechanismCache() Export

	SetPrivilegedMode(True);

	If Common.SeparatedDataUsageAvailable() Then

		RelevantDate = GetFunctionalOption("ORMCachedValuesLatestUpdate");

		If SessionParameters.ORMCachedValuesRefreshDate <> RelevantDate Then

			RefreshObjectsRegistrationMechanismCache();

		EndIf;

	EndIf;

EndProcedure

// 
//
// 
//   
//                                                    
//   
//                                                                         
//
Procedure RefreshObjectsRegistrationMechanismCache() Export
	
	SetPrivilegedMode(True);
	
	RefreshReusableValues();
	If DataExchangeCached.ExchangePlansInUse().Count() > 0 Then
		
		SessionParameters.ObjectsRegistrationRules = New ValueStorage(DataExchangeServer.GetObjectsRegistrationRules());
		
	Else
		
		SessionParameters.ObjectsRegistrationRules = New ValueStorage(DataExchangeServer.ObjectsRegistrationRulesTableInitialization());
		
	EndIf;
	
	// 
	SessionParameters.ORMCachedValuesRefreshDate = 
		GetFunctionalOption("ORMCachedValuesLatestUpdate");

EndProcedure

// 
// 
// 
//
Procedure ResetObjectsRegistrationMechanismCache() Export

	If Common.SeparatedDataUsageAvailable() Then

		SetPrivilegedMode(True);
		// 
		// 
		// 
		// 
		Constants.ORMCachedValuesRefreshDate.Set(CurrentUniversalDate());

	EndIf;

EndProcedure

// Returns a list of priority exchange data.
//
// Returns:
//  Array - 
//
Function PriorityExchangeData() Export

	SetPrivilegedMode(True);

	Result = New Array;

	For Each Item In SessionParameters.PriorityExchangeData Do

		Result.Add(Item);

	EndDo;

	Return Result;
EndFunction

// Clears the list of priority exchange data.
//
Procedure ClearPriorityExchangeData() Export

	SetPrivilegedMode(True);

	SessionParameters.PriorityExchangeData = New FixedArray(New Array);

EndProcedure

// Complements the list of priority exchange data with the passed value.
//
Procedure SupplementPriorityExchangeData(Val Data) Export

	Result = PriorityExchangeData();

	Result.Add(Data);

	SetPrivilegedMode(True);

	SessionParameters.PriorityExchangeData = New FixedArray(Result);

EndProcedure

// Returns an indication of the mode for loading program parameters from the exchange message to the information database.
// Relevant for exchange in the rib when loading data in the subordinate node of the rib.
//
Function DataExchangeMessageImportModeBeforeStart(Property) Export

	SetPrivilegedMode(True);

	Return SessionParameters.DataExchangeMessageImportModeBeforeStart.Property(Property);

EndFunction

// Returns whether the exchange plan is used in data exchange.
// If the exchange plan contains at least one node other than the predefined
// one, it is considered to be in use.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan as specified in the Configurator.
//
// Returns:
//  Boolean - 
//
Function DataExchangeEnabled(Val ExchangePlanName, Val Sender) Export

	SetPrivilegedMode(True);

	Return DataExchangeCached.DataExchangeEnabled(ExchangePlanName, Sender);
EndFunction

// Returns the value of the session option Profileregistry received in privileged mode.
//
// Returns:
//  ValueStorage - 
//
Function SessionParametersObjectsRegistrationRules() Export

	SetPrivilegedMode(True);

	Return SessionParameters.ObjectsRegistrationRules;

EndFunction

// Returns an indication that data changes were registered for the recipient.
//
// Returns:
//  Boolean - 
//
Function ChangesRegistered(Val Recipient) Export

	QueryText =
	"SELECT TOP 1 1
	|FROM
	|	&ChangeTableName AS ChangesTable
	|WHERE
	|	ChangesTable.Node = &Node";

	Query = New Query;
	Query.SetParameter("Node", Recipient);

	SetPrivilegedMode(True);

	TemplateRow = "%1.Changes";

	ExchangePlanContent = Metadata.ExchangePlans[DataExchangeCached.GetExchangePlanName(Recipient)].Content;
	For Each CompositionItem In ExchangePlanContent Do

		ChangeTableName = StrTemplate(TemplateRow, CompositionItem.Metadata.FullName());

		Query.Text = StrReplace(QueryText, "&ChangeTableName", ChangeTableName);
		QueryResult = Query.Execute();

		If Not QueryResult.IsEmpty() Then
			Return True;
		EndIf;

	EndDo;

	Return False;
EndFunction

// For internal use only.
//
// Parameters:
//   FileID - UUID -  unique ID of the data transfer session.
//   FilePartToImportNumber - Number -  part number of the file.
//   FilePartToImport - BinaryData -  data part of the file.
//   ErrorMessage - String -  description of the error when performing the operation.
//
Function ImportFilePart(FileID, FilePartToImportNumber, FilePartToImport, ErrorMessage) Export

	ErrorMessage = "";

	If Not ValueIsFilled(FileID) Then
		ErrorMessage = NStr("en = 'Cannot execute the method. The ID of the file to be imported is not specified.
								|Specify a UUID for the file to be imported.';");
		Raise (ErrorMessage);
	EndIf;

	If Not ValueIsFilled(FilePartToImport) And TypeOf(FilePartToImport) <> Type("BinaryData") Then
		ErrorMessage = NStr(
			"en = 'Cannot execute the method. The passed data type does not match the expected type.';");
		Raise (ErrorMessage);
	EndIf;

	If Not ValueIsFilled(FilePartToImportNumber) Or FilePartToImportNumber = 0 Then
		FilePartToImportNumber = 1;
	EndIf;

	TempFilesDir = TemporaryExportDirectory(FileID);

	Directory = New File(TempFilesDir);
	If Not Directory.Exists() Then
		CreateDirectory(TempFilesDir);
	EndIf;

	FileName = CommonClientServer.GetFullFileName(TempFilesDir, GetFilePartName(
		FilePartToImportNumber));
	FilePartToImport.Write(FileName);

	Return "";

EndFunction

Function ExportFilePart(FileID, FilePartToExportNumber, ErrorMessage) Export

	ErrorMessage      = "";
	FilePartName          = "";
	TempFilesDir = TemporaryExportDirectory(FileID);

	For DigitsCount = StrLen(Format(FilePartToExportNumber, "NFD=0; NG=0")) To 5 Do

		FormatString = StringFunctionsClientServer.SubstituteParametersToString("ND=%1; NLZ=; NG=0", String(
			DigitsCount));

		FileName = StringFunctionsClientServer.SubstituteParametersToString("%1.zip.%2", FileID, Format(
			FilePartToExportNumber, FormatString));

		FilesNames = FindFiles(TempFilesDir, FileName);

		If FilesNames.Count() > 0 Then

			FilePartName = CommonClientServer.GetFullFileName(TempFilesDir, FileName);
			Break;

		EndIf;

	EndDo;

	FilePart = New File(FilePartName);

	If FilePart.Exists() Then
		Return New BinaryData(FilePartName);
	Else
		ErrorMessage = NStr("en = 'The file part with the ID is not found.';");
	EndIf;

EndFunction

Function PrepareFileForImport(FileID, ErrorMessage) Export

	SetPrivilegedMode(True);

	TempStorageFileID = "";

	TempFilesDir = TemporaryExportDirectory(FileID);
	ArchiveName              = CommonClientServer.GetFullFileName(TempFilesDir, "datafile.zip");

	ReceivedFilesArray = FindFiles(TempFilesDir, "data.zip.*");

	If ReceivedFilesArray.Count() > 0 Then

		FilesToMerge = New Array;
		FilePartName = CommonClientServer.GetFullFileName(TempFilesDir, "data.zip.%1");

		For PartNumber = 1 To ReceivedFilesArray.Count() Do
			FilesToMerge.Add(StringFunctionsClientServer.SubstituteParametersToString(FilePartName,
				PartNumber));
		EndDo;

	Else
		MessageTemplate = NStr("en = 'No parts of the transfer session with the %1 ID are found.
							|Ensure that the ""Linux temporary files directory"" and
							|""Windows temporary files directory"" parameters are specified in the application settings.';");
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, String(
			FileID));
		Raise (ErrorMessage);
	EndIf;

	Try
		MergeFiles(FilesToMerge, ArchiveName);
	Except
		ErrorMessage = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Raise (ErrorMessage);
	EndTry;
	
	// 
	Dearchiver = New ZipFileReader(ArchiveName);

	If Dearchiver.Items.Count() = 0 Then

		Try
			DeleteFiles(TempFilesDir);
		Except
			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
				EventLogLevel.Error, , , ErrorMessage);
			Raise (ErrorMessage);
		EndTry;

		ErrorMessage = NStr("en = 'The archive file is empty.';");
		Raise (ErrorMessage);

	EndIf;

	ArchiveItem = Dearchiver.Items.Get(0);
	FileName = CommonClientServer.GetFullFileName(TempFilesDir, ArchiveItem.Name);

	Dearchiver.Extract(ArchiveItem, TempFilesDir);
	Dearchiver.Close();
	
	// 
	ImportDirectory          = DataExchangeServer.TempFilesStorageDirectory();
	NameOfFileWithData         = CommonClientServer.GetNameWithExtension(FileID,
		CommonClientServer.GetFileNameExtension(FileName));
	FileNameInImportDirectory = CommonClientServer.GetFullFileName(ImportDirectory, NameOfFileWithData);

	Try
		MoveFile(FileName, FileNameInImportDirectory);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
		Raise (ErrorMessage);
	EndTry;

	TempStorageFileID = DataExchangeServer.PutFileInStorage(FileNameInImportDirectory);
	
	// 
	Try
		DeleteFiles(TempFilesDir);
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		WriteLogEvent(DataExchangeServer.TempFileDeletionEventLogEvent(),
			EventLogLevel.Error, , , ErrorMessage);
		Raise (ErrorMessage);
	EndTry;

	Return TempStorageFileID;

EndFunction

Procedure PrepareDataForExportFromInfobase(ProcedureParameters, StorageAddress) Export

	WebServiceParameters = ProcedureParameters["WebServiceParameters"];
	ErrorMessage   = ProcedureParameters["ErrorMessage"];

	SetPrivilegedMode(True);

	ExchangeComponents = ExchangeComponents("Send", WebServiceParameters);
	FileName         = String(New UUID) + ".xml";

	TempFilesDir = DataExchangeServer.TempFilesStorageDirectory();
	FullFileName         = CommonClientServer.GetFullFileName(
		TempFilesDir, FileName);
		
	// 
	DataExchangeXDTOServer.OpenExportFile(ExchangeComponents, FullFileName);

	If ExchangeComponents.FlagErrors Then
		ExchangeComponents.ExchangeFile = Undefined;

		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);

		Raise ExchangeComponents.ErrorMessageString;
	EndIf;

	ExchangeSettingsStructure = ExchangeSettingsStructure(ExchangeComponents, Enums.ActionsOnExchange.DataExport);
	
	// 
	Try
		DataExchangeXDTOServer.ExecuteDataExport(ExchangeComponents);
	Except

		If ExchangeComponents.IsExchangeViaExchangePlan Then
			UnlockDataForEdit(ExchangeComponents.CorrespondentNode);
		EndIf;

		Info = ErrorInfo();
		ErrorCode = New Structure("BriefErrorDescription, DetailErrorDescription",
			ErrorProcessing.BriefErrorDescription(Info), ErrorProcessing.DetailErrorDescription(Info));

		DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorCode);
		DataExchangeXDTOServer.FinishKeepExchangeProtocol(ExchangeComponents);

		ExchangeComponents.ExchangeFile = Undefined;

		Raise ErrorCode.BriefErrorDescription;
	EndTry;

	ExchangeComponents.ExchangeFile.Close();

	WriteExchangeFinish(ExchangeSettingsStructure, ExchangeComponents);

	If ExchangeComponents.FlagErrors Then

		ErrorMessage = ExchangeComponents.ErrorMessageString;
		Raise ErrorMessage;

	Else
		
		// 
		TempStorageFileID = String(DataExchangeServer.PutFileInStorage(FullFileName));
		
		// 
		TempDirectory                     = TemporaryExportDirectory(
			TempStorageFileID);
		SharedFileName               = CommonClientServer.GetFullFileName(
			TempDirectory, TempStorageFileID + ?(WebServiceParameters.FilePartSize > 0,
			".zip", ".zip.1"));
		SourceFileNameInTemporaryDirectory = CommonClientServer.GetFullFileName(
			TempDirectory, "data.xml");

		CreateDirectory(TempDirectory);
		FileCopy(FullFileName, SourceFileNameInTemporaryDirectory);
		
		// 
		Archiver = New ZipFileWriter(SharedFileName);
		Archiver.Add(SourceFileNameInTemporaryDirectory);
		Archiver.Write();

		If WebServiceParameters.FilePartSize > 0 Then
			// 
			FilesNames = SplitFile(SharedFileName, WebServiceParameters.FilePartSize * 1024);
		Else
			FilesNames = New Array;
			FilesNames.Add(SharedFileName);
		EndIf;

		ReturnValue = "{WEBService}$%1$%2";
		ReturnValue = StringFunctionsClientServer.SubstituteParametersToString(ReturnValue,
			FilesNames.Count(), TempStorageFileID);

		Message = New UserMessage;
		Message.Text = ReturnValue;
		Message.Message();

	EndIf;

EndProcedure

Procedure ImportXDTODateToInfobase(ProcedureParameters, StorageAddress) Export

	WebServiceParameters = ProcedureParameters["WebServiceParameters"];
	ErrorMessage   = ProcedureParameters["ErrorMessage"];

	SetPrivilegedMode(True);

	Cancel = False;
	ExchangeComponents = ExchangeComponents("Receive", WebServiceParameters, Cancel);

	If ExchangeComponents.FlagErrors Then
		ErrorMessage = ExchangeComponents.ErrorMessageString;
		Raise ErrorMessage;
	EndIf;

	ExchangeSettingsStructure = ExchangeSettingsStructure(ExchangeComponents, Enums.ActionsOnExchange.DataImport);

	If Not Cancel Then
		DisableAccessKeysUpdate(True);
		Try
			DataExchangeXDTOServer.RunReadingData(ExchangeComponents);
			DisableAccessKeysUpdate(False);
		Except
			DisableAccessKeysUpdate(False);
			Information = ErrorInfo();
			ErrorMessage = NStr("en = 'Data import error: %1';");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorMessage, ErrorProcessing.DetailErrorDescription(Information));
			DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage, , , , , True);
			ExchangeComponents.FlagErrors = True;
		EndTry;

		DisableAccessKeysUpdate(True);
		Try
			DataExchangeXDTOServer.DeleteTempObjectsCreatedByRefs(ExchangeComponents);
			DisableAccessKeysUpdate(False);
		Except
			DisableAccessKeysUpdate(False);
			Information = ErrorInfo();
			ErrorMessage = NStr("en = 'Cannot delete temporary objects created by references: %1';");
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				ErrorMessage, ErrorProcessing.DetailErrorDescription(Information));
			DataExchangeXDTOServer.WriteToExecutionProtocol(ExchangeComponents, ErrorMessage, , , , , True);
			ExchangeComponents.FlagErrors = True;
		EndTry;

		ExchangeComponents.ExchangeFile.Close();
	Else
		ExchangeComponents.FlagErrors = True;
	EndIf;

	WriteExchangeFinish(ExchangeSettingsStructure, ExchangeComponents);

	If ExchangeComponents.FlagErrors Then
		Raise ExchangeComponents.ErrorMessageString;
	EndIf;

	If Not ExchangeComponents.FlagErrors And ExchangeComponents.IsExchangeViaExchangePlan
		And ExchangeComponents.UseHandshake Then
		
		// 
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add(Common.TableNameByRef(
				ExchangeComponents.CorrespondentNode));
			LockItem.SetValue("Ref", ExchangeComponents.CorrespondentNode);
			Block.Lock();

			LockDataForEdit(ExchangeComponents.CorrespondentNode);
			NodeObject = ExchangeComponents.CorrespondentNode.GetObject();

			NodeObject.ReceivedNo = ExchangeComponents.IncomingMessageNumber;
			NodeObject.AdditionalProperties.Insert("GettingExchangeMessage");

			NodeObject.Write();

			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;

	EndIf;

EndProcedure

Function TemporaryExportDirectory(Val SessionID) Export

	SetPrivilegedMode(True);

	TempDirectory = "{SessionID}";
	TempDirectory = StrReplace(TempDirectory, "SessionID", String(SessionID));

	Result = CommonClientServer.GetFullFileName(
		DataExchangeServer.TempFilesStorageDirectory(), TempDirectory);

	Return Result;

EndFunction

Procedure CheckInfobaseLockForUpdate() Export

	If ValueIsFilled(InfobaseUpdateInternal.InfobaseLockedForUpdate()) Then

		Raise NStr("en = 'Data synchronization is temporarily unavailable due to the application update.';");

	EndIf;

EndProcedure

Function GetDataReceiptExecutionStatus(TimeConsumingOperationID, ErrorMessage) Export

	ErrorMessage = "";

	SetPrivilegedMode(True);
	BackgroundJob = BackgroundJobs.FindByUUID(
		New UUID(TimeConsumingOperationID));

	BackgroundJobStates = BackgroundJobsStates();
	If BackgroundJob = Undefined Then
		CurrentBackgroundJobState = BackgroundJobStates.Get(BackgroundJobState.Canceled);
	Else

		If BackgroundJob.ErrorInfo <> Undefined Then
			ErrorMessage = ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo);
		EndIf;
		CurrentBackgroundJobState = BackgroundJobStates.Get(BackgroundJob.State);

	EndIf;

	Return CurrentBackgroundJobState;

EndFunction

Function GetExecutionStatusOfDataPreparationForSending(BackgroundJobIdentifier, ErrorMessage) Export

	ErrorMessage = "";

	SetPrivilegedMode(True);

	ReturnedStructure = XDTOFactory.Create(
		XDTOFactory.Type("http://v8.1c.ru/SSL/Exchange/EnterpriseDataExchange", "PrepareDataOperationResult"));

	BackgroundJob = BackgroundJobs.FindByUUID(
		New UUID(BackgroundJobIdentifier));

	If BackgroundJob = Undefined Then
		CurrentBackgroundJobState = BackgroundJobsStates().Get(BackgroundJobState.Canceled);
	Else

		ErrorMessage        = "";
		FilePartsCount    = 0;
		FileID       = "";
		CurrentBackgroundJobState = BackgroundJobsStates().Get(BackgroundJob.State);

		If BackgroundJob.ErrorInfo <> Undefined Then
			ErrorMessage = ErrorProcessing.DetailErrorDescription(BackgroundJob.ErrorInfo);
		Else
			If BackgroundJob.State = BackgroundJobState.Completed Then
				ArrayOfMessages  = TimeConsumingOperations.UserMessages(True, BackgroundJob.UUID);
				For Each BackgroundJobMessage In ArrayOfMessages Do
					If StrFind(BackgroundJobMessage.Text, "{WEBService}") > 0 Then
						ResultArray = StrSplit(BackgroundJobMessage.Text, "$", True);
						FilePartsCount = ResultArray[1];
						FileID    = ResultArray[2];
						Break;
					Else
						Continue;
					EndIf;
				EndDo;
			EndIf;
		EndIf;
	EndIf;

	ReturnedStructure.ErrorMessage = ErrorMessage;
	ReturnedStructure.FileID       = FileID;
	ReturnedStructure.PartCount    = FilePartsCount;
	ReturnedStructure.Status       = CurrentBackgroundJobState;

	Return ReturnedStructure;

EndFunction

Function InitializeWebServiceParameters() Export

	ParametersStructure = New Structure;
	ParametersStructure.Insert("ExchangePlanName");
	ParametersStructure.Insert("ExchangePlanNodeCode");
	ParametersStructure.Insert("TempStorageFileID");
	ParametersStructure.Insert("FilePartSize");
	ParametersStructure.Insert("NameOfTheWEBService");

	Return ParametersStructure;

EndFunction

Procedure DisableAccessKeysUpdate(Disconnect, ScheduleUpdate1 = True) Export

	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.DisableAccessKeysUpdate(Disconnect, ScheduleUpdate1);
	EndIf;

EndProcedure

Procedure PutMessageForDataMapping(ExchangeNode, MessageID) Export

	SetPrivilegedMode(True);
	
	// 
	Filter = New Structure("InfobaseNode", ExchangeNode);
	CommonSettings = InformationRegisters.CommonInfobasesNodesSettings.Get(Filter);

	If ValueIsFilled(CommonSettings.MessageForDataMapping) Then
		TempFileName = "";
		Try
			TempFileName = DataExchangeServer.GetFileFromStorage(
				CommonSettings.MessageForDataMapping);
		Except
			InformationRegisters.CommonInfobasesNodesSettings.PutMessageForDataMapping(
				ExchangeNode, "");
		EndTry;

		If Not IsBlankString(TempFileName) Then
			File = New File(TempFileName);
			If File.Exists() And File.IsFile() Then
				Try
					DeleteFiles(TempFileName);
				Except
					// 
					// 
					DataExchangeServer.PutFileInStorage(TempFileName,
						CommonSettings.MessageForDataMapping);
				EndTry;
			EndIf;
		EndIf;
	EndIf;

	InformationRegisters.CommonInfobasesNodesSettings.PutMessageForDataMapping(
		ExchangeNode, MessageID);

EndProcedure

// Retrieves the status of a long-running operation (background task) performed in the corresponding database for the information
// database node.
//
Function TimeConsumingOperationStateForInfobaseNode(Val OperationID, Val InfobaseNode,
	Val AuthenticationParameters = Undefined, ErrorMessageString = "") Export

	SetPrivilegedMode(True);

	ConnectionParameters = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(
		InfobaseNode, AuthenticationParameters);

	InterfaceVersions = DataExchangeCached.CorrespondentVersions(ConnectionParameters);

	ErrorMessage = "";
	AdditionalParameters = Undefined;
	Proxy = DataExchangeWebService.WSProxyForInfobaseNode(InfobaseNode, ErrorMessage, AdditionalParameters);

	If Proxy = Undefined Then
		Raise ErrorMessageString;
	EndIf;
	
	ProxyParameters = New Structure("CurrentVersion", AdditionalParameters.CurrentVersion);
	ExchangeParameters = New Structure("OperationID", OperationID);
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(InfobaseNode,
		"CheckLongRunningOperationStates", Enums.ExchangeMessagesTransportTypes.WS, False);
	
	Result = DataExchangeWebService.GetLongRunningOperationStatus(Proxy, ProxyParameters.CurrentVersion, ExchangeSettingsStructure, ExchangeParameters, ErrorMessageString);
	
	If Result = "Failed" Then
		MessageString = NStr("en = 'Peer infobase error: %1';");
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
			ErrorMessageString);
	EndIf;

	Return Result;

EndFunction

// Sets whether extensions need to be loaded
Procedure EnableLoadingExtensionsThatChangeTheDataStructure() Export

	SetPrivilegedMode(True);

	Constants.LoadExtensionsThatChangeDataStructure.Set(True);

EndProcedure

// Resets the indication that the extension needs to be loaded
Procedure DisableLoadingExtensionsThatChangeTheDataStructure() Export

	SetPrivilegedMode(True);

	If Constants.LoadExtensionsThatChangeDataStructure.Get() Then
		Constants.LoadExtensionsThatChangeDataStructure.Set(False);
	EndIf;

EndProcedure

// Returns an indication that extensions need to be loaded
Function LoadExtensionsThatChangeDataStructure() Export

	SetPrivilegedMode(True);

	Return Constants.LoadExtensionsThatChangeDataStructure.Get()

EndFunction

#Region SerializationMethodsExchangeExecution

// Returns a table of predefined data in the information database.
//
// Returns:
//   ValueTable - :
//     * TableName - String -  name of the information security table.
//     * XMLTypeName1 - String -  name of the serialized object type.
//     * Ref - AnyRef -  a reference to a predefined data element.
//     * PredefinedDataName - String -  name of the predefined element.
// 
Function PredefinedDataTable1() Export

	PredefinedDataTable = New ValueTable;
	PredefinedDataTable.Columns.Add("TableName");
	PredefinedDataTable.Columns.Add("XMLTypeName1");
	PredefinedDataTable.Columns.Add("Ref");
	PredefinedDataTable.Columns.Add("PredefinedDataName");

	MetadataKinds = New Array;
	MetadataKinds.Add(Metadata.Catalogs);
	MetadataKinds.Add(Metadata.ChartsOfCalculationTypes);
	MetadataKinds.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataKinds.Add(Metadata.ChartsOfAccounts);

	QueryBatch = New Array; // Array of Query
	TablesCounter = 0;
	QueryText  = "";

	For Each MetadataKind In MetadataKinds Do

		For Each CurrentMetadata In MetadataKind Do

			If TablesCounter = 256 Then
				QueryBatch.Add(New Query(QueryText));

				TablesCounter = 0;
				QueryText  = "";
			EndIf;

			TablesCounter = TablesCounter + 1;

			If TablesCounter > 1 Then
				QueryText = QueryText + "				
											  |UNION ALL";
			EndIf;

			QueryText = QueryText + StrReplace("
													  |SELECT
													  |	""#TableName"" AS TableName,
													  |	T.Ref AS Ref,
													  |	T.PredefinedDataName AS PredefinedDataName
													  |FROM
													  |	#TableName AS T
													  |WHERE
													  |	T.PredefinedDataName <> """"", "#TableName",
				CurrentMetadata.FullName());

		EndDo;

	EndDo;

	If TablesCounter > 1 Then
		QueryBatch.Add(New Query(QueryText));
	EndIf;

	For Each CurrentQuery In QueryBatch Do

		Selection = CurrentQuery.Execute().Select();
		While Selection.Next() Do
			PredefinedDataRow = PredefinedDataTable.Add();
			FillPropertyValues(PredefinedDataRow, Selection);
			PredefinedDataRow.XMLTypeName1 = XMLTypeOf(PredefinedDataRow.Ref).TypeName;
		EndDo;
		Selection = Undefined;

	EndDo;

	Return PredefinedDataTable;

EndFunction

// Parameters:
//   Data - CatalogObject,
//          - DocumentObject
//          - ChartOfAccountsObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - ConstantValueManager -
//             data object.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure MarkRefsToPredefinedData(Data, PredefinedDataTable) Export

	If Data = Undefined Or TypeOf(Data) = Type("ObjectDeletion") Then
		Return;
	Else
		ObjectMetadata = Data.Metadata();

		If Common.IsConstant(ObjectMetadata) Then

			CheckMarkPredefinedDataRef(Data.Value, PredefinedDataTable);

		ElsIf Common.IsRefTypeObject(ObjectMetadata) Then

			CollectionsArray = New Array;
			CollectionsArray.Add(ObjectMetadata.Attributes);
			CollectionsArray.Add(ObjectMetadata.StandardAttributes);

			If Common.IsTask(ObjectMetadata) Then
				CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
			EndIf;

			CheckMarkPredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
				PredefinedDataTable);

			For Each TabularSection In ObjectMetadata.TabularSections Do
				CheckMarkPredefinedDataRefInDataTable(Data[TabularSection.Name].Unload(),
					PredefinedDataTable);
			EndDo;

			If Common.IsChartOfAccounts(ObjectMetadata) Or Common.IsChartOfCalculationTypes(
				ObjectMetadata) Then
				For Each TabularSection In ObjectMetadata.StandardTabularSections Do
					TabularPartOfTheChartOfAccounts = TabularSection; // MetadataObjectChartOfAccounts
					CheckMarkPredefinedDataRefInDataTable(
						Data[TabularPartOfTheChartOfAccounts.Name].Unload(), PredefinedDataTable);
				EndDo;
			EndIf;

		ElsIf Common.IsRegister(ObjectMetadata) Then

			CheckMarkPredefinedDataRefInDataTable(Data.Unload(), PredefinedDataTable);

		EndIf;
	EndIf;

EndProcedure

// Parameters:
//   Data - CatalogObject
//          - DocumentObject
//          - ChartOfAccountsObject
//          - InformationRegisterRecordSet - 
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure ReplaceRefsToPredefinedItems(Data, PredefinedDataTable) Export

	If Data = Undefined Or TypeOf(Data) = Type("ObjectDeletion") Then
		Return;
	Else
		ObjectMetadata = Data.Metadata();

		If Common.IsConstant(ObjectMetadata) Then

			CheckReplacePredefinedDataRefInObjectAttribute(Data, "Value", PredefinedDataTable);

		ElsIf Common.IsRefTypeObject(ObjectMetadata) Then

			ProcessPredefinedItemImport(Data, PredefinedDataTable);

			CollectionsArray = New Array;
			CollectionsArray.Add(ObjectMetadata.Attributes);
			CollectionsArray.Add(ObjectMetadata.StandardAttributes);

			If Common.IsTask(ObjectMetadata) Then
				CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
			EndIf;

			CheckReplacePredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
				PredefinedDataTable);

			For Each TabularSection In ObjectMetadata.TabularSections Do
				CheckReplacePredefinedDataRefInDataTable(Data[TabularSection.Name],
					PredefinedDataTable);
			EndDo;

			If Common.IsChartOfAccounts(ObjectMetadata) Or Common.IsChartOfCalculationTypes(
				ObjectMetadata) Then
				For Each TabularSection In ObjectMetadata.StandardTabularSections Do
					TabularPartOfTheChartOfAccounts = TabularSection; // MetadataObjectChartOfAccounts
					CheckReplacePredefinedDataRefInDataTable(Data[TabularPartOfTheChartOfAccounts.Name],
						PredefinedDataTable);
				EndDo;
			EndIf;

		ElsIf Common.IsRegister(ObjectMetadata) Then

			For Each FilterElement In Data.Filter Do
				FilterStructure1 = New Structure("Value, Use");
				FillPropertyValues(FilterStructure1, FilterElement);

				If FilterStructure1.Use = False Then
					Continue;
				EndIf;

				CheckReplacePredefinedDataRefInObjectAttribute(FilterStructure1, "Value",
					PredefinedDataTable);
				FilterElement.Set(FilterStructure1.Value);
			EndDo;

			CheckReplacePredefinedDataRefInDataTable(Data, PredefinedDataTable);

		EndIf;
	EndIf;

EndProcedure

#EndRegion

Function ExchangePlanContent(ExchangePlanName, Periodic2 = True, Regulatory = True) Export

	Return DataExchangeCached.ExchangePlanContent(ExchangePlanName, Periodic2, Regulatory);

EndFunction

// Adds information about the number of elements in a transaction set in a constant
// to the structure containing parameters for the transport of exchange messages.
//
// Parameters:
//  Result - Structure -  contains parameters for the transport of exchange messages.
// 
Procedure AddTransactionItemsCountToTransportSettings(Result) Export

	Result.Insert("DataExportTransactionItemsCount",
		DataExchangeServer.DataExportTransactionItemsCount());
	Result.Insert("DataImportTransactionItemCount",
		DataExchangeServer.DataImportTransactionItemCount());

EndProcedure

// Returns the area number based on the node code of the exchange plan (messaging).
// 
// Parameters:
//  NodeCode - String -  code of the exchange plan node.
// 
// Returns:
//  Number - 
//
Function DataAreaNumberFromExchangePlanNodeCode(Val NodeCode) Export

	If TypeOf(NodeCode) <> Type("String") Then
		Raise NStr("en = 'Invalid type in parameter number [1].';");
	EndIf;

	Result = StrReplace(NodeCode, "S0", "");

	Return Number(Result);
EndFunction

// Returns data from the first record of the query result as a structure.
// 
// Parameters:
//  QueryResult - QueryResult -  the result of the request containing the data to be processed.
// 
// Returns:
//  Structure - 
//
Function QueryResultToStructure(Val QueryResult) Export

	Result = New Structure;
	For Each Column In QueryResult.Columns Do
		Result.Insert(Column.Name);
	EndDo;

	If QueryResult.IsEmpty() Then
		Return Result;
	EndIf;

	Selection = QueryResult.Select();
	Selection.Next();

	FillPropertyValues(Result, Selection);

	Return Result;
EndFunction

// Parameters:
//   Filter - Filter -  random selection.
//   ItemKey - String -  name of the selection element.
//   ElementValue - Arbitrary -  value of the selection element.
// 
Procedure SetFilterItemValue(Filter, ItemKey, ElementValue) Export

	FilterElement = Filter.Find(ItemKey);
	If FilterElement <> Undefined Then
		FilterElement.Set(ElementValue);
	EndIf;

EndProcedure

#Region OperationsWithInformationRegisters

// Adds one entry to the information register for the passed structure values.
//
// Parameters:
//  RecordStructure - Structure -  the structure to use for creating a set of records and populating this
//                                set.
//  RegisterName     - String -  name of the information register to add the entry to.
// 
Procedure AddRecordToInformationRegister(RecordStructure, Val RegisterName, Load = False) Export

	RecordSet = CreateInformationRegisterRecordSet(RecordStructure, RegisterName);
	
	// 
	NewRecord = RecordSet.Add();
	
	// 
	FillPropertyValues(NewRecord, RecordStructure);

	RecordSet.DataExchange.Load = Load;
	
	// 
	RecordSet.Write();

EndProcedure

// Updates a record in the information register for the given values of the structure.
//
// Parameters:
//  RecordStructure - Structure -  structure, the values of which you want to create Manager record and update the record.
//  RegisterName     - String -  the name of the register information in which you want to update the record.
// 
Procedure UpdateInformationRegisterRecord(RecordStructure, Val RegisterName) Export

	RegisterMetadata = Metadata.InformationRegisters[RegisterName]; // MetadataObjectInformationRegister
	
	// 
	RecordManager = InformationRegisters[RegisterName].CreateRecordManager();
	
	// 
	For Each Dimension In RegisterMetadata.Dimensions Do

		DimensionName = Dimension.Name;
		
		// 
		If RecordStructure.Property(DimensionName) Then

			RecordManager[DimensionName] = RecordStructure[DimensionName];

		EndIf;

	EndDo;
	
	// 
	RecordManager.Read();
	
	// 
	FillPropertyValues(RecordManager, RecordStructure);
	
	// 
	RecordManager.Write();

EndProcedure

// Deletes a set of entries in the register based on the passed structure values.
//
// Parameters:
//  RecordStructure - Structure -  structure to delete a set of records based on its values.
//  RegisterName     - String -  the name of the register information in which you want to delete a set of records.
// 
Procedure DeleteRecordSetFromInformationRegister(RecordStructure, RegisterName, Load = False) Export

	RecordSet = CreateInformationRegisterRecordSet(RecordStructure, RegisterName);

	RecordSet.DataExchange.Load = Load;
	
	// 
	RecordSet.Write();

EndProcedure

// Creates a set of information register entries for the passed structure values. Adds one entry to the set.
//
// Parameters:
//  RecordStructure - Structure -  a structure whose values should be used to create a set of records and populate this
//                                set.
//  RegisterName     - String -  name of the information register.
//  
// Returns:
//   InformationRegisterRecordSet - 
// 
Function CreateInformationRegisterRecordSet(RecordStructure, RegisterName) Export

	RecordSet = InformationRegisters[RegisterName].CreateRecordSet(); // InformationRegisterRecordSet
	
	// 
	For Each KeyValue In RecordStructure Do
		SetFilterItemValue(RecordSet.Filter, KeyValue.Key, KeyValue.Value);
	EndDo;

	Return RecordSet;

EndFunction

#EndRegion

#EndRegion

#Region Private

Function ExchangeComponents(ExchangeDirection, WebServiceParameters, Cancel = False)

	ExchangeComponents = DataExchangeXDTOServer.InitializeExchangeComponents(ExchangeDirection);

	If ValueIsFilled(WebServiceParameters.ExchangePlanName) And ValueIsFilled(
		WebServiceParameters.ExchangePlanNodeCode) Then
		ExchangeComponents.CorrespondentNode = ExchangePlans[WebServiceParameters.ExchangePlanName].FindByCode(
			WebServiceParameters.ExchangePlanNodeCode);
	Else
		ExchangeComponents.IsExchangeViaExchangePlan = False;
	EndIf;

	ExchangeComponents.KeepDataProtocol.OutputInfoMessagesToProtocol = False;
	ExchangeComponents.DataExchangeState.StartDate = CurrentSessionDate();
	ExchangeComponents.UseTransactions = False;

	If ExchangeDirection = "Receive" Then

		ExchangeComponents.EventLogMessageKey = GenerateEventLogMessageKey(ExchangeDirection,
			WebServiceParameters);

		FileName = DataExchangeServer.GetFileFromStorage(
			WebServiceParameters.TempStorageFileID);
		DataExchangeXDTOServer.OpenImportFile(ExchangeComponents, FileName);
		DataExchangeXDTOServer.AfterOpenImportFile(ExchangeComponents, Cancel);

		If Cancel Then
			Return ExchangeComponents;
		EndIf;

	Else

		ExchangeComponents.EventLogMessageKey   = GenerateEventLogMessageKey(ExchangeDirection,
			WebServiceParameters);
		ExchangeComponents.ExchangeFormatVersion               = DataExchangeXDTOServer.ExchangeFormatVersionOnImport(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.XMLSchema                          = DataExchangeXDTOServer.ExchangeFormat(
			WebServiceParameters.ExchangePlanName, ExchangeComponents.ExchangeFormatVersion);
		ExchangeComponents.ExchangeManager                    = DataExchangeXDTOServer.FormatVersionExchangeManager(
			ExchangeComponents.ExchangeFormatVersion, ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ObjectsRegistrationRulesTable = DataExchangeXDTOServer.ObjectsRegistrationRules(
			ExchangeComponents.CorrespondentNode);
		ExchangeComponents.ExchangePlanNodeProperties           = DataExchangeXDTOServer.ExchangePlanNodeProperties(
			ExchangeComponents.CorrespondentNode);

	EndIf;

	If ExchangeComponents.FlagErrors Then
		Return ExchangeComponents;
	EndIf;

	DataExchangeXDTOServer.InitializeExchangeRulesTables(ExchangeComponents);

	If ExchangeComponents.IsExchangeViaExchangePlan Then
		DataExchangeXDTOServer.FillXDTOSettingsStructure(ExchangeComponents);
		DataExchangeXDTOServer.FillSupportedXDTOObjects(ExchangeComponents);
	EndIf;

	DataExchangeXDTOServer.AfterInitializationOfTheExchangeComponents(ExchangeComponents);

	Return ExchangeComponents;

EndFunction

Function GetFilePartName(FilePartNumber, ArchiveName = "")

	If Not ValueIsFilled(ArchiveName) Then
		ArchiveName = "data";
	EndIf;

	Result = StringFunctionsClientServer.SubstituteParametersToString("%1.zip.%2", ArchiveName, Format(FilePartNumber,
		"NG=0"));

	Return Result;

EndFunction

Function BackgroundJobsStates()

	BackgroundJobStates = New Map;
	BackgroundJobStates.Insert(BackgroundJobState.Active, "Active");
	BackgroundJobStates.Insert(BackgroundJobState.Completed, "Completed");
	BackgroundJobStates.Insert(BackgroundJobState.Failed, "Failed");
	BackgroundJobStates.Insert(BackgroundJobState.Canceled, "Canceled");

	Return BackgroundJobStates;

EndFunction

Function GenerateEventLogMessageKey(ExchangeDirection, WebServiceParameters)

	If ExchangeDirection = "Receive" Then
		MessageKeyTemplate = NStr("en = 'Import data over web service %1';", Common.DefaultLanguageCode());
	Else
		MessageKeyTemplate = NStr("en = 'Export data over web service %1';", Common.DefaultLanguageCode());
	EndIf;

	Return StringFunctionsClientServer.SubstituteParametersToString(MessageKeyTemplate,
		WebServiceParameters.NameOfTheWEBService);

EndFunction

Function ExchangeSettingsStructure(ExchangeComponents, DataExchangeAction)

	If Not ExchangeComponents.IsExchangeViaExchangePlan Then
		Return Undefined;
	EndIf;

	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		ExchangeComponents.CorrespondentNode, DataExchangeAction, Undefined, False);

	If ExchangeSettingsStructure.Cancel Then
		ErrorMessageString = NStr("en = 'Cannot initialize data exchange.';");
		DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);
		Raise ErrorMessageString;
	EndIf;

	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	ExchangeSettingsStructure.StartDate = CurrentSessionDate();

	MessageString = NStr("en = 'Data exchange started. Node: %1';", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
		ExchangeSettingsStructure.InfobaseNodeDescription);

	WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey,
		EventLogLevel.Information, ExchangeSettingsStructure.InfobaseNode.Metadata(),
		ExchangeSettingsStructure.InfobaseNode, MessageString);

	Return ExchangeSettingsStructure;

EndFunction

Procedure WriteExchangeFinish(ExchangeSettingsStructure, ExchangeComponents)

	If Not ExchangeComponents.IsExchangeViaExchangePlan Then
		Return;
	EndIf;

	ExchangeSettingsStructure.ExchangeExecutionResult    = ExchangeComponents.DataExchangeState.ExchangeExecutionResult;

	If ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport Then
		ExchangeSettingsStructure.ProcessedObjectsCount = ExchangeComponents.ExportedObjectCounter;
		ExchangeSettingsStructure.MessageOnExchange           = ExchangeSettingsStructure.DataExchangeDataProcessor.CommentOnDataExport;
	ElsIf ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport Then
		ExchangeSettingsStructure.ProcessedObjectsCount = ExchangeComponents.ImportedObjectCounter;
		ExchangeSettingsStructure.MessageOnExchange           = ExchangeSettingsStructure.DataExchangeDataProcessor.CommentOnDataImport;
	EndIf;

	ExchangeSettingsStructure.ErrorMessageString      = ExchangeComponents.ErrorMessageString;

	DataExchangeServer.WriteExchangeFinish(ExchangeSettingsStructure);

EndProcedure

#Region SerializationMethodsExchangeExecution

Procedure CheckMarkPredefinedDataRef(Value, PredefinedDataTable)

	If Not Common.IsReference(TypeOf(Value)) Then
		Return;
	EndIf;

	PredefinedDataRow = PredefinedDataTable.Find(Value, "Ref");
	If PredefinedDataRow = Undefined Then
		// 
		Return;
	EndIf;

	If Not PredefinedDataRow.Export Then
		PredefinedDataRow.Export = True;
	EndIf;

EndProcedure

// Parameters:
//   Data - Arbitrary -  data object.
//   CollectionsArray - Array of MetadataObjectCollection -  a set of props collections.
//   PredefinedDataTable - ValueTable -  table of predefined elements.
// 
Procedure CheckMarkPredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
	PredefinedDataTable)

	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			CheckMarkPredefinedDataRef(Data[Attribute.Name], PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   TableData - ValueTable -  table with object data.
//   PredefinedDataTable - ValueTable -  table of predefined elements.
// 
Procedure CheckMarkPredefinedDataRefInDataTable(TableData, PredefinedDataTable)

	For Each TableRow In TableData Do
		For Each Column In TableData.Columns Do
			CheckMarkPredefinedDataRef(TableRow[Column.Name], PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   Data - CatalogObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfAccountsObject
//          - ChartOfCalculationTypesObject
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure ProcessPredefinedItemImport(Data, PredefinedDataTable)

	OriginalDataRef = Data.Ref;
	If Data.IsNew() Then
		OriginalDataRef = Data.GetNewObjectRef();
	EndIf;

	RowPredefinedData = PredefinedDataTable.Find(OriginalDataRef, "SourceRef1");
	If RowPredefinedData = Undefined Then
		Return;
	EndIf;

	DataForImport = RowPredefinedData.Ref.GetObject();
	ObjectMetadata = DataForImport.Metadata();

	CollectionsArray = New Array;
	CollectionsArray.Add(ObjectMetadata.Attributes);
	CollectionsArray.Add(ObjectMetadata.StandardAttributes);

	If Common.IsTask(ObjectMetadata) Then
		CollectionsArray.Add(ObjectMetadata.AddressingAttributes);
	EndIf;

	TransferAttributesCollectionValuesBetweenObjects(Data, DataForImport, CollectionsArray);

	For Each TabularSection In ObjectMetadata.TabularSections Do
		If Data[TabularSection.Name].Count() > 0 Or DataForImport[TabularSection.Name].Count() > 0 Then
			DataForImport[TabularSection.Name].Load(Data[TabularSection.Name].Unload());
		EndIf;
	EndDo;

	If Common.IsChartOfAccounts(ObjectMetadata) Or Common.IsChartOfCalculationTypes(ObjectMetadata) Then
		For Each TabularSection In ObjectMetadata.StandardTabularSections Do
			If Data[TabularSection.Name].Count() > 0 Or DataForImport[TabularSection.Name].Count() > 0 Then
				DataForImport[TabularSection.Name].Load(Data[TabularSection.Name].Unload());
			EndIf;
		EndDo;
	EndIf;

	Data = DataForImport;

EndProcedure

// Parameters:
//   Source - Arbitrary -  data source object.
//   Receiver - Arbitrary -  object-the receiver of the data.
//   CollectionsArray - Array of MetadataObjectCollection -  a set of props collections.
//
Procedure TransferAttributesCollectionValuesBetweenObjects(Source, Receiver, CollectionsArray)

	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			AttributeName = Attribute.Name;
			If Receiver[AttributeName] = Receiver.Ref Then
				Continue;
			EndIf;
			If Receiver[AttributeName] = Source[AttributeName] Then
				Continue;
			EndIf;
			Receiver[AttributeName] = Source[AttributeName];
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   Data - Arbitrary -  data object.
//   AttributeName - String -  name of the item's details.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
// 
Procedure CheckReplacePredefinedDataRefInObjectAttribute(Data, AttributeName, PredefinedDataTable)

	If AttributeName = "Ref" Then
		Return;
	EndIf;
	
	Value = Data[AttributeName];

	If Not Common.IsReference(TypeOf(Value)) Then
		Return;
	EndIf;

	RowPredefinedData = PredefinedDataTable.Find(Value, "SourceRef1");
	If Not RowPredefinedData = Undefined Then
		Data[AttributeName] = RowPredefinedData.Ref;
	EndIf;

EndProcedure

// Parameters:
//   Data - Arbitrary -  data object.
//   CollectionsArray - Array of MetadataObjectCollection -  a set of props collections.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
//
Procedure CheckReplacePredefinedDataRefInObjectAttributesCollection(Data, CollectionsArray,
	PredefinedDataTable)

	For Each AttributesCollection In CollectionsArray Do
		For Each Attribute In AttributesCollection Do
			CheckReplacePredefinedDataRefInObjectAttribute(Data, Attribute.Name, PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

// Parameters:
//   TableData - TabularSection -  table part of an object or a set of register entries.
//   PredefinedDataTable - See DataExchangeInternal.PredefinedDataTable1
//
Procedure CheckReplacePredefinedDataRefInDataTable(TableData, PredefinedDataTable)

	If TableData.Count() = 0 Then
		Return;
	EndIf;

	TableTS = TableData.Unload();

	For Each DataTSRow In TableData Do
		For Each Column In TableTS.Columns Do
			If Not CommonClientServer.HasAttributeOrObjectProperty(DataTSRow, Column.Name) Then
				Continue;
			EndIf;
			CheckReplacePredefinedDataRefInObjectAttribute(DataTSRow, Column.Name,
				PredefinedDataTable);
		EndDo;
	EndDo;

EndProcedure

#Region ObsoleteProceduresAndFunctions

// Deprecated.
//
Procedure CheckCanSynchronizeData() Export

	If Not AccessRight("View", Metadata.CommonCommands.Synchronize) Then

		Raise NStr("en = 'Insufficient rights to synchronize data.';");

	ElsIf InfobaseUpdate.InfobaseUpdateRequired()
		And Not DataExchangeMessageImportModeBeforeStart("ImportPermitted") Then

		Raise NStr("en = 'Infobase is updating.';");

	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndRegion