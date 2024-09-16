///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Gets the value of the exchange plan setting by its name.
// For a non-existent settings returns Undefined.
// 
// Parameters:
//   ExchangePlanName         - String -  name of the exchange plan from the metadata.
//   ParameterName           - String -  the name of the exchange plan parameter or a comma-separated list of parameters.
//                                     For a list of acceptable values, see the functions of the Exchange Plan settings,
//                                     Descriptionvariantanastroykiobjection of silence.
//   SettingID - String -  name of the predefined exchange plan setting.
//   CorrespondentVersion   - String -  version of the correspondent configuration.
// 
// Returns:
//   Arbitrary, Structure - 
//                             
//                             
//
Function ExchangePlanSettingValue(ExchangePlanName, ParameterName, SettingID = "", CorrespondentVersion = "") Export
	
	ParameterValue = New Structure;
	ExchangePlanSettings = Undefined;
	SettingOptionDetails = Undefined;
	ParameterName = StrReplace(ParameterName, Chars.LF, "");
	ParameterNames = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ParameterName,,True);
	DefaultExchangePlanSettings = DefaultExchangePlanSettings(ExchangePlanName);
	DefaultOptionDetails = DefaultExchangeSettingOptionDetails(ExchangePlanName);
	If ParameterNames.Count() = 0 Then
		Return Undefined;
	EndIf;
	For Each SingleParameter In ParameterNames Do
		SingleParameterValue = Undefined;
		If DefaultExchangePlanSettings.Property(SingleParameter) Then
			If ExchangePlanSettings = Undefined Then
				ExchangePlanSettings = DataExchangeCached.ExchangePlanSettings(ExchangePlanName);
			EndIf;
			ExchangePlanSettings.Property(SingleParameter, SingleParameterValue);
		ElsIf DefaultOptionDetails.Property(SingleParameter) Then
			If SettingOptionDetails = Undefined Then
				SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName, SettingID, CorrespondentVersion);
			EndIf;
			SettingOptionDetails.Property(SingleParameter, SingleParameterValue);
		EndIf;
		If ParameterNames.Count() = 1 Then
			Return SingleParameterValue;
		Else
			ParameterValue.Insert(SingleParameter, SingleParameterValue);
		EndIf;
	EndDo;
	Return ParameterValue;
	
EndFunction

// Procedure-handler for the "join Server" event for the exchange plan node form.
//
// Parameters:
//  Form - ClientApplicationForm - :
//    * Object - FormDataStructure:
//      ** Ref - ExchangePlanRef -  the site plan of exchange.
//  Cancel - Boolean           -  indicates that the form was not created. If set to True, the form will not be created.
// 
Procedure NodeFormOnCreateAtServer(Form, Cancel) Export
	
	ExchangePlanPresentation1 = ExchangePlanSettingValue(
		Form.Object.Ref.Metadata().Name,
		"ExchangePlanNodeTitle",
		DataExchangeOption(Form.Object.Ref));
	
	Form.AutoTitle = False;
	Form.Title = StringFunctionsClientServer.SubstituteParametersToString(Form.Object.Description + " (%1)",
		ExchangePlanPresentation1);
		
	If Common.DataSeparationEnabled() 
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleDataExchangeInternalPublication = Common.CommonModule("DataExchangeInternalPublication");
		ModuleDataExchangeInternalPublication.NodeFormOnCreateAtServer(Form, Cancel);
		
	EndIf;
	
	SetUpLoopFormElements(Form);
	
EndProcedure

// Procedure-handler of the event "Recordserver" for the exchange plan node form.
//
// Parameters:
//  CurrentObject - ExchangePlanObject -  the recorded site plan of exchange.
//  Cancel         - Boolean           -  incoming, indicates that the exchange node refused to write.
//                                     If set to True, the node will not be
//                                     registered for completing the synchronization configuration.
//
Procedure NodeFormOnWriteAtServer(CurrentObject, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	If Not SynchronizationSetupCompleted(CurrentObject.Ref) Then
		CompleteDataSynchronizationSetup(CurrentObject.Ref);
	EndIf;
	
EndProcedure

// Procedure-handler for the "join Server" event for the node configuration form.
//
// Parameters:
//  Form          - ClientApplicationForm -  the form from which the procedure is called.
//  ExchangePlanName - String           -  name of the exchange plan that the form was created for.
// 
Procedure NodeSettingsFormOnCreateAtServer(Form, ExchangePlanName) Export
	
	SettingID = "";
	
	If Form.Parameters.Property("SettingID") Then
		SettingID = Form.Parameters.SettingID;
	EndIf;
	
	CheckMandatoryFormAttributes(Form, "NodeFiltersSetting, CorrespondentVersion");
	
	Form.CorrespondentVersion   = Form.Parameters.CorrespondentVersion;
	Form.NodeFiltersSetting = NodeFiltersSetting(ExchangePlanName, Form.CorrespondentVersion, SettingID);
	
	NodeSettingsFormOnCreateAtServerHandler(Form, "NodeFiltersSetting");
	
EndProcedure

// Determines whether the handler for the "post-data Upload" event must be executed when exchanging data to the rib.
//
// Parameters:
//  Object - ExchangePlanObject -  the exchange plan node that the handler is running for.
//  Ref - ExchangePlanRef -  link to the exchange plan node that the handler is running for.
//
// Returns:
//   Boolean - 
//
Function MustExecuteHandlerAfterDataExport(Object, Ref) Export
	
	Return MustExecuteHandler(Object, Ref, "SentNo");
	
EndFunction

// Determines whether the "post-load Data" event handler must be executed when exchanging data to the rib.
//
// Parameters:
//  Object - ExchangePlanObject -  the exchange plan node that the handler is running for.
//  Ref - ExchangePlanRef -  link to the exchange plan node that the handler is running for.
//
// Returns:
//   Boolean - 
//
Function MustExecuteHandlerAfterDataImport(Object, Ref) Export
	
	Return MustExecuteHandler(Object, Ref, "ReceivedNo");
	
EndFunction

// Returns the prefix of this information base.
//
// Returns:
//   String - 
//
Function InfobasePrefix() Export
	
	Return GetFunctionalOption("InfobasePrefix");
	
EndFunction

// Returns the version of the correspondent configuration.
// If the correspondent configuration version is not defined, it returns an empty version - "0.0.0.0".
//
// Parameters:
//  Peer - ExchangePlanRef -  the site plan of exchange, for which to get the configuration version.
// 
// Returns:
//  String -  version of the correspondent configuration.
//
// Example:
//  If The General Purpose Is The Clientserver.Compare Versions(Recommended By The Server.Version Of The Correspondent (Correspondent), "2.1.5.1")
//  > = 0 Then ...
//
Function CorrespondentVersion(Val Peer) Export
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.CommonInfobasesNodesSettings.CorrespondentVersion(Peer);
EndFunction

// Sets the prefix of this information base.
//
// Parameters:
//   Prefix - String -  new value of the information database prefix.
//
Procedure SetInfobasePrefix(Val Prefix) Export
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsPrefixes")
		And Not OpenDataExchangeCreationWizardForSubordinateNodeSetup() Then
		
		ModuleObjectsPrefixesInternal = Common.CommonModule("ObjectsPrefixesInternal");
		
		PrefixChangeParameters = New Structure("NewIBPrefix, ContinueNumbering",
			TrimAll(Prefix), True);
		ModuleObjectsPrefixesInternal.ChangeIBPrefix(PrefixChangeParameters);
		
	Else
		//  
		// 
		// 
		Constants.DistributedInfobaseNodePrefix.Set(TrimAll(Prefix));
	EndIf;
	
	DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	
EndProcedure

// Checks whether this database is restored from a backup.
// If the database was restored from backup, you must synchronize the numbers sent and
// received messages for two bases (the number of sent messages in the database is given a number value
// received message from the base-correspondent).
// If the database was restored from a backup, we recommend that you do not de-register data changes on
// the current node, because this data may not have been sent yet.
//
// Parameters:
//   Sender    - ExchangePlanRef -  the node on whose behalf the exchange message was generated and sent.
//   ReceivedNo - Number            -  number of the received message in the corresponding database.
//
// Returns:
//   FixedStructure:
//     * Sender                 - ExchangePlanRef - see the Sender parameter above.
//     * ReceivedNo              - Number            - see the Accepted number parameter above.
//     * BackupRestored - Boolean -  True if it is detected that this database was restored from a backup.
//
Function BackupParameters(Val Sender, Val ReceivedNo) Export
	
	// 
	// 
	// 
	// 
	Result = New Structure("Sender, ReceivedNo, BackupRestored");
	Result.Sender = Sender;
	Result.ReceivedNo = ReceivedNo;
	Result.BackupRestored = (ReceivedNo > Common.ObjectAttributeValue(Sender, "SentNo"));
	
	Return New FixedStructure(Result);
EndFunction

// Synchronizes the numbers of sent and received messages
// for two databases (the number of the sent message in this database is assigned the value of the number of the received message from
// the corresponding database).
//
// Parameters:
//   BackupParameters - FixedStructure:
//     * Sender                 - ExchangePlanRef -  the node on whose behalf
//                                                        the exchange message was generated and sent.
//     * ReceivedNo              - Number            -  number of the received message in the corresponding database.
//     * BackupRestored - Boolean           -  indicates whether to restore this database from a backup.
//
Procedure OnRestoreFromBackup(Val BackupParameters) Export
	
	If BackupParameters.BackupRestored Then
		
		BeginTransaction();
		Try
			Block = New DataLock;
			LockItem = Block.Add(Common.TableNameByRef(BackupParameters.Sender));
			LockItem.SetValue("Ref", BackupParameters.Sender);
			Block.Lock();
			
			LockDataForEdit(BackupParameters.Sender);
			SenderObject = BackupParameters.Sender.GetObject();
			
			SenderObject.SentNo = BackupParameters.ReceivedNo;
			SenderObject.DataExchange.Load = True;
			SenderObject.Write();
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
EndProcedure

// Returns the ID of the saved exchange plan configuration option.
// Parameters:
//   ExchangePlanNode         - ExchangePlanRef -  the exchange plan node that you want to get an overridable
//                                                name for.
//
// Returns:
//  String - 
//
Function SavedExchangePlanNodeSettingOption(ExchangePlanNode) Export
	
	SettingsMode = "";
	
	If Common.HasObjectAttribute("SettingsMode", ExchangePlanNode.Metadata()) Then
		
		SetPrivilegedMode(True);
		SettingsMode = Common.ObjectAttributeValue(ExchangePlanNode, "SettingsMode");
		
	EndIf;
	
	Return SettingsMode;
	
EndFunction

// Returns an array of all exchange message transport modes defined in the configuration.
//
// Returns:
//   Array of EnumRef.ExchangeMessagesTransportTypes - 
//
Function AllConfigurationExchangeMessagesTransports() Export
	
	Result = New Array;
	Result.Add(Enums.ExchangeMessagesTransportTypes.COM);
	Result.Add(Enums.ExchangeMessagesTransportTypes.WS);
	Result.Add(Enums.ExchangeMessagesTransportTypes.FILE);
	Result.Add(Enums.ExchangeMessagesTransportTypes.FTP);
	Result.Add(Enums.ExchangeMessagesTransportTypes.EMAIL);
	Result.Add(Enums.ExchangeMessagesTransportTypes.WSPassiveMode);
	
	Return Result;
EndFunction

// Sends or receives data for an information database node using any of 
// the communication channels available for the exchange plan, except for the COM connection and web service.
//
// Parameters:
//  Cancel                        - Boolean -  the failure flag is set to True if
//                                 the procedure fails.
//  InfobaseNode       - УзелОбменаСсылка -  Panamenista site plan of exchange,
//                                 being operated on data exchange.
//  ActionOnExchange            - EnumRef.ActionsOnExchange -  the data exchange action that is being performed.
//  ExchangeMessagesTransportKind - ПеречислениеСсылка.Перечисления.ВидыТранспортаСообщенийОбмена -  the type of transport
//                                 that will be used in the data exchange process. If omitted, 
//                                 it is determined from the transport parameters set for the exchange plan node when
//                                 setting up the exchange. Optional, the default value is Undefined.
//  ParametersOnly              - Boolean -  contains a flag for selective data loading during rib exchange.
//  AdditionalParameters      - Structure -  reserved for service use.
// 
Procedure ExecuteExchangeActionForInfobaseNode(
		Cancel,
		InfobaseNode,
		ActionOnExchange,
		ExchangeMessagesTransportKind = Undefined,
		Val ParametersOnly = False,
		AdditionalParameters = Undefined) Export
		
	If AdditionalParameters = Undefined Then
		AdditionalParameters = New Structure;
	EndIf;
		
	SetPrivilegedMode(True);
	
	// 
	ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(
		InfobaseNode, ActionOnExchange, ExchangeMessagesTransportKind);
	RecordExchangeStartInInformationRegister(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.Cancel Then
		
		// 
		WriteExchangeFinish(ExchangeSettingsStructure);
		
		Cancel = True;
		
		Return;
	EndIf;
	
	For Each Parameter In AdditionalParameters Do
		ExchangeSettingsStructure.AdditionalParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	MessageString = NStr("en = 'Data exchange started. Node: %1.';", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
	// 
	ExecuteDataExchangeOverFileResource(ExchangeSettingsStructure, ParametersOnly);
	
	WriteExchangeFinish(ExchangeSettingsStructure);
	
	For Each Parameter In ExchangeSettingsStructure.AdditionalParameters Do
		AdditionalParameters.Insert(Parameter.Key, Parameter.Value);
	EndDo;
	
	If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

// Determines whether the folder exists on the FTP server.
//
// Parameters:
//  Path - String -  directory path.
//  DirectoryName - String -  directory name.
//  FTPConnection - FTPConnection -  Ftpconnection used to connect to the FTP server.
// 
// Returns:
//  Boolean - 
//
Function FTPDirectoryExist(Val Path, Val DirectoryName, Val FTPConnection) Export
	
	For Each FTPFile In FTPConnection.FindFiles(Path) Do
		
		If FTPFile.IsDirectory() And FTPFile.Name = DirectoryName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
EndFunction

// Returns the data tables for details of the exchange site.
// 
// Parameters:
//   Tables        - Array of String -  names and details of site plan of exchange.
//   ExchangePlanName - String -  name of the exchange plan.
// 
// Returns:
//   Map - 
//
Function CorrespondentTablesData(Tables, Val ExchangePlanName) Export
	
	Result = New Map;
	ExchangePlanAttributes = Metadata.ExchangePlans[ExchangePlanName].Attributes;
	
	For Each Item In Tables Do
		
		Attribute = ExchangePlanAttributes.Find(Item);
		
		If Attribute <> Undefined Then
			
			AttributeTypes = Attribute.Type.Types();
			
			If AttributeTypes.Count() <> 1 Then
				
				MessageString = NStr("en = 'Default values don''t support flexible data types.
					|Attribute: %1.';");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Attribute.FullName());
				Raise MessageString;
			EndIf;
			
			MetadataObject = Metadata.FindByType(AttributeTypes.Get(0));
			
			If Not Common.IsCatalog(MetadataObject) Then
				
				MessageString = NStr("en = 'Only catalogs support selection of default values.
					|Attribute: %1.';");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, Attribute.FullName());
				Raise MessageString;
			EndIf;
			
			FullMetadataObjectName = MetadataObject.FullName();
			
			TableData = New Structure("MetadataObjectProperties, CorrespondentInfobaseTable");
			TableData.MetadataObjectProperties = MetadataObjectProperties(FullMetadataObjectName);
			TableData.CorrespondentInfobaseTable = GetTableObjects(FullMetadataObjectName);
			
			Result.Insert(FullMetadataObjectName, TableData);
			
		EndIf;
		
	EndDo;
	
	Result.Insert("{AdditionalData}", New Structure); // 
	
	Return Result;
	
EndFunction

// Sets the number of items in a data upload transaction in a constant.
//
// Parameters:
//  Count - Number -  the number of items in the transaction.
// 
Procedure SetDataImportTransactionItemsCount(Count) Export
	
	SetPrivilegedMode(True);
	Constants.DataImportTransactionItemCount.Set(Count);
	
EndProcedure

// Returns a representation of the sync date.
//
// Parameters:
//  SynchronizationDate - Date -  absolute date of data synchronization.
//
// Returns:
//  String - 
//
Function SynchronizationDatePresentation(Val SynchronizationDate) Export
	
	If Not ValueIsFilled(SynchronizationDate) Then
		Return NStr("en = 'Synchronization never started.';");
	EndIf;
	
	Return StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Last synchronized on: %1';"), RelativeSynchronizationDate(SynchronizationDate));
EndFunction

// Returns a representation of the relative sync date.
//
// Parameters:
//  SynchronizationDate - Date -  absolute date of data synchronization.
//
// Returns:
//  String - :
//    *Never              (T = empty date).
//    *Now               (T < 5 min.)
//    *5 minutes ago (5 min < T < 15 min)
//    *15 minutes ago (15 min < T < 30 min)
//    *30 minutes ago (30 min < T < 1 hour)
//    *1 an hour ago (1 hour < T < 2 hours)
//    *2 hours ago (2 hours < T < 3 hours).
//    *Today, 12: 44: 12 (3 hours < T < yesterday).
//    *Yesterday, 22: 30: 45 (yesterday < T < the day before).
//    *DayBeforeYesterday, 21: 22: 54 (the day before yesterday < T < pose-the day before yesterday).
//    *<12 March 2012> (pose-the day before yesterday < T).
//
Function RelativeSynchronizationDate(Val SynchronizationDate) Export
	
	If Not ValueIsFilled(SynchronizationDate) Then
		
		Return NStr("en = 'Never';");
		
	EndIf;
	
	DateCurrent = CurrentSessionDate();
	
	Interval = DateCurrent - SynchronizationDate;
	
	If Interval < 0 Then // 
		
		Result = Format(SynchronizationDate, "DLF=DD");
		
	ElsIf Interval < 60 * 5 Then // 
		
		Result = NStr("en = 'Now';");
		
	ElsIf Interval < 60 * 15 Then // 
		
		Result = NStr("en = '5 minutes ago';");
		
	ElsIf Interval < 60 * 30 Then // 
		
		Result = NStr("en = '15 minutes ago';");
		
	ElsIf Interval < 60 * 60 * 1 Then // 
		
		Result = NStr("en = '30 minutes ago';");
		
	ElsIf Interval < 60 * 60 * 2 Then // 
		
		Result = NStr("en = '1 hour ago';");
		
	ElsIf Interval < 60 * 60 * 3 Then // 
		
		Result = NStr("en = '2 hours ago';");
		
	Else
		
		DifferenceDaysCount = DifferenceDaysCount(SynchronizationDate, DateCurrent);
		
		If DifferenceDaysCount = 0 Then // Today
			
			Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Today, %1';"), Format(SynchronizationDate, "DLF=T"));
			
		ElsIf DifferenceDaysCount = 1 Then // Yesterday
			
			Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Yesterday, %1';"), Format(SynchronizationDate, "DLF=T"));
			
		ElsIf DifferenceDaysCount = 2 Then // 
			
			Result = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Day before yesterday, %1';"), Format(SynchronizationDate, "DLF=T"));
			
		Else // 
			
			Result = Format(SynchronizationDate, "DLF=DD");
			
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

// Returns the ID of the supplied access group profile "data Synchronization with other programs".
//
// Returns:
//  String - 
//
Function DataSynchronizationWithOtherApplicationsAccessProfile() Export
	
	Return "04937803-5dba-11df-a1d4-005056c00008";
	
EndFunction

// Checks whether the current user can administer exchanges.
//
// Returns:
//  Boolean - 
//
Function HasRightsToAdministerExchanges() Export
	
	Return Users.IsFullUser();
	
EndFunction

// The function returns The wsproxy object of the Exchange web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure_ - Structure:
//    * WSWebServiceURL - String -  the location of the wsdl.
//    * WSServiceName - String -  service name.
//    * WSServiceNamespaceURL - String -  URI of the web service namespace.
//    * WSUserName - String -  name of the user to log in to the server.
//    * WSPassword - String -  user password.
//    * WSTimeout - Number -  timeout for operations performed through the received proxy.
//  ErrorMessageString - String -  contains a detailed description of the error if the connection failed;
//  UserMessage - String -  contains a brief description of the error if the connection failed.
//
// Returns:
//  WSProxy - 
//
Function GetWSProxy(SettingsStructure_, ErrorMessageString = "", UserMessage = "") Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure_);
	
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange");
	SettingsStructure_.Insert("WSServiceName",                 "Exchange");
	SettingsStructure_.Insert("WSTimeout", 600);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString, UserMessage);
EndFunction

// The function returns a Wsproxy object of the Exchange_2_0_1_6 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure_ - Structure:
//    * WSWebServiceURL - String -  the location of the wsdl.
//    * WSServiceName - String -  service name.
//    * WSServiceNamespaceURL - String -  URI of the web service namespace.
//    * WSUserName - String -  name of the user to log in to the server.
//    * WSPassword - String -  user password.
//    * WSTimeout - Number -  timeout for operations performed through the received proxy.
//  ErrorMessageString - String -  contains a detailed description of the error if the connection failed;
//  UserMessage - String -  contains a brief description of the error if the connection failed.
//
// Returns:
//  WSProxy - 
//
Function GetWSProxy_2_0_1_6(SettingsStructure_, ErrorMessageString = "", UserMessage = "") Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure_);
	
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_2_0_1_6");
	SettingsStructure_.Insert("WSServiceName",                 "Exchange_2_0_1_6");
	SettingsStructure_.Insert("WSTimeout", 600);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString, UserMessage);
EndFunction

// The function returns a Wsproxy object of the Exchange_2_0_1_7 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure_ - Structure:
//    * WSWebServiceURL - String -  the location of the wsdl.
//    * WSServiceName - String -  service name.
//    * WSServiceNamespaceURL - String -  URI of the web service namespace.
//    * WSUserName - String -  name of the user to log in to the server.
//    * WSPassword - String -  user password.
//    * WSTimeout - Number -  timeout for operations performed through the received proxy.
//  ErrorMessageString - String -  contains a detailed description of the error if the connection failed;
//  UserMessage - String -  contains a brief description of the error if the connection failed.
//  Timeout - Number -  timeout. 
//
// Returns:
//  WSProxy - 
//
Function GetWSProxy_2_1_1_7(SettingsStructure_, ErrorMessageString = "", UserMessage = "", Timeout = 600) Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure_);
	
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_2_0_1_6");
	SettingsStructure_.Insert("WSServiceName",                 "Exchange_2_0_1_6");
	SettingsStructure_.Insert("WSTimeout", Timeout);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString, UserMessage, True);
EndFunction

// The function returns a Wsproxy object of the Exchange_3_0_1_1 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure_ - Structure:
//    * WSWebServiceURL - String -  the location of the wsdl.
//    * WSServiceName - String -  service name.
//    * WSServiceNamespaceURL - String -  URI of the web service namespace.
//    * WSUserName - String -  name of the user to log in to the server.
//    * WSPassword - String -  user password.
//    * WSTimeout - Number -  timeout for operations performed through the received proxy.
//  ErrorMessageString - String -  contains a detailed description of the error if the connection failed;
//  UserMessage - String -  contains a brief description of the error if the connection failed.
//  Timeout - Number -  timeout. 
//
// Returns:
//  WSProxy - 
//
Function GetWSProxy_3_0_1_1(SettingsStructure_, ErrorMessageString = "", UserMessage = "", Timeout = 600) Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure_);
	
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_3_0_1_1");
	SettingsStructure_.Insert("WSServiceName",                 "Exchange_3_0_1_1");
	SettingsStructure_.Insert("WSTimeout",                    Timeout);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString, UserMessage, True);
	
EndFunction

// The function returns a Wsproxy object of the Exchange_3_0_1_1 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure_ - Structure:
//    * WSWebServiceURL - String -  the location of the wsdl.
//    * WSServiceName - String -  service name.
//    * WSServiceNamespaceURL - String -  URI of the web service namespace.
//    * WSUserName - String -  name of the user to log in to the server.
//    * WSPassword - String -  user password.
//    * WSTimeout - Number -  timeout for operations performed through the received proxy.
//  ErrorMessageString - String -  contains a detailed description of the error if the connection failed;
//  UserMessage - String -  contains a brief description of the error if the connection failed.
//  Timeout - Number -  timeout. 
//
// Returns:
//  WSProxy - 
//
Function GetWSProxy_3_0_2_1(SettingsStructure_, ErrorMessageString = "", UserMessage = "", Timeout = 600) Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure_);
	
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_3_0_2_1");
	SettingsStructure_.Insert("WSServiceName",                 "Exchange_3_0_2_1");
	SettingsStructure_.Insert("WSTimeout",                    Timeout);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString, UserMessage, True);
	
EndFunction

// The function returns a Wsproxy object of the Exchange_3_0_1_1 web service created with the passed parameters.
//
// Parameters:
//  SettingsStructure_ - Structure:
//    * WSWebServiceURL - String -  the location of the wsdl.
//    * WSServiceName - String -  service name.
//    * WSServiceNamespaceURL - String -  URI of the web service namespace.
//    * WSUserName - String -  name of the user to log in to the server.
//    * WSPassword - String -  user password.
//    * WSTimeout - Number -  timeout for operations performed through the received proxy.
//  ErrorMessageString - String -  contains a detailed description of the error if the connection failed;
//  UserMessage - String -  contains a brief description of the error if the connection failed.
//  Timeout - Number -  timeout. 
//
// Returns:
//  WSProxy - 
//
Function GetWSProxy_3_0_2_2(SettingsStructure_, ErrorMessageString = "", UserMessage = "", Timeout = 600) Export
	
	DeleteInsignificantCharactersInConnectionSettings(SettingsStructure_);
	
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SSL/Exchange_3_0_2_2");
	SettingsStructure_.Insert("WSServiceName",                 "Exchange_3_0_2_2");
	SettingsStructure_.Insert("WSTimeout",                    Timeout);
	
	Return GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString, UserMessage, True);
	
EndFunction

// 
//
// Returns:
//   Number - 
// 
Function DataImportTransactionItemCount() Export
	
	SetPrivilegedMode(True);
	Return Constants.DataImportTransactionItemCount.Get();
	
EndFunction

// Returns the allowed number of items processed in a single data upload transaction.
//
// Returns:
//   Number - 
// 
Function DataExportTransactionItemsCount() Export
	
	Return 1;
	
EndFunction

// Returns a table with node data for all configured BSP exchanges.
//
// Returns:
//   ValueTable:
//     * InfobaseNode - ExchangePlanRef -  link to the exchange plan node.
//     * Description - String -  name of the exchange plan node.
//     * ExchangePlanName - String -  name of the exchange plan.
//
Function SSLExchangeNodes() Export
	
	Query = New Query(ExchangePlansForMonitorQueryText());
	SetPrivilegedMode(True);
	SSLExchangeNodes = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Return SSLExchangeNodes;
	
EndFunction

// Determines whether the standard conversion rules are used for the exchange plan.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the rules are being loaded for.
//
// Returns:
//   Boolean - 
//
Function StandardRulesUsed(ExchangePlanName) Export
	
	Return InformationRegisters.DataExchangeRules.StandardRulesUsed(ExchangePlanName);
	
EndFunction

// Establishes an external connection to the database and returns a description of the connection.
//
// Parameters:
//  Parameters - Structure - 
//                          
//                          :
//
//    * InfobaseOperatingMode             - Number  -   version of the information base: 0 - file; 1-
//	                                                           client-server;
//    * InfobaseDirectory                   - String -  directory of the information base for the file mode of operation;
//    * NameOf1CEnterpriseServer                     - String -  server1c name:Companies;
//    * NameOfInfobaseOn1CEnterpriseServer - String -  name of the information base on server1c:Companies;
//    * OperatingSystemAuthentication           - Boolean -  indicates whether the operating system is authenticated when creating
//	                                                           an external connection to the database;
//    * UserName                             - String -  name of the database user;
//    * UserPassword                          - String -  password of the database user.
//
// Returns:
//  Structure:
//    * Join                  - COMObject
//                                  - Undefined - 
//                                    
//    * BriefErrorDetails       - String -  short description of the error;
//    * DetailedErrorDetails     - String -  detailed description of the error;
//    * AddInAttachmentError - Boolean -  COM connection error flag.
//
Function ExternalConnectionToInfobase(Parameters) Export
	
	// 
	TransportSettings = TransportSettingsByExternalConnectionParameters(Parameters);
	Return EstablishExternalConnectionWithInfobase(TransportSettings);
	
EndFunction

// Entry point for performing an iteration of data exchange (loading and unloading) with an external system on the exchange plan node.
//
// Parameters:
//  Peer - ExchangePlanRef -  exchange plan node corresponding to the external system.
//  ExchangeParameters - Structure - :
//    * ExecuteImport1 - Boolean -  flag for whether to load data.
//    * ExecuteSettingsSending - Boolean -  the flag need to be sent XDTO settings.
//  FlagError - Boolean -  True, if an error occurs during the exchange.
//                        Detailed information about the error is recorded in the log.
// 
Procedure ExecuteDataExchangeWithExternalSystem(Peer, ExchangeParameters, FlagError) Export
	
	AdditionalParameters = New Structure;
		
	ActionImport = Enums.ActionsOnExchange.DataImport;
	ActionExport = Enums.ActionsOnExchange.DataExport;
	
	Cancel = False;

	BeforePerformingExchanges(Peer, Cancel);
	If Cancel = True Then
		
		Return;
		
	EndIf;
	
	ParametersOnly = False;
	ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem;
	
	FlagError = False;
	
	If ExchangeParameters.ExecuteImport1 Then
		
		ExecuteExchangeActionForInfobaseNode(FlagError, Peer,
			ActionImport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
			
	EndIf;
	
	If ExchangeParameters.ExecuteSettingsSending Then
		
		ExecuteExchangeActionForInfobaseNode(FlagError, Peer,
			ActionExport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
			
	EndIf;
	
	AfterPerformingTheExchanges(Peer, Cancel);
	
EndProcedure

// Defines the default settings for the exchange plan, which can then be overridden
// in the exchange plan Manager module in the get Settings () procedure.
// 
// Parameters:
//   ExchangePlanName         - String -  name of the exchange plan from the metadata.
//   
// Returns:
//   Structure:
//      * ExchangeSettingsOptions                 - See ExchangeSettingsOptionsCollection
//      * GroupTypeForSettingsOptions          - FormGroupType -  a variant of the group type to display in
//                                                 the command tree for creating and exchanging settings.
//      * SourceConfigurationName               - String -  name of the source configuration displayed in
//                                                 the user interface.
//      * DestinationConfigurationName               - Structure -  list of IDs of correspondent configurations
//                                                 that can be exchanged through this exchange plan.
//      * ExchangeFormatVersions                    - Map of KeyAndValue - 
//                                                 
//                                                 :
//         ** Key - Number - 
//         ** Value - CommonModule - 
//      * ExchangeFormat                             - String -  the XDTO namespace of the package that contains 
//                                                   the universal format, without specifying the format version.
//                                                   Used only for exchanges via the universal format.
//      * ExchangeFormatExtensions                  - Map of KeyAndValue:
//        ** Key                                  - String -  URI of the format extension schema namespace.
//        ** Value                              - String -  number of the extensible version of the format.
//      * ExchangePlanUsedInSaaS     - Boolean -  indicates whether the exchange plan is used to organize
//                                                   the exchange in the service model.
//      * IsXDTOExchangePlan                        - Boolean -  indicates that this is an exchange plan using a
//                                                   universal format.
//      * WarnAboutExchangeRuleVersionMismatch - Boolean -  indicates whether you need to check for
//                                                                  version discrepancies in the conversion rules.
//                                                                  Validation is performed when loading a set
//                                                                  of rules, when sending data, and when receiving data.
//      * ExchangePlanNameToMigrateToNewExchange    - String -  if this property is set for the exchange plan 
//                                                   , you will not be 
//                                                   prompted to configure this type of exchange in the settings management workstations.
//                                                   Existing exchanges of this type will continue
//                                                   to be displayed in the list of configured exchanges.
//                                                   Receiving an exchange message in a new format will
//                                                   initiate the transition to a new type of exchange.
//      * ExchangePlanPurpose                    - String -  option for assigning an exchange plan.
//      * Algorithms                                - Structure -  list of export procedures and functions that
//                                                   are declared in the exchange plan Manager module
//                                                   and used by the data exchange subsystem.
//      *RulesForRegisteringInManager              - Boolean -  
//                                                   
//      *RegistrationManagerName                   - String - 
//      *UseCacheOfPublicIdentifiers   - Boolean - 
//                                                   
//      *Global                                - Boolean -  
//                                                   
//                                                   
//
Function DefaultExchangePlanSettings(ExchangePlanName) Export
	
	ExchangePlanPurpose = "SynchronizationWithAnotherApplication";
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName) Then
		ExchangePlanPurpose = "DIB";
	EndIf;
	
	Algorithms = New Structure;
	Algorithms.Insert("OnGetExchangeSettingsOptions",          False);
	Algorithms.Insert("OnGetSettingOptionDetails",        False);
	
	Algorithms.Insert("DataTransferRestrictionsDetails",            False);
	Algorithms.Insert("DefaultValuesDetails",                  False);
	
	Algorithms.Insert("InteractiveExportFilterPresentation",     False);
	Algorithms.Insert("SetUpInteractiveExport",               False);
	Algorithms.Insert("SetUpInteractiveExportSaaS", False);
	
	Algorithms.Insert("DataTransferLimitsCheckHandler",  False);
	Algorithms.Insert("DefaultValuesCheckHandler",        False);
	Algorithms.Insert("AccountingSettingsCheckHandler",            False);
	
	Algorithms.Insert("OnConnectToCorrespondent",                False);
	Algorithms.Insert("OnGetSenderData",                False);
	Algorithms.Insert("OnSendSenderData",                 False);
	
	Algorithms.Insert("OnSaveDataSynchronizationSettings",     False);
	
	Algorithms.Insert("OnDefineSupportedFormatObjects",  False);
	Algorithms.Insert("OnDefineFormatObjectsSupportedByCorrespondent", False);
	
	Algorithms.Insert("BeforeDataSynchronizationSetup",           False);
	
	Parameters = New Structure;
	Parameters.Insert("ExchangeSettingsOptions",                         ExchangeSettingsOptionsCollection());
	Parameters.Insert("SourceConfigurationName",                       "");
	Parameters.Insert("DestinationConfigurationName",                       New Structure);
	Parameters.Insert("ExchangeFormatVersions",                            New Map);
	Parameters.Insert("ExchangeFormat",                                   "");
	Parameters.Insert("ExchangeFormatExtensions",                        New Map);
	Parameters.Insert("ExchangePlanUsedInSaaS",           False);
	Parameters.Insert("IsXDTOExchangePlan",                              False);
	Parameters.Insert("ExchangePlanNameToMigrateToNewExchange",          "");
	Parameters.Insert("WarnAboutExchangeRuleVersionMismatch", True);
	Parameters.Insert("ExchangePlanPurpose",                          ExchangePlanPurpose);
	Parameters.Insert("ConversionRulesAreRequired",            True);
	Parameters.Insert("SelectiveRegistrationMode",                     Undefined);
	Parameters.Insert("Algorithms",                                      Algorithms);
	Parameters.Insert("RulesForRegisteringInManager", False);
	Parameters.Insert("RegistrationManagerName", "");
	Parameters.Insert("UseCacheOfPublicIdentifiers", False);
	Parameters.Insert("Global", False);
		
	Return Parameters;
	
EndFunction

// Defines the default settings for the exchange configuration option, which can then be overridden
// in the exchange plan Manager module in the procedure for getting a description of the configuration Option().
//
// Parameters:
//   ExchangePlanName - String -  contains the name of the exchange plan.
// 
// Returns:
//   Structure:
//      * Filters                                    - Structure -  selections on the exchange plan node 
//                                                    must be filled in with default values.
//      * DefaultValues                       - Structure -  default values on the exchange plan node. 
//      * CommonNodeData                          - String -  comma-separated names of details and table parts of the exchange plan 
//                                                    that are shared by a pair 
//                                                    of exchanging configurations. 
//      * UseDataExchangeCreationWizard - Boolean -  indicates whether the assistant will be used to
//                                                    create new exchange plan nodes.
//      * InitialImageCreationFormName          - String -  name of the form used to create the initial
//                                                    image of a distributed information system.
//      * DataSyncSettingsWizardFormName - String -  name of the form that will be used to configure
//                                                        the rules for sending and receiving data instead
//                                                        of the standard form.
//      * AccountingSettingsSetupNote      - String -  explanation of the sequence of user actions 
//                                                    for configuring accounting parameters in the current
//                                                    information database.
//      * PathToRulesSetFileOnUserSite - String -  the path to the rule set file as an archive
//                                                           on the user site in the configuration section.
//      * PathToRulesSetFileInTemplateDirectory - String -  relative path to the ruleset file in
//                                                     the template directory.
//      * NewDataExchangeCreationCommandTitle - String -  the command view that is displayed in the user 
//                                                         interface when creating a new
//                                                                         data exchange setting.
//      * ExchangeCreateWizardTitle          - String -  view of the header
//                                                    of the data exchange creation assistant form displayed in
//                                                    the user interface.
//      * ExchangePlanNodeTitle                  - String -  view of the exchange plan node
//                                                    displayed in the user interface.
//      * CorrespondentConfigurationName             - String -  ID of the correspondent configuration.
//      * CorrespondentConfigurationDescription    - String -  representation of the name of the correspondent configuration  
//                                                    displayed in the user interface.
//      * UsedExchangeMessagesTransports     - Array of EnumRef.ExchangeMessagesTransportTypes 
//                                                    -  
//                                                    
//      * BriefExchangeInfo                 - String -  a brief description of the data exchange that
//                                                    is displayed on the first page
//                                                    of the exchange creation assistant.
//      * DetailedExchangeInformation               - String -  a link to a web page or the full path to
//                                                    the form inside the configuration as a string to
//                                                    display in the exchange creation assistant.
//      * SettingsFileNameForDestination              - String -  name of the file for saving connection settings
//                                                    when setting up exchange via offline channels.
//      * DataMappingSupported         - Boolean -  
//                                                    
//                                                    
//                                                    
//                                                    
//      * FormatExtension                         - String - 
//                                                    
//                                                    
//                                                    
//                                                     
//                                                     
//                                                    
//      * CorrespondentExchangePlanName              - String -  
//
Function DefaultExchangeSettingOptionDetails(ExchangePlanName) Export
	
	MetadataOfExchangePlan = Metadata.ExchangePlans[ExchangePlanName];
	ExchangePlanSynonym    = MetadataOfExchangePlan.Synonym;
	
	WizardFormTitle = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = 'Data synchronization with %1 (setup)';"),
		ExchangePlanSynonym);
		
	OptionDetails = New Structure;
	
	OptionDetails.Insert("Filters",                                                New Structure);
	OptionDetails.Insert("DefaultValues",                                   New Structure);
	OptionDetails.Insert("CommonNodeData",                                      "");
	OptionDetails.Insert("UseDataExchangeCreationWizard",             True);
	OptionDetails.Insert("InitialImageCreationFormName",                      "");
	OptionDetails.Insert("DataSyncSettingsWizardFormName",         "");
	OptionDetails.Insert("AccountingSettingsSetupNote",                  "");
	OptionDetails.Insert("PathToRulesSetFileOnUserSite",      "");
	OptionDetails.Insert("PathToRulesSetFileInTemplateDirectory",            "");
	OptionDetails.Insert("NewDataExchangeCreationCommandTitle",        ExchangePlanSynonym);
	OptionDetails.Insert("ExchangeCreateWizardTitle",                      WizardFormTitle);
	OptionDetails.Insert("ExchangePlanNodeTitle",                              ExchangePlanSynonym);
	OptionDetails.Insert("CorrespondentConfigurationName",                         "");
	OptionDetails.Insert("CorrespondentConfigurationDescription",                "");
	OptionDetails.Insert("UsedExchangeMessagesTransports",                 New Array);
	OptionDetails.Insert("BriefExchangeInfo",                             "");
	OptionDetails.Insert("DetailedExchangeInformation",                           "");
	OptionDetails.Insert("SettingsFileNameForDestination",                          "");
	OptionDetails.Insert("DataMappingSupported",                     True);
	OptionDetails.Insert("FormatExtension",                                     "");
	OptionDetails.Insert("CorrespondentExchangePlanName",                          "");
	
	Return OptionDetails;
	
EndFunction

// It is intended for preparing the structure and then passing it to the handler to get a description of the variant.
//
// Parameters:
//  CorrespondentName - String -  name of the corresponding configuration.
//  CorrespondentVersion - String -  version of the corresponding configuration.
//
// Returns:
//   Structure:
//     * CorrespondentName - String -  name of the correspondent configuration.
//     * CorrespondentVersion - String -  version number of the correspondent configuration.
//
Function ContextParametersOfSettingOptionDetailsReceipt(CorrespondentName, CorrespondentVersion) Export
	
	Result = New Structure;
	Result.Insert("CorrespondentName",    CorrespondentName);
	Result.Insert("CorrespondentVersion", CorrespondentVersion);
	
	Return Result;
	
EndFunction

#Region ConnectionToExternalSystemSettings

// Saves connection settings for sharing with an external system via EnterpriseData. 
//
// Parameters:
//  Context - Structure - :
//    * Mode - String -  the mode in which the handler is called.
//                       Possible values: "new Connection" | "edit connection Parameters".
//    * Peer - ExchangePlanRef
//                    - Undefined - 
//                                     
//    * ExchangePlanName - String
//                     - Undefined - 
//    * SettingID - String
//                             - Undefined - 
//                                              
//  ConnectionParameters - Structure - :
//    * CorrespondentID - String -  a 36-character string
//                                  - Undefined -  unique identifier of the correspondent.
//    * CorrespondentDescription - String
//                                 - Undefined - 
//                                                  
//    * TransportSettings - Arbitrary
//                          - Undefined - 
//    * SynchronizationSchedule - JobSchedule
//                              - Undefined - 
//    * XDTOSettings - Structure
//                    - Undefined - :
//      ** SupportedVersions - Array -  list of the format versions supported by the correspondent.
//      ** SupportedObjects - See DataExchangeXDTOServer.SupportedObjectsInFormat
//  Result - Structure:
//    * ExchangeNode - ExchangePlanRef -  exchange plan node corresponding to the correspondent.
//    * CorrespondentID - String -  unique identifier of the correspondent.
//
Procedure OnSaveExternalSystemConnectionSettings(Context, ConnectionParameters, Result) Export
	
	Peer = Undefined;
	Context.Property("Peer", Peer);
	
	XDTOSettings = Undefined;
	ConnectionParameters.Property("XDTOSettings", XDTOSettings);
	
	ExchangeFormatVersion = "";
	If Not XDTOSettings = Undefined Then
		If XDTOSettings.SupportedVersions <> Undefined
			And XDTOSettings.SupportedVersions.Count() > 0 Then
			ExchangeFormatVersion = DataExchangeXDTOServer.MaxCommonFormatVersion(
				Context.ExchangePlanName, XDTOSettings.SupportedVersions);
		EndIf;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		If Context.Mode = "New_Connection" Then
			
			CorrespondentID = Undefined;
			ConnectionParameters.Property("CorrespondentID", CorrespondentID);
			If Not ValueIsFilled(CorrespondentID) Then
				CorrespondentID = XMLString(New UUID);
			EndIf;
			
			Peer = NewXDTODataExchangeNode(
				Context.ExchangePlanName,
				Context.SettingID,
				CorrespondentID,
				ConnectionParameters.CorrespondentDescription,
				ExchangeFormatVersion);
			
			If Not Common.DataSeparationEnabled() Then
				UpdateDataExchangeRules();
			EndIf;
			
			DatabaseObjectsTable = DataExchangeXDTOServer.SupportedObjectsInFormat(
				Context.ExchangePlanName, "SendReceive", Peer);
			
			XDTODataExchangeConfigurationModule = Common.CommonModule("InformationRegisters.XDTODataExchangeSettings");
			XDTODataExchangeConfigurationModule.UpdateSettings2(
				Peer, "SupportedObjects", DatabaseObjectsTable);
				
			RecordStructure = New Structure;
			RecordStructure.Insert("InfobaseNode",       Peer);
			RecordStructure.Insert("CorrespondentExchangePlanName", Context.ExchangePlanName);
			
			DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
		ElsIf Context.Mode = "EditConnectionParameters" Then
			CorrespondentData = Common.ObjectAttributesValues(Peer, "Code, Description, ExchangeFormatVersion");
			
			ValuesToUpdate = New Structure;
			
			If ConnectionParameters.Property("CorrespondentID")
				And ValueIsFilled(ConnectionParameters.CorrespondentID)
				And TrimAll(ConnectionParameters.CorrespondentID) <> TrimAll(CorrespondentData.Code) Then
				ValuesToUpdate.Insert("Code", TrimAll(ConnectionParameters.CorrespondentID));
			EndIf;
			
			If ConnectionParameters.Property("CorrespondentDescription")
				And ValueIsFilled(ConnectionParameters.CorrespondentDescription)
				And TrimAll(ConnectionParameters.CorrespondentDescription) <> TrimAll(CorrespondentData.Description) Then
				ValuesToUpdate.Insert("Description", TrimAll(ConnectionParameters.CorrespondentDescription));
			EndIf;
			
			If ValueIsFilled(ExchangeFormatVersion)
				And Not ExchangeFormatVersion = CorrespondentData.ExchangeFormatVersion Then
				ValuesToUpdate.Insert("ExchangeFormatVersion", ExchangeFormatVersion);
			EndIf;
			
			If ValuesToUpdate.Count() > 0 Then
				Block = New DataLock;
			    LockItem = Block.Add(Common.TableNameByRef(Peer));
			    LockItem.SetValue("Ref", Peer);
			    Block.Lock();
			    
				LockDataForEdit(Peer);
				CorrespondentObject = Peer.GetObject();
				
				For Each ValueToUpdate In ValuesToUpdate Do
					CorrespondentObject[ValueToUpdate.Key] = ValueToUpdate.Value;
				EndDo;

			    CorrespondentObject.DataExchange.Load = True;
				CorrespondentObject.Write();
			EndIf;
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Invalid function call mode: %1';"), Context.Mode);
		EndIf;
		
		If Not XDTOSettings = Undefined Then
			If Not XDTOSettings.SupportedObjects = Undefined Then
				XDTODataExchangeConfigurationModule = Common.CommonModule("InformationRegisters.XDTODataExchangeSettings");
				XDTODataExchangeConfigurationModule.UpdateCorrespondentSettings(
					Peer, "SupportedObjects", XDTOSettings.SupportedObjects);
			EndIf;
		EndIf;
		
		ModuleDataExchangeTransportSettings = Common.CommonModule("InformationRegisters.DataExchangeTransportSettings");
		ModuleDataExchangeTransportSettings.SaveExternalSystemTransportSettings(
			Peer, ConnectionParameters.TransportSettings);
			
		If ConnectionParameters.Property("SynchronizationSchedule")
			And ConnectionParameters.SynchronizationSchedule <> Undefined Then
			
			UseScheduledJob = ?(ConnectionParameters.Property("UseScheduledJob"),
				ConnectionParameters.UseScheduledJob, True);
				
			If Common.DataSeparationEnabled() Then
				If Common.SubsystemExists("CloudTechnology.JobsQueue") 
					And Common.SubsystemExists("CloudTechnology.Core") Then
					
					ModuleJobsQueue = Common.CommonModule("JobsQueue");
					ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
					
					JobKey = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Data exchange with external system (%1)';"),
						Common.ObjectAttributeValue(Peer, "Code"));
						
					JobParameters = New Structure;
					JobParameters.Insert("DataArea", ModuleSaaSOperations.SessionSeparatorValue());
					JobParameters.Insert("Use", UseScheduledJob);
					JobParameters.Insert("MethodName",     "DataExchangeServer.ExecuteDataExchangeWithExternalSystem");
					
					JobParameters.Insert("Parameters", New Array);
					JobParameters.Parameters.Add(Peer);
					JobParameters.Parameters.Add(New Structure("ExecuteImport1, ExecuteSettingsSending", True, True));
					JobParameters.Parameters.Add(False);
					
					JobParameters.Insert("Key",       JobKey);
					JobParameters.Insert("Schedule", ConnectionParameters.SynchronizationSchedule);
					
					If Context.Mode = "New_Connection" Then
						ModuleJobsQueue.AddJob(JobParameters);
					ElsIf Context.Mode = "EditConnectionParameters" Then
						Filter = New Structure("DataArea, MethodName, Key");
						FillPropertyValues(Filter, JobParameters);
						
						JobTable = ModuleJobsQueue.GetJobs(Filter);
						If JobTable.Count() > 0 Then
							ModuleJobsQueue.ChangeJob(JobTable[0].Id, JobParameters);
						Else
							ModuleJobsQueue.AddJob(JobParameters);
						EndIf;
					EndIf;
					
				EndIf;
			Else
				If Context.Mode = "New_Connection" Then
					Catalogs.DataExchangeScenarios.CreateScenario(
						Peer, ConnectionParameters.SynchronizationSchedule, UseScheduledJob);
				ElsIf Context.Mode = "EditConnectionParameters" Then
					Query = New Query(
					"SELECT DISTINCT
					|	DataExchangeScenarios.Ref AS Scenario,
					|	DataExchangeScenarios.Ref.UseScheduledJob AS UseScheduledJob
					|FROM
					|	Catalog.DataExchangeScenarios AS DataExchangeScenarios
					|		INNER JOIN Catalog.DataExchangeScenarios.ExchangeSettings AS DataExchangeScenariosExchangeSettings
					|		ON (DataExchangeScenariosExchangeSettings.Ref = DataExchangeScenarios.Ref)
					|WHERE
					|	DataExchangeScenariosExchangeSettings.InfobaseNode = &InfobaseNode
					|	AND NOT DataExchangeScenarios.DeletionMark");
					Query.SetParameter("InfobaseNode", Peer);
					
					Selection = Query.Execute().Select();
					If Selection.Next() Then
						ScenarioObject = Selection.Scenario.GetObject(); // CatalogObject.DataExchangeScenarios
						
						Cancel = False;
						Catalogs.DataExchangeScenarios.UpdateScheduledJobData(
							Cancel, ConnectionParameters.SynchronizationSchedule, ScenarioObject);
							
						If Not Cancel Then
							ScenarioObject.UseScheduledJob = UseScheduledJob;
							ScenarioObject.Write();
						EndIf;
					EndIf;
				EndIf;
			EndIf;
			
		EndIf;
			
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If Context.Mode = "New_Connection" Then
		// 
		ExchangeParameters = New Structure;
		ExchangeParameters.Insert("ExecuteImport1",         False);
		ExchangeParameters.Insert("ExecuteSettingsSending", True);
		
		Cancel             = False;
		ErrorMessage = "";
		Try
			ExecuteDataExchangeWithExternalSystem(Peer, ExchangeParameters, Cancel);
		Except
			Cancel = True;
			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			WriteLogEvent(DataExchangeCreationEventLogEvent(),
				EventLogLevel.Error, , , ErrorMessage);
		EndTry;
		
		If Cancel Then
			DeletionSettings = New Structure;
			DeletionSettings.Insert("ExchangeNode", Peer);
			DeletionSettings.Insert("DeleteSettingItemInCorrespondent", True);
			
			ProcedureParameters = New Structure;
			ProcedureParameters.Insert("DeletionSettings", DeletionSettings);
			
			ResultAddress = "";
			Try
				ModuleDataExchangeCreationWizard().DeleteSynchronizationSetting(ProcedureParameters, ResultAddress);
			Except
				Raise;
			EndTry;
			
			Raise ErrorMessage;
		EndIf;
	EndIf;
		
	Result = New Structure;
	Result.Insert("ExchangeNode", Peer);
	Result.Insert("CorrespondentID",
		Common.ObjectAttributeValue(Peer, "Code"));
	
EndProcedure

// Fills in the structure of saved connection parameters to the external system.
//
// Parameters:
//  Context - Structure - :
//    * Peer - ExchangePlanRef -  the exchange node corresponding to the correspondent.
//  ConnectionParameters - Structure - :
//    * CorrespondentID - String -  a 36-character string with a unique correspondent ID.
//    * CorrespondentDescription - String -  the name of the correspondent, as it appears
//                                            in the list of configured syncs.
//    * TransportSettings - Arbitrary -  saved settings for the transport of exchange messages from the external system.
//    * SynchronizationSchedule - JobSchedule -  schedule for automatic start of the exchange.
//    * XDTOSettings - Structure
//                    - Undefined - :
//      ** SupportedVersions - Array -  list of the format versions supported by the correspondent.
//      ** SupportedObjects - See DataExchangeXDTOServer.SupportedObjectsInFormat.
//
Procedure OnGetExternalSystemConnectionSettings(Context, ConnectionParameters) Export
	
	SetPrivilegedMode(True);
	
	ExchangeNodeData = Common.ObjectAttributesValues(Context.Peer, "Code, Description");
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("CorrespondentID", ExchangeNodeData.Code);
	ConnectionParameters.Insert("CorrespondentDescription",  ExchangeNodeData.Description);
	ConnectionParameters.Insert("TransportSettings",
		InformationRegisters.DataExchangeTransportSettings.ExternalSystemTransportSettings(Context.Peer));
	ConnectionParameters.Insert("SynchronizationSchedule");
	ConnectionParameters.Insert("XDTOSettings", New Structure);
	
	ConnectionParameters.XDTOSettings.Insert("SupportedVersions",
		InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(Context.Peer, "SupportedVersions"));
	ConnectionParameters.XDTOSettings.Insert("SupportedObjects",
		InformationRegisters.XDTODataExchangeSettings.CorrespondentSettingValue(Context.Peer, "SupportedObjects"));
	
EndProcedure
	
// Table of exchange transport settings for all configured data exchanges with external systems.
//
// Returns:
//  ValueTable:
//    * Peer - ExchangePlanRef -  the exchange node corresponding to the correspondent.
//    * TransportSettings - Arbitrary -  saved settings for the transport of exchange messages from the external system.
//
Function AllTransportSettingsOfExchangeWithExternalSystems() Export
	
	Result = New ValueTable;
	Result.Columns.Add("Peer");
	Result.Columns.Add("TransportSettings");
	
	CommonQueryText = "";
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	
	For Each ExchangePlan In SSLExchangePlans Do
		
		If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlan) Then
			Continue;
		EndIf;
		
		QueryText = 
		"SELECT
		|	T.Ref AS Peer,
		|	DataExchangeTransportSettings.ExternalSystemConnectionParameters AS ExternalSystemConnectionParameters
		|FROM
		|	#ExchangePlanTable AS T
		|		INNER JOIN InformationRegister.DataExchangeTransportSettings AS DataExchangeTransportSettings
		|		ON (DataExchangeTransportSettings.Peer = T.Ref)
		|WHERE
		|	NOT T.ThisNode
		|	AND DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.ExternalSystem)";
		QueryText = StrReplace(QueryText, "#ExchangePlanTable", "ExchangePlan." + ExchangePlan);
		
		If Not IsBlankString(CommonQueryText) Then
			CommonQueryText = CommonQueryText + "
			|
			|UNION ALL
			|
			|";
		EndIf;
		
		CommonQueryText = CommonQueryText + QueryText;
		
	EndDo;
	
	If IsBlankString(CommonQueryText) Then
		Return Result;
	EndIf;
	
	Query = New Query(CommonQueryText);
	
	SetPrivilegedMode(True);
	SettingsTable1 = Query.Execute().Unload();
	
	For Each SettingString In SettingsTable1 Do
		ResultRow = Result.Add();
		ResultRow.Peer = SettingString.Peer;
		ResultRow.TransportSettings = SettingString.ExternalSystemConnectionParameters.Get();
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#Region SaveDataSynchronizationSettings

// Starts saving data synchronization settings in a long operation.
// When the settings are saved, the transmitted fill data is transferred to the exchange node,
// and a sign is set that the synchronization configuration is completed.
// We recommend using data synchronization settings in the assistant.
// 
// Parameters:
//  SynchronizationSettings - Structure - :
//   * ExchangeNode - ExchangePlanRef -  the exchange plan node for which synchronization settings are saved.
//   * FillingData - Structure -  custom structure for filling in settings on the node.
//                                    It will be passed to the algorithm for "saving the data in sync" (if available).
//  HandlerParameters   - Structure -  outgoing service parameter. Reserved for internal use.
//                                       Used to track the status of a long-running operation.
//                                       You should pass the "Custom" form details to the input
//                                       , which are not used in any other operations.
//  ContinueWait     - Boolean    -  outgoing parameter. True if saving the setting is started in a long operation.
//                                       To track the status in this case, use the procedure 
//                                       Abendanimation.When waiting for the save set-up to sync.
//
Procedure OnStartSaveSynchronizationSettings(SynchronizationSettings, HandlerParameters, ContinueWait = True) Export
	
	ModuleDataExchangeCreationWizard().OnStartSaveSynchronizationSettings(SynchronizationSettings,
		HandlerParameters,
		ContinueWait);
	
EndProcedure

// Used when waiting for the completion of the synchronization configuration data.
// Checks the status of a long-running operation to save the setting, and returns a sign
// that you need to continue waiting, or reports that the operation to save the setting is completed.
// 
// Parameters:
//  HandlerParameters   - Structure -  incoming / outgoing service parameter. Reserved for internal use.
//                                       Used to track the status of a long-running operation.
//                                       The input should be passed the "Custom" form details
//                                       that were used when starting the synchronization settings
//                                       by calling the method Obmendannymiserver.At the beginning of saving, the synchronization settings are set up.
//  ContinueWait     - Boolean    -  outgoing parameter. True if you need to continue waiting
//                                       for the save sync setting operation to complete, False if
//                                       the sync setting is completed.
//
Procedure OnWaitForSaveSynchronizationSettings(HandlerParameters, ContinueWait) Export

	ModuleDataExchangeCreationWizard().OnWaitForSaveSynchronizationSettings(HandlerParameters,
		ContinueWait);
	
EndProcedure

// Gets the status of completion of the synchronization setup operation. Invoked when the procedure
// Abendanimation.At the beginning of the save, set up the sync or command Server.When
// waiting for saving, the sync settings set the continue Waiting flag to False.
// 
// Parameters:
//  HandlerParameters   - Structure -  incoming service parameter. Reserved for internal use.
//                                       Used to get the status of a long operation.
//                                       The input should be passed the "Custom" form details
//                                       that were used when starting the synchronization settings
//                                       by calling the method Obmendannymiserver.At the beginning of saving, the synchronization settings are set up.
//  CompletionStatus       - Structure - :
//   * Cancel             - Boolean -  True if an error occurred during startup or during a long operation.
//   * ErrorMessage - String -  text of the error that occurred during a long operation, if Failure = True.
//   * Result         - Structure - :
//    ** SettingsSaved - Boolean -  True if the synchronization setup was completed successfully.
//    ** ErrorMessage  - String -  text of the error that occurred directly in the transaction for saving the synchronization setting.
//
Procedure OnCompleteSaveSynchronizationSettings(HandlerParameters, CompletionStatus) Export
	
	ModuleDataExchangeCreationWizard().OnCompleteSaveSynchronizationSettings(HandlerParameters,
		CompletionStatus);
	
EndProcedure

#EndRegion

#Region CommonInfobasesNodesSettings

// Sets whether the data synchronization configuration is completed.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef -  the exchange node to set the attribute for.
//
Procedure CompleteDataSynchronizationSetup(ExchangeNode) Export
	
	SetPrivilegedMode(True);
	
	If ExchangeNode = ExchangePlans[DataExchangeCached.GetExchangePlanName(ExchangeNode)].ThisNode() Then
		Return;
	EndIf;
	
	SynchronizationSetupCompleted = True;
	
	BeginTransaction();
	Try
		
		If Not SynchronizationSetupCompleted(ExchangeNode) Then
			
			SynchronizationSetupCompleted = False;
			
			// 
			// 
			ExchangePlans.DeleteChangeRecords(ExchangeNode);
			
		EndIf;
		
		InformationRegisters.CommonInfobasesNodesSettings.SetFlagSettingCompleted(ExchangeNode);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	// 
	If Not SynchronizationSetupCompleted
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.ChangeTheIndicationOfTheNeedForDataExchangeInTheServiceModel(False);	
			
	EndIf;
	
EndProcedure

// Returns whether synchronization settings for the exchange node have been completed.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef -  the exchange node to get the attribute for.
//
// Returns:
//   Boolean - 
//
Function SynchronizationSetupCompleted(ExchangeNode) Export
	
	If DataExchangeCached.IsMessagesExchangeNode(ExchangeNode) Then
		Return True;
	Else
		SetPrivilegedMode(True);
		
		Return InformationRegisters.CommonInfobasesNodesSettings.SettingCompleted(ExchangeNode);
	EndIf;
	
EndFunction

// Sets whether the initial image of the rib node was created successfully.
//
// Parameters:
//   ExchangeNode - ExchangePlanRef -  the exchange node to set the attribute for.
//
Procedure CompleteInitialImageCreation(ExchangeNode) Export
	
	InformationRegisters.CommonInfobasesNodesSettings.SetFlagInitialImageCreated(ExchangeNode);
	
EndProcedure

#EndRegion

#Region ForCallsFromOtherSubsystems

// 

// Returns a link to the exchange plan node found by its code.
// If the node is not found, it returns Undefined.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan as specified in the Configurator.
//  NodeCode - String -  code of the exchange plan node.
//
// Returns:
//  ExchangePlanRef - 
//  
//
Function ExchangePlanNodeByCode(ExchangePlanName, NodeCode) Export
	
	NodeRef = ExchangePlans[ExchangePlanName].FindByCode(NodeCode);
	
	If Not ValueIsFilled(NodeRef) Then
		Return Undefined;
	EndIf;
	
	Return NodeRef;
	
EndFunction

// Returns True if the session is started in an offline workplace.
// Returns:
//  Boolean - 
//
Function IsStandaloneWorkplace() Export
	
	Return DataExchangeCached.StandaloneWorkstationMode();
	
EndFunction

// Determines whether the transferred exchange plan node is a stand-alone workplace.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef -  the node being checked.
//
// Returns:
//  Boolean - 
//
Function IsStandaloneWorkstationNode(Val InfobaseNode) Export
	
	Return DataExchangeCached.IsStandaloneWorkstationNode(InfobaseNode);
	
EndFunction

// Deletes a set of entries in the register based on the passed structure values.
//
// Parameters:
//  RecordStructure - Structure -  structure to delete a set of records based on its values.
// 
Procedure DeleteDataExchangesStateRecords(RecordStructure) Export
	
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure, "DataExchangesStates");
	
EndProcedure

// Deletes a set of entries in the register based on the passed structure values.
//
// Parameters:
//  RecordStructure - Structure -  structure to delete a set of records based on its values.
// 
Procedure DeleteSuccessfulDataExchangesStatesRecords(RecordStructure) Export
	
	DataExchangeInternal.DeleteRecordSetFromInformationRegister(RecordStructure, "SuccessfulDataExchangesStates");
	
EndProcedure

// Deletes the supplied rules for the exchange plan (clears the data in the register).
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan for which the rules are being deleted.
//
Procedure DeleteSuppliedRules(ExchangePlanName) Export
	
	InformationRegisters.DataExchangeRules.DeleteSuppliedRules(ExchangePlanName);	
	
EndProcedure

// Loads the supplied rules for the exchange plan.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the rules are being loaded for.
//  RulesFileName - String -  full name of the exchange rules file (*. zip).
//
Procedure ImportSuppliedRules(ExchangePlanName, RulesFileName) Export
	
	InformationRegisters.DataExchangeRules.ImportSuppliedRules(ExchangePlanName, RulesFileName);	
	
EndProcedure

// Returns the ID of the exchange setting corresponding to a specific correspondent.
// 
// Parameters:
//   ExchangePlanName       - String -  name of the exchange plan that is used to configure the exchange.
//   CorrespondentVersion - String -  the version number of the correspondent with which the exchange is configured.
//   CorrespondentName    - String -  the name of the correspondent (see the function configurename of the source
//                          on the side of the correspondent configuration).
//
// Returns:
//   Array of String - 
// 
Function CorrespondentExchangeSettingsOptions(ExchangePlanName, CorrespondentVersion, CorrespondentName) Export
	
	ExchangePlanSettings = ExchangePlanSettings(ExchangePlanName, CorrespondentVersion, CorrespondentName, True);
	If ExchangePlanSettings.ExchangeSettingsOptions.Count() = 0 Then
		Return New Array;
	Else
		Return ExchangePlanSettings.ExchangeSettingsOptions.UnloadColumn("SettingID");
	EndIf;
	
EndFunction

// Returns the ID of the exchange setting corresponding to a specific correspondent.
// 
// Parameters:
//  ExchangePlanName    - String -  name of the exchange plan that is used to configure the exchange.
//  CorrespondentName - String -  the name of the correspondent (see the function configurename of the source
//                               on the side of the correspondent configuration).
//
// Returns:
//  String - 
// 
Function ExchangeSetupOptionForCorrespondent(ExchangePlanName, CorrespondentName) Export
	
	ExchangePlanSettings = ExchangePlanSettings(ExchangePlanName, "", CorrespondentName, True);
	If ExchangePlanSettings.ExchangeSettingsOptions.Count() = 0 Then
		Return "";
	Else
		Return ExchangePlanSettings.ExchangeSettingsOptions[0].SettingID;
	EndIf;
	
EndFunction

// 
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan for which the rules are being deleted.
//
Procedure DeleteSuppliedObjectRegistrationRules(ExchangePlanName) Export
	
	InformationRegisters.DataExchangeRules.DeleteSuppliedObjectRegistrationRules(ExchangePlanName);	
	
EndProcedure

// 
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan that the rules are being loaded for.
//  RulesFileName - String - 
//
Procedure DownloadSuppliedObjectRegistrationRules(ExchangePlanName, RulesFileName) Export
	
	InformationRegisters.DataExchangeRules.DownloadSuppliedObjectRegistrationRules(
		ExchangePlanName,
		RulesFileName);	
	
EndProcedure

// 

#EndRegion

#Region ObsoleteProceduresAndFunctions

// Deprecated. Adds information about the number of elements in a transaction set in a constant
// to the structure containing parameters for the transport of exchange messages.
//
// Parameters:
//  Result - Structure -  contains parameters for the transport of exchange messages.
// 
Procedure AddTransactionItemsCountToTransportSettings(Result) Export
	
	DataExchangeInternal.AddTransactionItemsCountToTransportSettings(Result);
	
EndProcedure

// Deprecated. Returns the area number based on the node code of the exchange plan (messaging).
// 
// Parameters:
//  NodeCode - String -  code of the exchange plan node.
// 
// Returns:
//  Number - 
//
Function DataAreaNumberFromExchangePlanNodeCode(Val NodeCode) Export
	
	Return DataExchangeInternal.DataAreaNumberFromExchangePlanNodeCode(NodeCode);
	
EndFunction

// Deprecated. Returns data from the first record of the query result as a structure.
// 
// Parameters:
//  QueryResult - QueryResult -  the result of the request containing the data to be processed.
// 
// Returns:
//  Structure - 
//
Function QueryResultToStructure(Val QueryResult) Export
	
	Return DataExchangeInternal.QueryResultToStructure(QueryResult);
	
EndFunction

// Deprecated.
// 
//  
//  
//  
//  
//
//  
// 
// Parameters:
//   ExchangePlanNode         - ExchangePlanRef -  the exchange plan node that you want to get an overridable
//                                                name for.
//   ParameterNameWithNodeName - String -  name of the parameter, in the default settings, from which to get the node name.
//   SettingsMode        - String -  exchange settings option.
//
// Returns:
//  String - 
//
Function OverridableExchangePlanNodeName(Val ExchangePlanNode, ParameterNameWithNodeName, SettingsMode = "") Export
	
	SetPrivilegedMode(True);
	
	ExchangePlanPresentation1 = ExchangePlanSettingValue(
		ExchangePlanNode.Metadata().Name,
		ParameterNameWithNodeName,
		SettingsMode);
	
	SetPrivilegedMode(False);
	
	Return ExchangePlanPresentation1;
	
EndFunction

// Deprecated.
// 
// 
//
// Parameters:
//   Nodes - Array of ExchangePlanRef -  exchange nodes.
//
// Returns:
//   Number - 
// 
Function UnresolvedIssuesCount(Nodes = Undefined) Export
	
	Return DataExchangeIssueCount(Nodes) + VersioningIssuesCount(Nodes);
	
EndFunction

// Deprecated.
// 
// Parameters:
//   Nodes - Array of ExchangePlanRef -  exchange nodes.
//
// Returns:
//   Structure:
//     * Title - String   -  the title of the hyperlink.
//     * Picture  - Picture -  image for the hyperlink.
//
Function IssueMonitorHyperlinkTitleStructure(Nodes = Undefined) Export
	
	Count = UnresolvedIssuesCount(Nodes);
	
	If Count > 0 Then
		
		Title = NStr("en = 'Warnings (%1)';");
		Title = StringFunctionsClientServer.SubstituteParametersToString(Title, Count);
		Picture = PictureLib.Warning;
		
	Else
		
		Title = NStr("en = 'No warnings';");
		Picture = New Picture;
		
	EndIf;
	
	TitleStructure = New Structure;
	TitleStructure.Insert("Title", Title);
	TitleStructure.Insert("Picture", Picture);
	
	Return TitleStructure;
	
EndFunction

#EndRegion

#EndRegion

#Region Internal

#Region DifferentPurpose

// Loads priority data received from the main rib node.
Procedure ImportPriorityDataToSubordinateDIBNode(Cancel = False) Export
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportPriorityDataBeforeStart") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
	SetPrivilegedMode(False);
	
	Try
		
		If Not GetFunctionalOption("UseDataSynchronization") Then
			
			If Common.DataSeparationEnabled() Then
				
				UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
				UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
				UseDataSynchronization.DataExchange.Load = True;
				UseDataSynchronization.Value = True;
				UseDataSynchronization.Write();
				
			Else
				
				If GetExchangePlansInUse().Count() > 0 Then
					
					UseDataSynchronization = Constants.UseDataSynchronization.CreateValueManager();
					UseDataSynchronization.AdditionalProperties.Insert("DisableObjectChangeRecordMechanism");
					UseDataSynchronization.DataExchange.Load = True;
					UseDataSynchronization.Value = True;
					UseDataSynchronization.Write();
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If GetFunctionalOption("UseDataSynchronization") Then
			
			InfobaseNode = MasterNode();
			
			If InfobaseNode <> Undefined Then
				
				InformationRegisters.DataExchangeTransportSettings.TransferSettingsOfCorrespondentDataExchangeTransport(InfobaseNode);
				TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
				
				ParameterName = "StandardSubsystems.DataExchange.RecordRules."
					+ DataExchangeCached.GetExchangePlanName(InfobaseNode);
				RegistrationRulesUpdated = StandardSubsystemsServer.ApplicationParameter(ParameterName);
				If RegistrationRulesUpdated = Undefined Then
					UpdateDataExchangeRules();
				EndIf;
				RegistrationRulesUpdated = StandardSubsystemsServer.ApplicationParameter(ParameterName);
				If RegistrationRulesUpdated = Undefined Then
					Raise StringFunctionsClientServer.SubstituteParametersToString(
						NStr("en = 'Cannot update data registration rules cache for exchange plan ""%1""';"),
						DataExchangeCached.GetExchangePlanName(InfobaseNode));
				EndIf;
				
				// 
				ExchangeParameters = ExchangeParameters();
				ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
				ExchangeParameters.ExecuteImport1 = True;
				ExchangeParameters.ExecuteExport2 = False;
				ExchangeParameters.ParametersOnly   = True;
				ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
				
			EndIf;
			
		EndIf;
		
	Except
		SetPrivilegedMode(True);
		SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
		SetPrivilegedMode(False);
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		WriteLogEvent(
			NStr("en = 'Data exchange.Priority data import';", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Raise
			NStr("en = 'Cannot import priority data from the exchange message.
			           |For details, see the event log.';");
	EndTry;
	SetPrivilegedMode(True);
	SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
	SetPrivilegedMode(False);
	
	If Cancel Then
		
		If ConfigurationChanged() Then
			Raise
				NStr("en = 'Changes are imported from the main node. Do the following:
				           | 1. Exit the application.
				           | 2. Open the application in Designer.
				           | 3. Run the ""Update database configuration (F7)"" command.
				           | 4. Re-open the application.';");
		EndIf;
		
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		
		Raise
			NStr("en = 'Cannot import priority data from the exchange message.
			           |For details, see the event log.';");
	EndIf;
	
EndProcedure

// Sets whether the download will be repeated if there is a download or update error.
// Clears the storage of the exchange message received from the main rib node.
//
Procedure EnableDataExchangeMessageImportRecurrenceBeforeStart() Export
	
	ClearDataExchangeMessageFromMasterNode();
	
	Constants.RetryDataExchangeMessageImportBeforeStart.Set(True);
	
EndProcedure

// Initializes an XML file to record information about objects
// marked for update processing and pass them to a subordinate rib node.
//
Procedure InitializeUpdateDataFile(Parameters) Export
	
	FileToWriteXML = Undefined;
	NameOfChangedFile = Undefined;
	
	If StandardSubsystemsCached.DIBUsed("WithFilter") Then
		
		NameOfChangedFile = FullNameOfFileOfDeferredUpdateData();
		
		FileToWriteXML = New FastInfosetWriter;
		FileToWriteXML.OpenFile(NameOfChangedFile);
		FileToWriteXML.WriteXMLDeclaration();
		FileToWriteXML.WriteStartElement("Objects");
		
	EndIf;
	
	Parameters.NameOfChangedFile = NameOfChangedFile;
	Parameters.WriteChangesForSubordinateDIBNodeWithFilters = FileToWriteXML;
	
EndProcedure

// Initializes an XML file to record information about objects.
//
Procedure WriteUpdateDataToFile(Parameters, Data, DataKind, FullObjectName = "") Export
	
	If Not StandardSubsystemsCached.DIBUsed("WithFilter") Then
		Return;
	EndIf;
	
	If Parameters.WriteChangesForSubordinateDIBNodeWithFilters = Undefined Then
		ExceptionText = NStr("en = 'The processing of the data registration parameters in the handler is poorly arranged.';");
		Raise ExceptionText;
	EndIf;
	
	XMLWriter = Parameters.WriteChangesForSubordinateDIBNodeWithFilters;
	XMLWriter.WriteStartElement("Object");
	XMLWriter.WriteAttribute("Queue", String(Parameters.Queue));
	
	If Not ValueIsFilled(FullObjectName) Then
		FullObjectName = Data.Metadata().FullName();
	EndIf;
	
	XMLWriter.WriteAttribute("Type", FullObjectName);
	
	If Upper(DataKind) = "REF" Then
		XMLWriter.WriteAttribute("Ref", XMLString(Data.Ref));
	Else
		
		If Upper(DataKind) = "INDEPENDENTREGISTER" Then
			
			XMLWriter.WriteStartElement("Filter");
			For Each FilterElement In Data.Filter Do
				
				If ValueIsFilled(FilterElement.Value) Then
					XMLWriter.WriteStartElement(FilterElement.Name);
					
					DataType = TypeOf(FilterElement.Value);
					MetadataObject =  Metadata.FindByType(DataType);
					
					If MetadataObject <> Undefined Then
						XMLWriter.WriteAttribute("Type", MetadataObject.FullName());
					ElsIf DataType = Type("UUID") Then
						XMLWriter.WriteAttribute("Type", "UUID");
					Else
						XMLWriter.WriteAttribute("Type", String(DataType));
					EndIf;
					
					XMLWriter.WriteAttribute("Val", XMLString(FilterElement.Value));
					XMLWriter.WriteEndElement();
				EndIf;
				
			EndDo;
			XMLWriter.WriteEndElement();
			
		Else
			Recorder = Data.Filter.Recorder.Value;
			XMLWriter.WriteAttribute("FilterType", String(Recorder.Metadata().FullName()));
			XMLWriter.WriteAttribute("Ref",        XMLString(Recorder.Ref));
		EndIf;
		
	EndIf;
	
	XMLWriter.WriteEndElement();

EndProcedure

// Performs registration in the subordinate rib node with filters
// of objects registered for deferred update in the main rib node.
//
Procedure ProcessDataToUpdateInSubordinateNode(Val ConstantValue) Export
	
	If Not StandardSubsystemsCached.DIBUsed("WithFilter")
		Or Not IsSubordinateDIBNode()
		Or ExchangePlanPurpose(MasterNode().Metadata().Name) <> "DIBWithFilter" Then
		Return;
	EndIf;
	
	ArrayOfValues = ConstantValue.Value.Get();
	If TypeOf(ArrayOfValues) <> Type("Array") Then
		Return;
	EndIf;
	
	For Each ValueStorage In ArrayOfValues Do
		FileName = FullNameOfFileOfDeferredUpdateData();
		
		If ValueStorage = Undefined Then
			Return;
		EndIf;
		
		BinaryData = ValueStorage.Get(); // BinaryData
		If BinaryData = Undefined Then
			Return;
		EndIf;
		
		If Common.IsSubordinateDIBNode() Then
			Query = New Query;
			Query.Text = 
			"SELECT
			|	InfobaseUpdate.Ref AS Node
			|FROM
			|	ExchangePlan.InfobaseUpdate AS InfobaseUpdate
			|WHERE
			|	NOT InfobaseUpdate.ThisNode";
			
			Selection = Query.Execute().Select();
			While Selection.Next() Do
				ExchangePlans.DeleteChangeRecords(Selection.Node);
			EndDo;
		EndIf;
		
		BinaryData.Write(FileName);
		
		XMLReader = New FastInfosetReader;
		XMLReader.OpenFile(FileName);
		
		HandlerParametersStructure = InfobaseUpdate.MainProcessingMarkParameters();
		
		While XMLReader.Read() Do
			
			If XMLReader.Name = "Object"
				And XMLReader.NodeType = XMLNodeType.StartElement Then
				
				HandlerParametersStructure.Queue = Number(XMLReader.AttributeValue("Queue"));
				FullMetadataObjectName            = TrimAll(XMLReader.AttributeValue("Type"));
				MetadataObjectType                  = Metadata.FindByFullName(FullMetadataObjectName);
				ObjectManager                       = Common.ObjectManagerByFullName(FullMetadataObjectName);
				IsReferenceObjectType                = Common.IsRefTypeObject(MetadataObjectType);
				
				If IsReferenceObjectType Then
					ObjectToProcess1 = ObjectManager.GetRef(New UUID(XMLReader.AttributeValue("Ref")));
				Else
					
					ObjectToProcess1 = ObjectManager.CreateRecordSet();
					
					If Common.IsInformationRegister(MetadataObjectType)
						And MetadataObjectType.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
						
						XMLReader.Read();
						
						If XMLReader.Name = "Filter"
							And XMLReader.NodeType = XMLNodeType.StartElement Then
							
							WritingFilter = True;
							
							While WritingFilter Do
								
								XMLReader.Read();
								
								If XMLReader.Name = "Filter" And XMLReader.NodeType = XMLNodeType.EndElement Then
									WritingFilter = False;
									Continue;
								ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
									Continue;
								Else
									
									FilterValue = XMLReader.AttributeValue("Val");
									If ValueIsFilled(FilterValue) Then
										
										FilterName         = XMLReader.Name;
										ValueTypeFilter = XMLReader.AttributeValue("Type");
										FilterValueMetadata = Metadata.FindByFullName(ValueTypeFilter);
										
										FilterElement = ObjectToProcess1.Filter.Find(FilterName);
										
										If FilterElement <> Undefined Then
										
											If FilterValueMetadata <> Undefined Then
												
												FilterObjectManager = Common.ObjectManagerByFullName(ValueTypeFilter);
												
												If Common.IsEnum(FilterValueMetadata) Then
													ValueRef = FilterObjectManager[FilterValue];
												Else
													ValueRef = FilterObjectManager.GetRef(New UUID(FilterValue));
												EndIf;
												
												FilterElement.Set(ValueRef);
												
											Else
												If Upper(StrReplace(ValueTypeFilter, " ", "")) = "UUID" Then
													FilterElement.Set(XMLValue(Type("UUID"), FilterValue));
												Else
													FilterElement.Set(XMLValue(Type(ValueTypeFilter), FilterValue));
												EndIf;
											EndIf;
											
										EndIf;
										
									EndIf;
									
								EndIf;
								
							EndDo;
							
						EndIf;
						
					Else
						
						RecorderValue  = New UUID(XMLReader.AttributeValue("Ref"));
						FullRecorderName = XMLReader.AttributeValue("FilterType");
						RecorderManager  = Common.ObjectManagerByFullName(FullRecorderName);
						RecorderRef   = RecorderManager.GetRef(RecorderValue);
						DataExchangeInternal.SetFilterItemValue(ObjectToProcess1.Filter, "Recorder", RecorderRef);
						
					EndIf;
					
					ObjectToProcess1.Read();
					
				EndIf;
				
				InfobaseUpdate.MarkForProcessing(HandlerParametersStructure, ObjectToProcess1);
				
			Else
				Continue;
			EndIf;
			
		EndDo;
		
		XMLReader.Close();
		
		File = New File(FileName);
		If File.Exists() Then
			DeleteFiles(FileName);
		EndIf;
	EndDo;
	
EndProcedure

// Closes an XML file with recorded information about objects
// registered for deferred update.
//
Procedure CompleteWriteUpdateDataFile(Parameters) Export
	
	UpdateData = CompleteWriteFileAndGetUpdateData(Parameters);
	
	If UpdateData <> Undefined Then
		SaveUpdateData(UpdateData, Parameters.NameOfChangedFile);
	EndIf;
	
EndProcedure

// Closes an XML file with recorded information about objects
// registered for deferred update and returns the contents of the file.
//
// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
// Returns:
//  ValueStorage -  file contents.
//
Function CompleteWriteFileAndGetUpdateData(Parameters) Export
	
	If Not StandardSubsystemsCached.DIBUsed("WithFilter")
		Or Common.IsSubordinateDIBNode() Then
		Return Undefined;
	EndIf;
	
	If Parameters.WriteChangesForSubordinateDIBNodeWithFilters = Undefined Then
		ExceptionText = NStr("en = 'The processing of the data registration parameters in the handler is poorly arranged.';");
		Raise ExceptionText;
	EndIf;
	
	XMLWriter = Parameters.WriteChangesForSubordinateDIBNodeWithFilters;
	XMLWriter.WriteEndElement();
	XMLWriter.Close();
	
	NameOfChangedFile = Parameters.NameOfChangedFile;
	FileBinaryData = New BinaryData(NameOfChangedFile);
	
	Return New ValueStorage(FileBinaryData, New Deflation(9));
	
EndFunction

// Saves the contents of the file from finalrecordfile and get update Data()
// to the data constant for the delayed Update.
//
// Parameters:
//  UpdateData - ValueStorage -  file contents.
//  NameOfChangedFile - String -  name of the file where the data was stored.
//
Procedure SaveUpdateData(UpdateData, NameOfChangedFile) Export
	
	If NameOfChangedFile = Undefined Then
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		Block.Add("Constant.DataForDeferredUpdate");
		Block.Lock();
		
		ConstantValue = Constants.DataForDeferredUpdate.Get().Get();
		If TypeOf(ConstantValue) <> Type("Array") Then
			ConstantValue = New Array;
		EndIf;
		
		ConstantValue.Add(UpdateData);

		Constants.DataForDeferredUpdate.Set(New ValueStorage(ConstantValue));
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	FileWithData = New File(NameOfChangedFile);
	If FileWithData.Exists() Then
		DeleteFiles(NameOfChangedFile);
	EndIf;
	
EndProcedure

// Resets the value of the write-change constant for the associated node Filters when updating.
//
Procedure ResetConstantValueWithChangesForSubordinateDIBNodeWithFilters() Export
	
	Constants.DataForDeferredUpdate.Set(Undefined);
	
EndProcedure

// Returns True if the configuration of the subordinate rib node is not completed and
// the program parameters that are not involved in the rib need to be updated.
//
Function SubordinateDIBNodeSetup() Export
	
	SetPrivilegedMode(True);
	
	Return IsSubordinateDIBNode()
	      And Not Constants.SubordinateDIBNodeSetupCompleted.Get();
	
EndFunction

// Updates the rules for converting/registering objects.
// The update is performed for all exchange plans connected to the subsystem.
// Rules are updated only for standard rules.
// If the rules for the exchange plan were downloaded from a file, these rules are not updated.
//
Procedure UpdateDataExchangeRules() Export
	
	// 
	DeleteObsoleteRecordsFromDataExchangeRulesRegister();
	
	If Not Constants.UseDataSynchronization.Get()
		And Not Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	ExchangeRulesImportedFromFile = New Array;
	RegistrationRulesImportedFromFile = New Array;
	
	CheckLoadedFromFileExchangeRulesAvailability(ExchangeRulesImportedFromFile, RegistrationRulesImportedFromFile);
	UpdateStandardDataExchangeRuleVersion(ExchangeRulesImportedFromFile, RegistrationRulesImportedFromFile);
	
EndProcedure

// See DataExchangeCached.TempFilesStorageDirectory
// ()
Function TempFilesStorageDirectory() Export
	
	SafeMode = SafeMode();
	Return DataExchangeCached.TempFilesStorageDirectory(SafeMode);
	
EndFunction

// Checks whether transport processing is enabled according to the specified settings.
//
Procedure CheckExchangeMessageTransportDataProcessorAttachment(Cancel,
		SettingsStructure_, TransportKind, ErrorMessage = "", NewPasswords = Undefined) Export
	
	SetPrivilegedMode(True);
	
	// 
	DataProcessorObject = DataProcessors[DataExchangeMessageTransportDataProcessorName(TransportKind)].Create();
	
	// 
	FillPropertyValues(DataProcessorObject, SettingsStructure_);
	
	Peer = Undefined;
	ThereIsCorrespondent = SettingsStructure_.Property("Peer", Peer)
		Or SettingsStructure_.Property("CorrespondentEndpoint", Peer);
		
	// 
	If ThereIsCorrespondent Then

		ParametersString1 = "COMUserPassword, FTPConnectionPassword, WSPassword, ArchivePasswordExchangeMessages,
			|FTPConnectionDataAreasPassword, ArchivePasswordDataAreaExchangeMessages";
		
		If NewPasswords = Undefined Then
			Passwords = Common.ReadDataFromSecureStorage(Peer, ParametersString1, True);
		Else
			Passwords = New Structure(ParametersString1);
			FillPropertyValues(Passwords, NewPasswords);
		EndIf;
		
		FillPropertyValues(DataProcessorObject, Passwords);
		
		If Common.DataSeparationEnabled()
			And TypeOf(DataProcessorObject) = Type("DataProcessorObject.ExchangeMessageTransportFTP") Then
			DataProcessorObject.FTPConnectionPassword = Passwords.FTPConnectionDataAreasPassword;
			DataProcessorObject.ArchivePasswordExchangeMessages = Passwords.ArchivePasswordDataAreaExchangeMessages;
		EndIf;
		
	EndIf;
	
	// 
	DataProcessorObject.Initialize();
	
	// 
	If Not DataProcessorObject.ConnectionIsSet() Then
		
		Cancel = True;
		
		ErrorMessage = DataProcessorObject.ErrorMessageString
			+ Chars.LF + NStr("en = 'See the event log for details.';");
		
		WriteLogEvent(NStr("en = 'Exchange message transport';", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , DataProcessorObject.ErrorMessageStringEL);
		
	EndIf;
	
EndProcedure

Procedure CheckExchangeManagementRights() Export
	
	If Not HasRightsToAdministerExchanges() Then
		
		Raise NStr("en = 'Insufficient rights to administer data synchronization.';");
		
	EndIf;
	
EndProcedure

// Gets the node of the distributed information base that is the main one for the current information base, provided
// that the distributed information base is created on the basis of the exchange plan served by the BSP data exchange subsystem.
//
// Returns:
//  ПланОбменаСсылка.<ИмяПланаОбмена>, Undefined - 
//   
//   
//   
//   
//
Function MasterNode() Export
	
	Result = ExchangePlans.MasterNode();
	
	If Result <> Undefined Then
		
		If Not DataExchangeCached.IsSSLDataExchangeNode(Result) Then
			
			Result = Undefined;
			
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

Procedure OnContinueSubordinateDIBNodeSetup() Export
	
	SSLSubsystemsIntegration.OnSetUpSubordinateDIBNode();
	DataExchangeOverridable.OnSetUpSubordinateDIBNode();
	
EndProcedure

// Returns whether the user has rights to perform data synchronization.
// Data synchronization can be performed either by a full-fledged user,
// or by a user with the rights of the supplied profile "data Synchronization with other programs".
//
//  Parameters:
// User - InfoBaseUser
//              - Undefined
// The user for whom you want to calculate the attribute for allowing the use of data synchronization.
// If the parameter is not specified, the function is calculated for the current user of the information database.
//
Function DataSynchronizationPermitted(Val User = Undefined) Export
	
	If User = Undefined Then
		User = InfoBaseUsers.CurrentUser();
	EndIf;
	
	If User.Roles.Contains(Metadata.Roles.FullAccess) Then
		Return True;
	EndIf;
	
	ProfileRoles = StrSplit(DataSynchronizationWithOtherApplicationsAccessProfileRoles(), ",");
	For Each Role In ProfileRoles Do
		
		If Not User.Roles.Contains(Metadata.Roles.Find(TrimAll(Role))) Then
			Return False;
		EndIf;
		
	EndDo;
	
	Return True;
EndFunction

// Parameters:
//   Receiver - ValueTable
//            - TabularSection - 
//   Source - ValueTable
//            - TabularSection -  data source.
//
Procedure FillValueTable(Receiver, Val Source) Export
	Receiver.Clear();
	
	If TypeOf(Source)=Type("ValueTable") Then
		SourceColumns = Source.Columns;
	Else
		TempTable_ = Source.Unload(New Array);
		SourceColumns = TempTable_.Columns;
	EndIf;
	
	If TypeOf(Receiver)=Type("ValueTable") Then
		DestinationColumns = Receiver.Columns;
		DestinationColumns.Clear();
		For Each Column In SourceColumns Do
			FillPropertyValues(DestinationColumns.Add(), Column);
		EndDo;
	EndIf;
	
	For Each String In Source Do
		FillPropertyValues(Receiver.Add(), String);
	EndDo;
EndProcedure

Function MessageWithDataForMappingReceived(ExchangeNode) Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
	"SELECT
	|	MessagesForDataMapping.MessageReceivedForDataMapping AS MessageReceivedForDataMapping
	|FROM
	|	#ExchangePlanTable AS ExchangePlanTable
	|		INNER JOIN MessagesForDataMapping AS MessagesForDataMapping
	|		ON (MessagesForDataMapping.InfobaseNode = ExchangePlanTable.Ref)
	|WHERE
	|	ExchangePlanTable.Ref = &ExchangeNode");
	Query.SetParameter("ExchangeNode", ExchangeNode);
	Query.TempTablesManager = New TempTablesManager;
	
	Query.Text = StrReplace(Query.Text, "#ExchangePlanTable", "ExchangePlan." + DataExchangeCached.GetExchangePlanName(ExchangeNode));
	
	GetMessagesToMapData(Query.TempTablesManager);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Return Selection.MessageReceivedForDataMapping;
	EndIf;
	
	Return False;
	
EndFunction

Function ExchangePlanNodeCodeString(Value) Export
	
	If TypeOf(Value) = Type("String") Then
		
		Return TrimAll(Value);
		
	ElsIf TypeOf(Value) = Type("Number") Then
		
		Return Format(Value, "ND=7; NLZ=; NG=0");
		
	EndIf;
	
	Return Value;
EndFunction

// Receives the option of a secured connection.
//
Function SecureConnection(Path) Export
	
	Return ?(Lower(Left(Path, 4)) = "ftps", CommonClientServer.NewSecureConnection(), Undefined);
	
EndFunction

Procedure RegisterDataForInitialExport(InfobaseNode, Data = Undefined, DeleteMapsRegistration = True) Export
	
	SetPrivilegedMode(True);
	
	// 
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	StandardProcessing = True;
	
	DataExchangeOverridable.InitialDataExportChangesRegistration(InfobaseNode, StandardProcessing, Data);
	
	If StandardProcessing Then
		
		If TypeOf(Data) = Type("Array") Then
			
			For Each MetadataObject In Data Do
				
				ExchangePlans.RecordChanges(InfobaseNode, MetadataObject);
				
			EndDo;
			
		Else
			
			ExchangePlans.RecordChanges(InfobaseNode, Data);
			
		EndIf;
		
	EndIf;
	
	If DataExchangeCached.ExchangePlanContainsObject(DataExchangeCached.GetExchangePlanName(InfobaseNode),
		Metadata.InformationRegisters.InfobaseObjectsMaps.FullName())
		And DeleteMapsRegistration Then
		
		ExchangePlans.DeleteChangeRecords(InfobaseNode, Metadata.InformationRegisters.InfobaseObjectsMaps);
		
	EndIf;
	
	// 
	InformationRegisters.CommonInfobasesNodesSettings.SetInitialDataExportFlag(InfobaseNode);
	
EndProcedure

Procedure RegisterOnlyCatalogsForInitialExport(Val InfobaseNode) Export
	
	RegisterDataForInitialExport(InfobaseNode, ExchangePlanCatalogs(InfobaseNode));
	
EndProcedure

Procedure RegisterCatalogsOnlyForInitialBackgroundExport(ProcedureParameters, StorageAddress) Export
	
	RegisterOnlyCatalogsForInitialExport(ProcedureParameters["InfobaseNode"]);
	
EndProcedure

Procedure RegisterAllDataExceptCatalogsForInitialExport(Val InfobaseNode) Export
	
	RegisterDataForInitialExport(InfobaseNode, AllExchangePlanDataExceptCatalogs(InfobaseNode));
	
EndProcedure

Procedure RegisterAllDataExceptCatalogsForInitialBackgroundExport(ProcedureParameters, StorageAddress) Export
	
	RegisterAllDataExceptCatalogsForInitialExport(ProcedureParameters["InfobaseNode"]);
	
EndProcedure

Function DataForThisInfobaseNodeTabularSections(Val ExchangePlanName, CorrespondentVersion = "", SettingID = "") Export
	
	Result = New Structure;
	
	NodeCommonTables = DataExchangeCached.ExchangePlanTabularSections(ExchangePlanName, CorrespondentVersion, SettingID)["AllTablesOfThisInfobase"];
	
	For Each TabularSectionName In NodeCommonTables Do
		
		TableName = TableNameFromExchangePlanTabularSectionFirstAttribute(ExchangePlanName, TabularSectionName);
		
		If Not ValueIsFilled(TableName) Then
			Continue;
		EndIf;
		
		TabularSectionData = New ValueTable;
		TabularSectionData.Columns.Add("Presentation",                 New TypeDescription("String"));
		TabularSectionData.Columns.Add("RefUUID", New TypeDescription("String"));
		
		QueryText =
		"SELECT TOP 1000
		|	ExchangePlanTableName.Ref AS Ref,
		|	ExchangePlanTableName.Presentation AS Presentation
		|FROM
		|	&ExchangePlanTableName AS ExchangePlanTableName
		|
		|WHERE
		|	NOT ExchangePlanTableName.DeletionMark
		|
		|ORDER BY
		|	ExchangePlanTableName.Presentation";
		
		QueryText = StrReplace(QueryText, "&ExchangePlanTableName", TableName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			TableRow = TabularSectionData.Add();
			TableRow.Presentation = Selection.Presentation;
			TableRow.RefUUID = String(Selection.Ref.UUID());
			
		EndDo;
		
		Result.Insert(TabularSectionName, TabularSectionData);
		
	EndDo;
	
	Return Result;
	
EndFunction

Function GetFilterSettingsValues(ExternalConnectionSettingsStructure) Export
	
	Result = New Structure;
	
	// 
	For Each FilterSettings In ExternalConnectionSettingsStructure Do
		
		If TypeOf(FilterSettings.Value) = Type("Structure") Then
			
			ResultNested = New Structure;
			
			For Each Item In FilterSettings.Value Do
				
				If StrFind(Item.Key, "_Key") > 0 Then
					
					Var_Key = StrReplace(Item.Key, "_Key", "");
					
					Array = New Array;
					
					For Each ArrayElement In Item.Value Do
						
						If Not IsBlankString(ArrayElement) Then
							
							Value = ValueFromStringInternal(ArrayElement);
							
							Array.Add(Value);
							
						EndIf;
						
					EndDo;
					
					ResultNested.Insert(Var_Key, Array);
					
				EndIf;
				
			EndDo;
			
			Result.Insert(FilterSettings.Key, ResultNested);
			
		Else
			
			If StrFind(FilterSettings.Key, "_Key") > 0 Then
				
				Var_Key = StrReplace(FilterSettings.Key, "_Key", "");
				
				Try
					If IsBlankString(FilterSettings.Value) Then
						Value = Undefined;
					Else
						Value = ValueFromStringInternal(FilterSettings.Value);
					EndIf;
				Except
					Value = Undefined;
				EndTry;
				
				Result.Insert(Var_Key, Value);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	// 
	For Each FilterSettings In ExternalConnectionSettingsStructure Do
		
		If TypeOf(FilterSettings.Value) = Type("Structure") Then
			
			ResultNested = Result[FilterSettings.Key];
			
			If ResultNested = Undefined Then
				
				ResultNested = New Structure;
				
			EndIf;
			
			For Each Item In FilterSettings.Value Do
				
				If StrFind(Item.Key, "_Key") <> 0 Then
					
					Continue;
					
				ElsIf FilterSettings.Value.Property(Item.Key + "_Key") Then
					
					Continue;
					
				EndIf;
				
				Array = New Array;
				
				For Each ArrayElement In Item.Value Do
					
					Array.Add(ArrayElement);
					
				EndDo;
				
				ResultNested.Insert(Item.Key, Array);
				
			EndDo;
			
		Else
			
			If StrFind(FilterSettings.Key, "_Key") <> 0 Then
				
				Continue;
				
			ElsIf ExternalConnectionSettingsStructure.Property(FilterSettings.Key + "_Key") Then
				
				Continue;
				
			EndIf;
			
			// 
			If TypeOf(FilterSettings.Value) = Type("String")
				And (     StrFind(FilterSettings.Value, "Enum.") <> 0
					Or StrFind(FilterSettings.Value, "Enumeration.") <> 0) Then
				
				Result.Insert(FilterSettings.Key, PredefinedValue(FilterSettings.Value));
				
			Else
				
				Result.Insert(FilterSettings.Key, FilterSettings.Value);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function InfoBaseAdmParams(Val ExchangePlanName, 
									Val NodeCode, 
									ErrorMessage, 
									AdditionalParameters = Undefined) Export 
	
	Result = New Structure;
	
	Result.Insert("ExchangePlanExists",                      False);
	Result.Insert("InfobasePrefix",                 "");
	Result.Insert("DefaultInfobasePrefix",      "");
	Result.Insert("InfobaseDescription",            "");
	Result.Insert("DefaultInfobaseDescription", "");
	Result.Insert("AccountingParametersSettingsAreSpecified",            False);
	Result.Insert("ThisNodeCode",                              "");
	// 
	Result.Insert("ConfigurationVersion",                        Metadata.Version);
	// 
	Result.Insert("NodeExists",                            False);
	// 
	Result.Insert("DataExchangeSettingsFormatVersion",        ModuleDataExchangeCreationWizard().DataExchangeSettingsFormatVersion());
	Result.Insert("UsePrefixesForExchangeSettings",    True);
	Result.Insert("ExchangeFormat",                              "");
	Result.Insert("ExchangePlanName",                            ExchangePlanName);
	Result.Insert("ExchangeFormatVersions",                       New Array);
	Result.Insert("SupportedObjectsInFormat",              Undefined);
	
	Result.Insert("DataSynchronizationSetupCompleted",     False);
	Result.Insert("MessageReceivedForDataMapping",   False);
	Result.Insert("DataMappingSupported",         True);
	
	SetPrivilegedMode(True);
	
	Result.ExchangePlanExists = (Metadata.ExchangePlans.Find(ExchangePlanName) <> Undefined);

	If Not Result.ExchangePlanExists 
		And AdditionalParameters <> Undefined
		And AdditionalParameters.Property("IsXDTOExchangePlan") Then
		
		SettingID = Undefined;
		AdditionalParameters.Property("SettingID", SettingID);
		
		ExchangePlan = FindNameOfExchangePlanThroughUniversalFormat(ExchangePlanName, SettingID);
			
		Result.ExchangePlanExists = ValueIsFilled(ExchangePlan);
		Result.ExchangePlanName = ExchangePlan;
	
	EndIf;
	
	If Not Result.ExchangePlanExists Then
		Return Result;
	EndIf;
	
	ThisNode = ExchangePlans[Result.ExchangePlanName].ThisNode();
	
	ThisNodeProperties = Common.ObjectAttributesValues(ThisNode, "Code, Description");
	
	InfobasePrefix = Undefined;
	DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(InfobasePrefix);
	
	CorrespondentNode = Undefined;
	If ValueIsFilled(NodeCode) Then
		CorrespondentNode = ExchangePlanNodeByCode(Result.ExchangePlanName, NodeCode);
	EndIf;
	
	Result.InfobasePrefix            = GetFunctionalOption("InfobasePrefix");
	Result.DefaultInfobasePrefix = InfobasePrefix;
	
	If Common.SeparatedDataUsageAvailable() Then
		Result.InfobaseDescription = Constants.SystemTitle.Get();
	EndIf;
	If IsBlankString(Result.InfobaseDescription) Then
		Result.InfobaseDescription = ThisNodeProperties.Description;
	EndIf;
	
	Result.NodeExists                       = ValueIsFilled(CorrespondentNode);
	Result.AccountingParametersSettingsAreSpecified       = Result.NodeExists
		And AccountingParametersSettingsAreSet(Result.ExchangePlanName, NodeCode, ErrorMessage);
	Result.ThisNodeCode                         = ThisNodeProperties.Code;
	Result.ConfigurationVersion                   = Metadata.Version;
	
	Result.DefaultInfobaseDescription = ?(Common.DataSeparationEnabled(),
		Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
		
	If DataExchangeCached.IsXDTOExchangePlan(Result.ExchangePlanName) Then
		Result.UsePrefixesForExchangeSettings = 
			Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(ThisNode);
			
		ExchangePlanProperties = ExchangePlanSettingValue(Result.ExchangePlanName, "ExchangeFormatVersions, ExchangeFormat");
		
		Result.ExchangeFormat        = ExchangePlanProperties.ExchangeFormat;
		Result.ExchangeFormatVersions = Common.UnloadColumn(ExchangePlanProperties.ExchangeFormatVersions, "Key", True);
		
		Result.Insert("SupportedObjectsInFormat",
			DataExchangeXDTOServer.SupportedObjectsInFormat(Result.ExchangePlanName, "SendReceive", CorrespondentNode));
	EndIf;
		
	If Result.NodeExists Then
		Result.DataSynchronizationSetupCompleted   = SynchronizationSetupCompleted(CorrespondentNode);
		Result.MessageReceivedForDataMapping = MessageWithDataForMappingReceived(CorrespondentNode);
		Result.DataMappingSupported = ExchangePlanSettingValue(Result.ExchangePlanName,
			"DataMappingSupported", SavedExchangePlanNodeSettingOption(CorrespondentNode));
	EndIf;
			
	Return Result;
	
EndFunction

// Returns True if the configuration of the information base of the subordinate rib node needs to be updated.
// In the main node, it is always False.
// 
// A copy of the General purpose function.You need to update the configuration of the assigned node.
// 
Function UpdateInstallationRequired() Export
	
	Return IsSubordinateDIBNode() 
		And (ConfigurationChanged() Or DataExchangeInternal.LoadExtensionsThatChangeDataStructure());
	
EndFunction

// It is intended for preparing the structure and then passing it to the handler for getting configuration options.
//
// Parameters:
//  CorrespondentName - String -  name of the corresponding configuration.
//  CorrespondentVersion - String -  version of the corresponding configuration.
//  CorrespondentInSaaS - Boolean
//                              - Undefined -  indicates that the correspondent is in the service model.
//
// Returns:
//   Structure:
//     * CorrespondentVersion - String -  version number of the correspondent configuration.
//     * CorrespondentName - String -  name of the correspondent configuration.
//     * CorrespondentInSaaS - Boolean -  True if the correspondent works in the service model.
//
Function ContextParametersOfSettingsOptionsReceipt(CorrespondentName, CorrespondentVersion, CorrespondentInSaaS) Export
	
	Result = New Structure;
	Result.Insert("CorrespondentName",           CorrespondentName);
	Result.Insert("CorrespondentVersion",        CorrespondentVersion);
	Result.Insert("CorrespondentInSaaS", CorrespondentInSaaS);
	
	Return Result;
	
EndFunction

// Returns an empty table of exchange configuration options.
//
// Returns:
//   ValueTable:
//     * SettingID        - String -  ID of the setting.
//     * CorrespondentInSaaS   - Boolean -  True if the exchange setting
//                                                with a correspondent working in the service model is supported.
//     * CorrespondentInLocalMode - Boolean -  True if the exchange setting
//                                                with a correspondent working in local mode is supported.
//
Function ExchangeSettingsOptionsCollection() Export
	
	ExchangeSettingsOptions = New ValueTable;
	ExchangeSettingsOptions.Columns.Add("SettingID",        New TypeDescription("String"));
	ExchangeSettingsOptions.Columns.Add("CorrespondentInSaaS",   New TypeDescription("Boolean"));
	ExchangeSettingsOptions.Columns.Add("CorrespondentInLocalMode", New TypeDescription("Boolean"));
	
	Return ExchangeSettingsOptions;
	
EndFunction

// Getting a file by its ID.
//
// Parameters:
//  FileID - UUID -  ID of the received file.
//  WSPassiveModeFileIB - Boolean -  a sign that the file is received in the file information system when configuring the WS
//                                        connection in passive mode
//
// Returns:
//  ИмяФайла - 
//
Function GetFileFromStorage(Val FileID, WSPassiveModeFileIB = False) Export
	
	FileName = "";
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnReceiveFileFromStorage(FileID, FileName);
		
	Else
		
		OnReceiveFileFromStorage(FileID, FileName);
		
	EndIf;
	
	If WSPassiveModeFileIB Then
		FullFileName = TheFullNameOfTheFileToBeMappedIsFileInformationSystem(FileName);	
	Else
		FullFileName = CommonClientServer.GetFullFileName(TempFilesStorageDirectory(), FileName);	
	EndIf;
	
	Return FullFileName;
	
EndFunction

// Saving file.
//
// Parameters:
//  FileName               - String - 
//  FileID     - UUID -  file identifier. If set,
//                           this value will be used when saving the file, otherwise a new one will be generated.
//
// Returns:
//  UUID -   file identifier.
//
Function PutFileInStorage(Val FileName, Val FileID = Undefined) Export
	
	FileID = ?(FileID = Undefined, New UUID, FileID);
	
	File = New File(FileName);
	
	RecordStructure = New Structure;
	RecordStructure.Insert("MessageID", String(FileID));
	RecordStructure.Insert("MessageFileName", File.Name);
	RecordStructure.Insert("MessageStoredDate", CurrentUniversalDate());
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnPutFileToStorage(RecordStructure);
	Else
		
		OnPutFileToStorage(RecordStructure);
		
	EndIf;
	
	Return FileID;
	
EndFunction

// Structure of the description of standard options for uploading extensions.
//
// Returns:
//   Structure - :
//     * OptionDoNotAdd - See StandardOptionDetailsWithoutAddition
//     * AllDocumentsOption - See StandardOptionDetailsAllDocuments
//     * ArbitraryFilterOption - See StandardOptionDetailsCustomFilter
//     * AdditionalOption - See StandardOptionDetailsMore
//
Function StandardExportAdditionOptionsDetails() Export
	
	Result = New Structure;
	
	Result.Insert("OptionDoNotAdd",     StandardOptionDetailsWithoutAddition());
	Result.Insert("AllDocumentsOption",      StandardOptionDetailsAllDocuments());
	Result.Insert("ArbitraryFilterOption", StandardOptionDetailsCustomFilter());
	Result.Insert("AdditionalOption",     StandardOptionDetailsMore());
	
	Return Result;
	
EndFunction

Procedure CheckWhetherTheExchangeCanBeStarted(ExchangeNode, Cancel) Export
	
	Try
		
		// 
		LockDataForEdit(ExchangeNode);
		UnlockDataForEdit(ExchangeNode);
		
	Except
		
		Cancel = True;
		
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot start an exchange with %1.
			|Data exchange is already in progress. Try again later.';"),
			ExchangeNode);
		
		WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Warning,
			ExchangeNode.Metadata(), ExchangeNode, ErrorMessage);
			
	EndTry;
	
EndProcedure

Function IsTechnicalObject(Val FullObjectName) Export
	
	If StrFind(FullObjectName, Upper("ExchangePlan")) > 0 Then
		
		For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
			
			If StrFind(FullObjectName, Upper(ExchangePlanName)) Then
				Return True;
			EndIf;
			
		EndDo;	
						
	EndIf;
		
	Return False;
	
EndFunction

#EndRegion

#Region WrappersToOperateWithExchangePlanManagerApplicationInterface

Function NodeFiltersSetting(Val ExchangePlanName, Val CorrespondentVersion, SettingID = "") Export
	If IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName, 
								SettingID, CorrespondentVersion);
	
	Result = Undefined;
	If ValueIsFilled(SettingOptionDetails.Filters) Then
		Result = SettingOptionDetails.Filters;
	EndIf;
	
	If Result = Undefined Then
		Result = New Structure;
	EndIf;
	
	Return Result;
EndFunction

Function DataTransferRestrictionsDetails(Val ExchangePlanName, Val Setting, Val CorrespondentVersion, 
										SettingID = "") Export
	If Not HasExchangePlanManagerAlgorithm("DataTransferRestrictionsDetails", ExchangePlanName) Then
		Return "";
	ElsIf IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	
	Return ExchangePlans[ExchangePlanName].DataTransferRestrictionsDetails(Setting, CorrespondentVersion, SettingID);
	
EndFunction

// 
// 
// Parameters:
//  AlgorithmName - String -  name of the procedure / function.
//  ExchangePlanName - String -  name of the exchange plan.
// Returns:
//   Boolean
//
Function HasExchangePlanManagerAlgorithm(AlgorithmName, ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeCached.ExchangePlanSettings(ExchangePlanName);
	
	AlgorithmFound = Undefined;
	ExchangePlanSettings.Algorithms.Property(AlgorithmName, AlgorithmFound);
	
	Return (AlgorithmFound = True);
	
EndFunction

#EndRegion

#Region ProgressBar

// Calculates the upload percentage and writes it as a message to the user.
//
// Parameters:
//  ExportedCount       - Number -  the number of objects currently uploaded.
//  ObjectsToExportCount - Number -  the number of objects to be uploaded.
//
Procedure CalculateExportPercent(ExportedCount, ObjectsToExportCount) Export
	
	// 
	If ExportedCount = 0 Or ExportedCount / 100 <> Int(ExportedCount / 100) Then
		Return;
	EndIf;
	
	If ObjectsToExportCount = 0 Or ExportedCount > ObjectsToExportCount Then
		ProgressPercent = 95;
		Template = NStr("en = '%1 objects processed.';");
		Text = StringFunctionsClientServer.SubstituteParametersToString(Template, Format(ExportedCount, "NZ=0; NG="));
	Else
		// 
		ProgressPercent = Round(Min(ExportedCount * 95 / ObjectsToExportCount, 95));
		Template = NStr("en = '%1 out of %2 objects processed.';");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			Format(ExportedCount, "NZ=0; NG="),
			Format(ObjectsToExportCount, "NZ=0; NG="));
	EndIf;
	
	// 
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataExchange", True);
	
	TimeConsumingOperations.ReportProgress(ProgressPercent, Text, AdditionalParameters);
EndProcedure

// Calculates the download percentage and writes it as a message to the user.
//
// Parameters:
//  ExportedCount1       - Number -  the number of currently loaded objects.
//  ObjectsToImportCount - Number -  the number of objects to load.
//  ExchangeMessageFileSize  - Number -  the size of the exchange message file, in megabytes.
//
Procedure CalculateImportPercent(ExportedCount1, ObjectsToImportCount, ExchangeMessageFileSize) Export
	// 
	If ExportedCount1 = 0 Or ExportedCount1 / 10 <> Int(ExportedCount1 / 10) Then
		Return;
	EndIf;

	If ObjectsToImportCount = 0 Then
		// 
		ProgressPercent = 95;
		Template = NStr("en = '%1 objects processed.';");
		Text = StringFunctionsClientServer.SubstituteParametersToString(Template, Format(ExportedCount1, "NZ=0; NG="));
	Else
		// 
		ProgressPercent = Round(Min(ExportedCount1 * 95 / ObjectsToImportCount, 95));
		
		Template = NStr("en = '%1 out of %2 objects processed.';");
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			Template,
			Format(ExportedCount1, "NZ=0; NG="),
			Format(ObjectsToImportCount, "NZ=0; NG="));
	EndIf;
	
	// 
	If ExchangeMessageFileSize <> 0 Then
		Template = NStr("en = 'Message size: %1 MB';");
		TextAddition = StringFunctionsClientServer.SubstituteParametersToString(Template, ExchangeMessageFileSize);
		Text = Text + " " + TextAddition;
	EndIf;
	
	// 
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("DataExchange", True);
	
	TimeConsumingOperations.ReportProgress(ProgressPercent, Text, AdditionalParameters);

EndProcedure

// Increasing the counter of uploaded objects and calculating the percentage of uploads. Only for rib.
//
// Parameters:
//   Recipient - ExchangePlanObject
//   InitialImageCreating - Boolean
//
Procedure CalculateDIBDataExportPercentage(Recipient, InitialImageCreating) Export
	
	If Recipient = Undefined
		Or Not DataExchangeCached.IsDistributedInfobaseNode(Recipient.Ref) Then
		Return;
	EndIf;
	
	// 
	If Not Recipient.AdditionalProperties.Property("ObjectsToExportCount") Then
		ObjectsToExportCount = 0;
		If InitialImageCreating Then
			ObjectsToExportCount = CalculateObjectsCountInInfobase(Recipient);
		Else
			// 
			CurrentSessionParameter = Undefined;
			SetPrivilegedMode(True);
			Try
				CurrentSessionParameter = SessionParameters.DataSynchronizationSessionParameters.Get();
			Except
				Return;
			EndTry;
			SetPrivilegedMode(False);
			If TypeOf(CurrentSessionParameter) = Type("Map") Then
				SynchronizationData = CurrentSessionParameter.Get(Recipient.Ref);
				If Not (SynchronizationData = Undefined 
					Or TypeOf(SynchronizationData) <> Type("Structure")) Then
					ObjectsToExportCount = SynchronizationData.ObjectsToExportCount;
				EndIf;
			EndIf;
		EndIf;
		Recipient.AdditionalProperties.Insert("ObjectsToExportCount", ObjectsToExportCount);
		Recipient.AdditionalProperties.Insert("ExportedObjectCounter", 1);
		Return; // 
	Else
		If Recipient.AdditionalProperties.Property("ExportedObjectCounter") Then
			Recipient.AdditionalProperties.ExportedObjectCounter = Recipient.AdditionalProperties.ExportedObjectCounter + 1;
		Else
			Return;
		EndIf;
	EndIf;
	
	CalculateExportPercent(Recipient.AdditionalProperties.ExportedObjectCounter,
		Recipient.AdditionalProperties.ObjectsToExportCount);
EndProcedure

// Increasing the counter of loaded objects and calculating the percentage of loading. Only for rib.
//
// Parameters:
//   Sender - ExchangePlanObject
//
Procedure CalculateDIBDataImportPercentage(Sender) Export
	
	If Sender = Undefined
		Or Not DataExchangeCached.IsDistributedInfobaseNode(Sender.Ref) Then
		Return;
	EndIf;
	If Not Sender.AdditionalProperties.Property("ObjectsToImportCount")
		Or Not Sender.AdditionalProperties.Property("ExchangeMessageFileSize") Then
		// 
		CurrentSessionParameter = Undefined;
		SetPrivilegedMode(True);
		Try
			CurrentSessionParameter = SessionParameters.DataSynchronizationSessionParameters.Get();
		Except
			Return;
		EndTry;
		SetPrivilegedMode(False);
		If TypeOf(CurrentSessionParameter) = Type("Map") Then
			SynchronizationData = CurrentSessionParameter.Get(Sender.Ref);
			If SynchronizationData = Undefined 
				Or TypeOf(SynchronizationData) <> Type("Structure") Then
				Return;
			EndIf;
			Sender.AdditionalProperties.Insert("ObjectsToImportCount", 
														SynchronizationData.ObjectsToImportCount);
			Sender.AdditionalProperties.Insert("ExchangeMessageFileSize", 
														SynchronizationData.ExchangeMessageFileSize);
		EndIf;
	EndIf;
	If Not Sender.AdditionalProperties.Property("ImportedObjectCounter") Then
		Sender.AdditionalProperties.Insert("ImportedObjectCounter", 1);
	Else
		Sender.AdditionalProperties.ImportedObjectCounter = Sender.AdditionalProperties.ImportedObjectCounter + 1;
	EndIf;
	
	CalculateImportPercent(Sender.AdditionalProperties.ImportedObjectCounter,
		Sender.AdditionalProperties.ObjectsToImportCount,
		Sender.AdditionalProperties.ExchangeMessageFileSize);
	
EndProcedure

// Analyzes data to upload:
// Calculates the number of objects to upload, the size of the exchange message file, and other service data.
// Parameters:
//  ExchangeFileName - String -   the file name of the exchange message.
//  IsXDTOExchange - Boolean -  indicates that the exchange is being performed using a universal format.
// 
// Returns:
//  Structure:
//    * ExchangeMessageFileSize  - Number -  the file size, in megabytes, is 0 by default.
//    * ObjectsToImportCount - Number -  the number of objects to load, by default 0.
//    * From - String -  code of the sending node.
//    * To - String -  code of the recipient node of the message.
//    * NewFrom - String -  code of the sending node in the new format (for converting existing exchanges to the new encoding).
//
Function DataAnalysisResultToExport(Val ExchangeFileName, IsXDTOExchange, IsDIBExchange1 = False) Export
	
	Result = New Structure;
	Result.Insert("ExchangeMessageFileSize", 0);
	Result.Insert("ObjectsToImportCount", 0);
	Result.Insert("From", "");
	Result.Insert("NewFrom", "");
	Result.Insert("To", "");
	
	If Not ValueIsFilled(ExchangeFileName) Then
		Return Result;
	EndIf;
	
	FileWithData = New File(ExchangeFileName);
	If Not FileWithData.Exists() Then
		Return Result;
	EndIf;
	
	ExchangeFile = New XMLReader;
	Try
		// 
		Result.ExchangeMessageFileSize = Round(FileWithData.Size() / 1048576, 1);
		ExchangeFile.OpenFile(ExchangeFileName);
	Except
		Return Result;
	EndTry;
	
	// 
	If IsXDTOExchange Then
		ExchangeFile.Read(); // Message.
		ExchangeFile.Read();  // 
		StartObjectsAccount = False;
		While ExchangeFile.Read() Do
			If ExchangeFile.LocalName = "Header" Then
				// 
				StartObjectsAccount = True;
				ExchangeFile.Skip(); 
			ElsIf ExchangeFile.LocalName = "Confirmation" Then
				ExchangeFile.Read();
			ElsIf ExchangeFile.LocalName = "From" Then
				ExchangeFile.Read();
				Result.From = ExchangeFile.Value;
				ExchangeFile.Skip();
			ElsIf ExchangeFile.LocalName = "To" Then
				ExchangeFile.Read();
				Result.To = ExchangeFile.Value;
				ExchangeFile.Skip();
			ElsIf ExchangeFile.LocalName = "NewFrom" Then
				ExchangeFile.Read();
				Result.NewFrom = ExchangeFile.Value;
				ExchangeFile.Skip();
			ElsIf StartObjectsAccount 
				And ExchangeFile.NodeType = XMLNodeType.StartElement 
				And ExchangeFile.LocalName <> "ObjectDeletion" 
				And ExchangeFile.LocalName <> "Body" Then
				Result.ObjectsToImportCount = Result.ObjectsToImportCount + 1;
				ExchangeFile.Skip();
			EndIf;
		EndDo;

	ElsIf IsDIBExchange1 Then
		ExchangeFile.Read(); // Message.
		ExchangeFile.Read();  // 
		ExchangeFile.Skip(); // 
		ExchangeFile.Read();
		While ExchangeFile.Read() Do
			If ExchangeFile.LocalName = "Changes"
				Or ExchangeFile.LocalName = "Data" Then
				Continue;
			ElsIf StrFind(ExchangeFile.LocalName, "Config") = 0 
				And StrFind(ExchangeFile.LocalName, "Signature") = 0
				And StrFind(ExchangeFile.LocalName, "Nodes") = 0
				And ExchangeFile.LocalName <> "Parameters"
				And ExchangeFile.LocalName <> "Body" Then
				Result.ObjectsToImportCount = Result.ObjectsToImportCount + 1;
			EndIf;
			ExchangeFile.Skip();
		EndDo;	
	Else
		
		ExchangeFile.Read(); // 
		ExchangeFile.Read();  // 
		ExchangeFile.Skip(); // 

		ExchangeFile.Read();  // 
		ExchangeFile.Skip(); // 

		ExchangeFile.Read();  // 
		ExchangeFile.Skip(); // 
		While ExchangeFile.Read() Do
			If ExchangeFile.LocalName = "Object"
				Or ExchangeFile.LocalName = "RegisterRecordSet"
				Or ExchangeFile.LocalName = "ObjectDeletion"
				Or ExchangeFile.LocalName = "ObjectRegistrationInformation" Then
				Result.ObjectsToImportCount = Result.ObjectsToImportCount + 1;
			EndIf;
			ExchangeFile.Skip();
		EndDo;
	EndIf;
	ExchangeFile.Close();
	
	Return Result;
EndFunction

#EndRegion

#Region OperationsWithFTPConnectionObject

Function FTPConnection(Val Settings) Export
	
	Return New FTPConnection(
		Settings.Server,
		Settings.Port,
		Settings.UserName,
		Settings.UserPassword,
		ProxyServerSettings(Settings.SecureConnection),
		Settings.PassiveConnection,
		Settings.Timeout,
		Settings.SecureConnection);
	
EndFunction

Function FTPConnectionSetup(Val Timeout = 180) Export
	
	Result = New Structure;
	Result.Insert("Server", "");
	Result.Insert("Port", 21);
	Result.Insert("UserName", "");
	Result.Insert("UserPassword", "");
	Result.Insert("PassiveConnection", False);
	Result.Insert("Timeout", Timeout);
	Result.Insert("SecureConnection", Undefined);
	
	Return Result;
EndFunction

// Returns the server name and path on the FTP server obtained from the connection string to the FTP resource.
//
// Parameters:
//  StringForConnection - String -  connection string for the FTP resource.
// 
// Returns:
//  Structure - :
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
Function FTPServerNameAndPath(Val StringForConnection) Export
	
	Result = New Structure("Server, Path");
	StringForConnection = TrimAll(StringForConnection);
	
	If (Upper(Left(StringForConnection, 6)) <> "FTP://"
		And Upper(Left(StringForConnection, 7)) <> "FTPS://")
		Or StrFind(StringForConnection, "@") <> 0 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The FTP connection string has invalid format: ""%1""';"), StringForConnection);
	EndIf;
	
	ConnectionParameters = StrSplit(StringForConnection, "/");
	
	If ConnectionParameters.Count() < 3 Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The server name is missing from the FTP connection string: ""%1""';"), StringForConnection);
	EndIf;
	
	Result.Server = ConnectionParameters[2];
	
	ConnectionParameters.Delete(0);
	ConnectionParameters.Delete(0);
	ConnectionParameters.Delete(0);
	
	ConnectionParameters.Insert(0, "@");
	
	If Not IsBlankString(ConnectionParameters.Get(ConnectionParameters.UBound())) Then
		
		ConnectionParameters.Add("@");
		
	EndIf;
	
	Result.Path = StrConcat(ConnectionParameters, "/");
	Result.Path = StrReplace(Result.Path, "@", "");
	
	Return Result;
EndFunction

Function OpenDataExchangeCreationWizardForSubordinateNodeSetup() Export
	
	Return Not Common.DataSeparationEnabled()
		And Not IsStandaloneWorkplace()
		And IsSubordinateDIBNode()
		And Not Constants.SubordinateDIBNodeSetupCompleted.Get();
	
EndFunction

#EndRegion

#Region SecurityProfiles

Function RequestToUseExternalResourcesOnEnableExchange() Export
	
	Queries = New Array();
	CreateRequestsToUseExternalResources(Queries);
	Return Queries;
	
EndFunction

Function RequestToClearPermissionsToUseExternalResources() Export
	
	Queries = New Array;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		QueryText =
		"SELECT
		|	ExchangePlan.Ref AS Node
		|FROM
		|	ExchangePlan.[ExchangePlanName] AS ExchangePlan";
		
		QueryText = StrReplace(QueryText, "[ExchangePlanName]", ExchangePlanName);
		
		Query = New Query;
		Query.Text = QueryText;
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			Queries.Add(ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(Selection.Node));
			
		EndDo;
		
	EndDo;
	
	Queries.Add(ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(
		Common.MetadataObjectID(Metadata.Constants.DataExchangeMessageDirectoryForLinux)));
	Queries.Add(ModuleSafeModeManager.RequestToClearPermissionsToUseExternalResources(
		Common.MetadataObjectID(Metadata.Constants.DataExchangeMessageDirectoryForWindows)));
	
	Return Queries;
	
EndFunction

#EndRegion

#Region Other

Function NodeIDForExchange(ExchangeNode) Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeNode);
	
	NodeCode = TrimAll(Common.ObjectAttributeValue(ExchangePlans[ExchangePlanName].ThisNode(), "Code"));
	
	If DataExchangeCached.IsSeparatedSSLDataExchangeNode(ExchangeNode) Then

		NodePrefixes = InformationRegisters.CommonInfobasesNodesSettings.NodePrefixes(ExchangeNode);
		ThisNodePrefix = TrimAll(NodePrefixes.Prefix);
		
		If Not IsBlankString(ThisNodePrefix)
			And StrLen(NodeCode) <= 2 Then
			// 
			// 
			NodeCode = ThisNodePrefix;
		EndIf;
		
	EndIf;
	
	Return NodeCode;
	
EndFunction

Function CorrespondentNodeIDForExchange(ExchangeNode) Export
	
	NodeCode = TrimAll(Common.ObjectAttributeValue(ExchangeNode, "Code"));
	
	If DataExchangeCached.IsSeparatedSSLDataExchangeNode(ExchangeNode) Then
		NodePrefixes = InformationRegisters.CommonInfobasesNodesSettings.NodePrefixes(ExchangeNode);
		
		If StrLen(NodeCode) <= 2
			And Not IsBlankString(NodePrefixes.CorrespondentPrefix) Then
			// 
			// 
			NodeCode = TrimAll(NodePrefixes.CorrespondentPrefix);
		EndIf;
	EndIf;
	
	Return NodeCode;
	
EndFunction

// Determines whether the BSP exchange plan is split.
//
// Parameters:
//  ExchangePlanName - String -  name of the exchange plan being checked.
//
// Returns:
//  Type - Boolean
//
Function IsSeparatedSSLExchangePlan(Val ExchangePlanName) Export
	
	Return DataExchangeCached.SeparatedSSLExchangePlans().Find(ExchangePlanName) <> Undefined;
	
EndFunction

// 
// 
// 
//
Function SelectChanges(Val Node, Val MessageNo, Val SelectionFilter = Undefined) Export
	
	If TransactionActive() Then
		Raise NStr("en = 'Cannot select data changes in an active transaction.';");
	EndIf;
	
	Return ExchangePlans.SelectChanges(Node, MessageNo, SelectionFilter);
EndFunction

Function WSParameterStructure() Export
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("WSWebServiceURL");
	ParametersStructure.Insert("WSUserName");
	ParametersStructure.Insert("WSPassword");
	
	Return ParametersStructure;
	
EndFunction

Function DataExchangeMonitorTable(Val Var_ExchangePlans, Val AdditionalExchangePlanProperties = "") Export
	
	QueryText = 
		"SELECT
		|	ExchangePlans.InfobaseNode AS InfobaseNode,
		|	&AdditionalExchangePlanProperties AS AdditionalExchangePlanProperties,
		|	ISNULL(DataExchangeStatesExport.ExchangeExecutionResult, 0) AS LastDataExportResult,
		|	ISNULL(DataExchangeStatesImport.ExchangeExecutionResult, 0) AS LastDataImportResult,
		|	ISNULL(DataExchangeStatesImport.StartDate, DATETIME(1, 1, 1)) AS LastImportStartDate,
		|	ISNULL(DataExchangeStatesImport.EndDate, DATETIME(1, 1, 1)) AS LastImportEndDate,
		|	ISNULL(DataExchangeStatesExport.StartDate, DATETIME(1, 1, 1)) AS LastExportStartDate,
		|	ISNULL(DataExchangeStatesExport.EndDate, DATETIME(1, 1, 1)) AS LastExportEndDate,
		|	ISNULL(SuccessfulDataExchangeStatesImport.EndDate, DATETIME(1, 1, 1)) AS LastSuccessfulExportEndDate,
		|	ISNULL(SuccessfulDataExchangeStatesExport.EndDate, DATETIME(1, 1, 1)) AS LastSuccessfulImportEndDate,
		|	CASE
		|		WHEN DataSynchronizationScenarios.InfobaseNode IS NULL
		|			THEN 0
		|		ELSE 1
		|	END AS ScheduleConfigured,
		|	ISNULL(CommonInfobasesNodesSettings.CorrespondentVersion, 0) AS CorrespondentVersion,
		|	ISNULL(CommonInfobasesNodesSettings.CorrespondentPrefix, """") AS CorrespondentPrefix,
		|	ISNULL(CommonInfobasesNodesSettings.SettingCompleted, FALSE) AS SettingCompleted,
		|	ISNULL(CommonInfobasesNodesSettings.MigrationToWebService_Step, 0) AS MigrationToWebService_Step,
		|	ISNULL(CommonInfobasesNodesSettings.TransportKind, """") AS TransportKind,
		|	ISNULL(CommonInfobasesNodesSettings.SynchronizationIsUnavailable, FALSE) AS SynchronizationIsUnavailable,
		|	CASE
		|		WHEN ISNULL(DataExchangeStatesExport.ExchangeExecutionResult, 0) = 0
		|				AND ISNULL(DataExchangeStatesImport.ExchangeExecutionResult, 0) = 0
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS HasErrors,
		|	ISNULL(MessagesForDataMapping.MessageReceivedForDataMapping, FALSE) AS MessageReceivedForDataMapping,
		|	ISNULL(MessagesForDataMapping.LastMessageStoragePlacementDate, DATETIME(1, 1, 1)) AS DataMapMessageDate
		|FROM
		|	ConfigurationExchangePlans AS ExchangePlans
		|		LEFT JOIN CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
		|		ON (CommonInfobasesNodesSettings.InfobaseNode = ExchangePlans.InfobaseNode)
		|		LEFT JOIN DataExchangeStatesImport AS DataExchangeStatesImport
		|		ON (DataExchangeStatesImport.InfobaseNode = ExchangePlans.InfobaseNode)
		|		LEFT JOIN DataExchangeStatesExport AS DataExchangeStatesExport
		|		ON (DataExchangeStatesExport.InfobaseNode = ExchangePlans.InfobaseNode)
		|		LEFT JOIN SuccessfulDataExchangeStatesImport AS SuccessfulDataExchangeStatesImport
		|		ON (SuccessfulDataExchangeStatesImport.InfobaseNode = ExchangePlans.InfobaseNode)
		|		LEFT JOIN SuccessfulDataExchangeStatesExport AS SuccessfulDataExchangeStatesExport
		|		ON (SuccessfulDataExchangeStatesExport.InfobaseNode = ExchangePlans.InfobaseNode)
		|		LEFT JOIN DataSynchronizationScenarios AS DataSynchronizationScenarios
		|		ON (DataSynchronizationScenarios.InfobaseNode = ExchangePlans.InfobaseNode)
		|		LEFT JOIN MessagesForDataMapping AS MessagesForDataMapping
		|		ON (MessagesForDataMapping.InfobaseNode = ExchangePlans.InfobaseNode)
		|
		|ORDER BY
		|	ExchangePlans.Description";
		
	QueryText = StrReplace(QueryText, "&AdditionalExchangePlanProperties AS AdditionalExchangePlanProperties,",
		AdditionalExchangePlanPropertiesAsString(AdditionalExchangePlanProperties));
		
	Query = New Query(QueryText);	
	TempTablesManager = New TempTablesManager;
	Query.TempTablesManager = TempTablesManager;
	
	SetPrivilegedMode(True);
	GetDataExchangeScriptsForMonitor(TempTablesManager);
	GetExchangePlansForDashboard(TempTablesManager, Var_ExchangePlans, AdditionalExchangePlanProperties);
	GetExchangeResultsForMonitor(TempTablesManager);
	GetDataExchangesStates(TempTablesManager);
	GetMessagesToMapData(TempTablesManager);
	GetCommonInfobasesNodesSettings(TempTablesManager);
	
	SynchronizationSettings = Query.Execute().Unload();
	
	SynchronizationSettings.Columns.Add("DataExchangeOption", New TypeDescription("String"));
	SynchronizationSettings.Columns.Add("ExchangePlanName",       New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("LastRunDate", New TypeDescription("Date"));
	SynchronizationSettings.Columns.Add("LastStartDatePresentation", New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("LastImportDatePresentation", New TypeDescription("String"));
	SynchronizationSettings.Columns.Add("LastExportDatePresentation", New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("LastSuccessfulImportDatePresentation", New TypeDescription("String"));
	SynchronizationSettings.Columns.Add("LastSuccessfulExportDatePresentation", New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("MessageDatePresentationForDataMapping", New TypeDescription("String"));
	
	SynchronizationSettings.Columns.Add("CanMigrateToWS", New TypeDescription("Boolean"));
	
	For Each SyncSetup In SynchronizationSettings Do
		
		SyncSetup.LastRunDate = Max(SyncSetup.LastImportStartDate,
			SyncSetup.LastExportStartDate);
		SyncSetup.LastStartDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastRunDate);
		
		SyncSetup.LastImportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastImportEndDate);
		SyncSetup.LastExportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastExportEndDate);
		SyncSetup.LastSuccessfulImportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastSuccessfulExportEndDate);
		SyncSetup.LastSuccessfulExportDatePresentation = RelativeSynchronizationDate(
			SyncSetup.LastSuccessfulImportEndDate);
		
		SyncSetup.MessageDatePresentationForDataMapping = RelativeSynchronizationDate(
			ToLocalTime(SyncSetup.DataMapMessageDate));
		
		SyncSetup.DataExchangeOption = DataExchangeOption(SyncSetup.InfobaseNode);
		SyncSetup.ExchangePlanName = DataExchangeCached.GetExchangePlanName(SyncSetup.InfobaseNode);
		
		If Common.DataSeparationEnabled()
			And SyncSetup.SettingCompleted = True
			And DataExchangeCached.IsXDTOExchangePlan(SyncSetup.InfobaseNode) = True
			And SyncSetup.TransportKind <> Enums.ExchangeMessagesTransportTypes.WS
			And SyncSetup.TransportKind <> Enums.ExchangeMessagesTransportTypes.WSPassiveMode Then
				
			SyncSetup.CanMigrateToWS = True;
				
		EndIf;
		
	EndDo;
	
	Return SynchronizationSettings;
	
EndFunction

Procedure CheckCanSynchronizeData(OnlineApplication = False) Export
	
	If Not AccessRight("View", Metadata.CommonCommands.Synchronize) Then
		
		If OnlineApplication Then
			
			Raise NStr("en = 'Insufficient rights to synchronize data with the web application.';");
			
		Else
			
			Raise NStr("en = 'Insufficient rights to synchronize data.';");
			
		EndIf;
		
	ElsIf InfobaseUpdate.InfobaseUpdateRequired()
		And Not DataExchangeInternal.DataExchangeMessageImportModeBeforeStart("ImportPermitted") Then
			
		If OnlineApplication Then
			
			Raise NStr("en = 'Web application is updating.';");
			
		Else
			
			Raise NStr("en = 'Infobase is updating.';");
			
		EndIf;
		
	ElsIf Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
			
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			DataAreaNumber = ModuleSaaSOperations.SessionSeparatorValue();
			
			SetPrivilegedMode(True);
			
			If ModuleSaaSOperations.DataAreaStatus(DataAreaNumber) <> Enums["DataAreaStatuses"]["Used"] Then
				
				ExceptionText = NStr("en = 'Cannot sync as the data area is marked as inactive.
					|Contact the administrator or technical service.';", Common.DefaultLanguageCode());
				
				GeneralSettingsNodes = InformationRegisters.CommonInfobasesNodesSettings.Select();
				While GeneralSettingsNodes.Next() Do
					
					InformationRegisters.DataExchangeResults.LogAdministratorError(GeneralSettingsNodes.InfobaseNode, ExceptionText);
					
				EndDo;
				
				WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Error, , , ExceptionText);
				Raise ExceptionText;
				
			EndIf;
			
			SetPrivilegedMode(False);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure CheckDataExchangeUsage(SetUsing = False) Export
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		
		If Not Common.DataSeparationEnabled()
			And SetUsing
			And AccessRight("Edit", Metadata.Constants.UseDataSynchronization) Then
			
			Try
				Constants.UseDataSynchronization.Set(True);
			Except
				MessageText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
				WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Error,,,MessageText);
				Raise MessageText;
			EndTry;
			
		Else
			MessageText = NStr("en = 'Synchronization is disabled by the administrator.';");
			WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Error,,,MessageText);
			Raise MessageText;
		EndIf;
		
	EndIf;
	
EndProcedure

Function ExchangeParameters() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("ExchangeMessagesTransportKind", Undefined);
	ParametersStructure.Insert("ExecuteImport1", True);
	ParametersStructure.Insert("ExecuteExport2", True);
	
	ParametersStructure.Insert("ParametersOnly",     False);
	
	ParametersStructure.Insert("TimeConsumingOperationAllowed", False);
	ParametersStructure.Insert("TimeConsumingOperation", False);
	ParametersStructure.Insert("OperationID", "");
	ParametersStructure.Insert("FileID", "");
	ParametersStructure.Insert("AuthenticationParameters", Undefined);
	
	ParametersStructure.Insert("MessageForDataMapping", False);
	
	ParametersStructure.Insert("TheTimeoutOnTheServer", 0);
	
	Return ParametersStructure;
	
EndFunction

//  
Function GetWSProxyByConnectionParameters(
					SettingsStructure_,
					ErrorMessageString = "",
					UserMessage = "",
					ProbingCallRequired = False) Export
	
	WSProxy = DataExchangeWebService.GetWSProxyByConnectionParameters(
					SettingsStructure_,
					ErrorMessageString,
					UserMessage,
					ProbingCallRequired);
	
	Return WSProxy;
	
EndFunction

// Determines whether the exchange plan is included in the list of exchange plans that use data exchange in the XDTO format.
//
// Parameters:
//  ExchangePlan - ExchangePlanRef -  link to the exchange plan node or exchange plan name.
//
// Returns:
//  Boolean - 
//
Function IsXDTOExchangePlan(ExchangePlan) Export
	
	Return DataExchangeCached.IsXDTOExchangePlan(ExchangePlan);
	
EndFunction

// Performs actions to delete the data synchronization setting.
// 
// Parameters:
//   InfobaseNode - ExchangePlanRef -  link to the exchange plan node to delete.
// 
Procedure DeleteSynchronizationSetting(InfobaseNode) Export
	
	CheckExchangeManagementRights();
	
	If Not Common.RefExists(InfobaseNode) Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add(Common.TableNameByRef(InfobaseNode));
		LockItem.SetValue("Ref", InfobaseNode);
		Block.Lock();
		
		Common.DeleteDataFromSecureStorage(InfobaseNode);
		
		LockDataForEdit(InfobaseNode);
		NodeObject = InfobaseNode.GetObject();
		NodeObject.AdditionalProperties.Insert("DeleteSyncSetting");
		NodeObject.Delete();
		
		ExchangePlanName = NodeObject.Metadata().Name;
		DataExchangeLoopControl.UpdateCircuit(ExchangePlanName);
		DataExchangeLoopControl.CheckLooping(ExchangePlanName, "NodeDeletion");

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Performs the procedure to delete configuration data synchronization with the main node of the rib.
// 
// Parameters:
//   InfobaseNode - ExchangePlanRef -  link to the main node.
// 
Procedure DeleteSynchronizationSettingsForMasterDIBNode(InfobaseNode) Export
	
	DeleteSynchronizationSetting(InfobaseNode);
	
	SubordinateDIBNodeSetupCompleted = Constants.SubordinateDIBNodeSetupCompleted.CreateValueManager();
	SubordinateDIBNodeSetupCompleted.Read();
	If SubordinateDIBNodeSetupCompleted.Value Then
		SubordinateDIBNodeSetupCompleted.Value = False;
		InfobaseUpdate.WriteData(SubordinateDIBNodeSetupCompleted);
	EndIf;
	
EndProcedure

// Sets the value of the "Load" parameter for the object's "Tricked" property.
//
// Parameters:
//  Object - Arbitrary -  the object for which the property is set.
//  Value - Boolean -  the value of the "Upload" property to set.
//  SendBack - Boolean -  indicates whether data needs to be registered for sending back.
//  ExchangeNode - ExchangePlanRef -  indicates whether data needs to be registered for sending back.
//
Procedure SetDataExchangeLoad(Object, Value = True, SendBack = False, ExchangeNode = Undefined) Export
	
	Object.DataExchange.Load = Value;
	
	If Not SendBack
		And ExchangeNode <> Undefined
		And Not ExchangeNode.IsEmpty() Then
	
		ObjectValueType = TypeOf(Object);
		MetadataObject = Metadata.FindByType(ObjectValueType);
		
		If Metadata.ExchangePlans[ExchangeNode.Metadata().Name].Content.Contains(MetadataObject) Then
			Object.DataExchange.Sender = ExchangeNode;
		EndIf;
	
	EndIf;
	
EndProcedure

Function ExchangePlanPurpose(ExchangePlanName) Export
	
	Return DataExchangeCached.ExchangePlanPurpose(ExchangePlanName);
	
EndFunction

// The procedure for removal of the existing movements of the document when reposting (cancel conduct).
//
// Parameters:
//   DocumentObject - DocumentObject -  the document whose movements you want to delete.
//
Procedure DeleteDocumentRegisterRecords(DocumentObject) Export
	
	RecordTableRowToProcessArray = New Array;
	
	InsertAnAdditionalParameterForDeletingRegisteredRecords = 
		DocumentObject.AdditionalProperties.Property("DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords")
			And (DocumentObject.AdditionalProperties.DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords = True);
	
	// 
	RegisterRecordTable = DetermineDocumentHasRegisterRecords(DocumentObject.Ref);
	
	For Each RegisterRecordRow In RegisterRecordTable Do
		// 
		// 
		FullRegisterName = RegisterRecordRow.RegisterTableName;
		
		RecordTableRowToProcessArray.Add(RegisterRecordRow);
		
		Set = Common.ObjectManagerByFullName(FullRegisterName).CreateRecordSet();
		
		If Not AccessRight("Update", Set.Metadata()) Then
			// 
			ExceptionText = NStr("en = 'Access rights violation: %1';");
			ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, FullRegisterName);
			Raise ExceptionText;
		EndIf;
		
		DataExchangeInternal.SetFilterItemValue(Set.Filter, "Recorder", DocumentObject.Ref);
		
		// 
		// 
		RegisterRecordRow.RecordSet = Set;
		
	EndDo;
	
	PeriodEndClosingDatesCheckDisabled = PeriodEndClosingDatesCheckDisabled();
	DisablePeriodEndClosingDatesCheck(True);
	Try
		For Each RegisterRecordRow In RecordTableRowToProcessArray Do
			Try
				
				Set = RegisterRecordRow.RecordSet; // 
				If InsertAnAdditionalParameterForDeletingRegisteredRecords Then
					
					Set.AdditionalProperties.Insert("DataSynchronizationViaAUniversalFormatDeletingRegisteredRecords", True);
					
				EndIf;
				
				Set.Write();
				
			Except
				
				// 
				Raise StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Operation failed: %1
					|%2';"),
					RegisterRecordRow.RegisterTableName,
					ErrorProcessing.BriefErrorDescription(ErrorInfo()));
					
			EndTry;
		EndDo;
	Except
		DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
		Raise;
	EndTry;
	DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
	
	For Each Movement In DocumentObject.RegisterRecords Do
		If Movement.Count() > 0 Then
			Movement.Clear();
		EndIf;
	EndDo;
	
	// 
	If DocumentObject.Metadata().SequenceFilling = Metadata.ObjectProperties.SequenceFilling.AutoFill Then
		For Each SequenceRecordSet In DocumentObject.BelongingToSequences Do
			If SequenceRecordSet.Count() > 0 Then
				SequenceRecordSet.Clear();
			EndIf;
		EndDo;
	EndIf;

EndProcedure

// Returns whether the data exchange message needs to be loaded.
//
// Returns:
//   Boolean - 
//
Function LoadDataExchangeMessage() Export
	
	SetPrivilegedMode(True);
	
	Return Constants.LoadDataExchangeMessage.Get();
	
EndFunction

// Initializes columns in the registration rules table by properties.
//
//  Returns:
//    ValueTree
//
Function FilterByExchangePlanPropertiesTableInitialization() Export
	
	Return DataExchangeCached.FilterByExchangePlanPropertiesTableInitialization();

EndFunction

// Initializes columns in the registration rules table by properties.
//
//  Returns:
//    ValueTree
//
Function FilterByObjectPropertiesTableInitialization() Export
	
	Return DataExchangeCached.FilterByObjectPropertiesTableInitialization();

EndFunction

#EndRegion

#Region ConfigurationSubsystemsEventHandlers

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "DataExchangeServer.SetDefaultDataImportTransactionItemsCount";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.SharedData = True;
	Handler.HandlerManagement = True;
	Handler.Version = "*";
	Handler.ExecutionMode = "Seamless";
	Handler.Procedure = "DataExchangeServer.FillSeparatedDataHandlers";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "DataExchangeServer.SetPredefinedNodeCodes";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.Procedure = "DataExchangeServer.SetUpMessageArchivingAutomatedWorkstation";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.1.1";
	Handler.Procedure = "DataExchangeServer.DeleteDataSynchronizationSetupRole";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.2.172";
	Handler.Procedure = "DataExchangeServer.SetDefaultDataImportTransactionItemsCount";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.91";
	Handler.Comment =
		NStr("en = 'Initial population of XDTO data exchange settings.';");
	Handler.Id = New UUID("2ea5ec7e-547b-4e8b-9c3f-d2d8652c8cdf");
	Handler.Procedure = "InformationRegisters.XDTODataExchangeSettings.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToRead = "InformationRegister.XDTODataExchangeSettings";
	Handler.ObjectsToChange = "InformationRegister.XDTODataExchangeSettings";
	Handler.DeferredProcessingQueue = 1;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.XDTODataExchangeSettings.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.XDTODataExchangeSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.281";
	Handler.Comment =
		NStr("en = 'Population of auxiliary data exchange settings in the register ""Common infobase node settings"".';");
	Handler.Id = New UUID("e1cd64f1-3df9-4ea6-8076-1ba0627ba104");
	Handler.Procedure = "InformationRegisters.CommonInfobasesNodesSettings.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToRead = "InformationRegister.CommonInfobasesNodesSettings";
	Handler.ObjectsToChange = "InformationRegister.CommonInfobasesNodesSettings";
	Handler.DeferredProcessingQueue = 1;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.CommonInfobasesNodesSettings.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.CommonInfobasesNodesSettings";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.1.22";
	Handler.Comment =
		NStr("en = 'Moving data exchange results to a new register.';");
	Handler.Id = New UUID("012c28d7-bbe8-494f-87f7-620ffe5c99e2");
	Handler.Procedure = "InformationRegisters.DataExchangeResults.ProcessDataForMigrationToNewVersion";
	Handler.ExecutionMode = "Deferred";
	Handler.ObjectsToRead = "InformationRegister.DeleteDataExchangeResults";
	Handler.ObjectsToChange = "InformationRegister.DeleteDataExchangeResults,InformationRegister.DataExchangeResults";
	Handler.DeferredProcessingQueue = 1;
	Handler.RunAlsoInSubordinateDIBNodeWithFilters = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DataExchangeResults.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock = "InformationRegister.DeleteDataExchangeResults,InformationRegister.DataExchangeResults";
	
EndProcedure

// See InfobaseUpdateSSL.BeforeUpdateInfobase.
Procedure BeforeUpdateInfobase(OnClientStart, Restart) Export
	
	If Common.DataSeparationEnabled() Then
		Return;	
	EndIf;
	
	If Not InfobaseUpdate.InfobaseUpdateRequired() Then
		RunSyncIfInfobaseNotUpdated(OnClientStart, Restart);
	Else	
		ImportMessageBeforeInfobaseUpdate();
	EndIf;

EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase() Export
	
	If Common.DataSeparationEnabled() Then
		Return;
	EndIf;
	
	InformationRegisters.DataSyncEventHandlers.RegisterInfobaseDataUpdate();
	
	ExportMessageAfterInfobaseUpdate();
	
EndProcedure	

// See BatchEditObjectsOverridable.OnDefineObjectsWithEditableAttributes.
Procedure OnDefineObjectsWithEditableAttributes(Objects) Export
	Objects.Insert(Metadata.Catalogs.DataExchangeScenarios.FullName(), "AttributesToSkipInBatchProcessing");
EndProcedure

// See SaaSOperationsOverridable.OnEnableSeparationByDataAreas.
Procedure OnEnableSeparationByDataAreas() Export
	
	If Not Constants.UseDataSynchronization.Get() Then
		Constants.UseDataSynchronization.Set(True);
	EndIf;
	
	UpdateDataExchangeRules();
	
EndProcedure

// See CommonOverridable.OnAddSessionParameterSettingHandlers.
Procedure OnAddSessionParameterSettingHandlers(Handlers) Export
	
	Handlers.Insert("DataExchangeMessageImportModeBeforeStart", "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("ORMCachedValuesRefreshDate",    "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("ObjectsRegistrationRules",                       "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("DataSynchronizationPasswords",                        "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("PriorityExchangeData",                         "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("VersionDifferenceErrorOnGetData",        "DataExchangeInternal.SessionParametersSetting");
	Handlers.Insert("DataSynchronizationSessionParameters",               "DataExchangeInternal.SessionParametersSetting");
	
EndProcedure

// See CommonOverridable.OnDefineSupportedInterfaceVersions.
Procedure OnDefineSupportedInterfaceVersions(Val SupportedVersionsStructure) Export
	
	VersionsArray = New Array;
	VersionsArray.Add("2.0.1.6");
	VersionsArray.Add("2.1.1.7");
	VersionsArray.Add("3.0.1.1");
	VersionsArray.Add("3.0.2.1");
	VersionsArray.Add("3.0.2.2");
	SupportedVersionsStructure.Insert("DataExchange", VersionsArray);
	
EndProcedure

// See CommonOverridable.OnAddClientParametersOnStart.
Procedure OnAddClientParametersOnStart(Parameters) Export
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("DIBExchangePlanName", ?(IsSubordinateDIBNode(), MasterNode().Metadata().Name, ""));
	Parameters.Insert("MasterNode", MasterNode());
	
	If OpenDataExchangeCreationWizardForSubordinateNodeSetup() Then
		
		If Common.SubsystemExists("StandardSubsystems.Interactions") Then
			ModuleInteractions = Common.CommonModule("Interactions");
			ModuleInteractions.PerformCompleteStatesRecalculation();
		EndIf;
		
		Parameters.Insert("OpenDataExchangeCreationWizardForSubordinateNodeSetup");
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	If Parameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup") Then
		
		ThisNode = ExchangePlans[Parameters.DIBExchangePlanName].ThisNode();
		Parameters.Insert("DIBNodeSettingID", SavedExchangePlanNodeSettingOption(ThisNode));
		
	EndIf;
	
	If Not Parameters.Property("OpenDataExchangeCreationWizardForSubordinateNodeSetup")
		And AccessRight("View", Metadata.CommonCommands.Synchronize) Then
		
		Parameters.Insert("CheckSubordinateNodeConfigurationUpdateRequired");
	EndIf;
	
EndProcedure

// See CommonOverridable.OnAddClientParameters.
Procedure OnAddClientParameters(Parameters) Export
	
	SetPrivilegedMode(True);
	
	Parameters.Insert("MasterNode", MasterNode());
	
EndProcedure

// See AccessManagementOverridable.OnFillSuppliedAccessGroupProfiles
Procedure OnFillSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	// 
	ProfileDetails = Common.CommonModule("AccessManagement").NewAccessGroupProfileDescription();
	ProfileDetails.Parent      = "AdditionalProfiles";
	ProfileDetails.Id = DataSynchronizationWithOtherApplicationsAccessProfile();
	ProfileDetails.Description =
		NStr("en = 'Synchronization with other applications';", Common.DefaultLanguageCode());
	ProfileDetails.LongDesc =
		NStr("en = 'The profile is assigned to users that are allowed
		           |to run and monitor data synchronization.';");
	
	// 
	ProfileRoles = StrSplit(DataSynchronizationWithOtherApplicationsAccessProfileRoles(), ",");
	For Each Role In ProfileRoles Do
		ProfileDetails.Roles.Add(TrimAll(Role));
	EndDo;
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

// Parameters:
//   ToDoList - See ToDoListServer.ToDoList.
//
Procedure OnFillToDoList(ToDoList) Export
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		Return;
	EndIf;
	
	OnFillToDoListSynchronizationWarnings(ToDoList);
	OnFillToDoListUpdateRequired(ToDoList);
	OnFillToDoListCheckCompatibilityWithCurrentVersion(ToDoList);
	CheckLoopingWhenFillingOutToDoList(ToDoList);
	
EndProcedure

// See ScheduledJobsOverridable.OnDefineScheduledJobSettings
Procedure OnDefineScheduledJobSettings(Settings) Export
	Dependence = Settings.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.ObsoleteSynchronizationDataDeletion;
	Dependence.FunctionalOption = Metadata.FunctionalOptions.UseDataSynchronization;
	Dependence.UseExternalResources = True;
	
	Dependence = Settings.Add();
	Dependence.ScheduledJob = Metadata.ScheduledJobs.DataSynchronization;
	Dependence.UseExternalResources = True;
	Dependence.IsParameterized = True;
EndProcedure

// See CommonOverridable.OnAddMetadataObjectsRenaming.
Procedure OnAddMetadataObjectsRenaming(Total) Export
	
	Library = "StandardSubsystems";
	
	Common.AddRenaming(
		Total, "2.1.2.5", "Role.ВыполнениеОбменовДанными", "Role.DataSynchronizationInProgress", Library);
	
EndProcedure

// See CommonOverridable.OnAddReferenceSearchExceptions.
Procedure OnAddReferenceSearchExceptions(RefSearchExclusions) Export
	
	RefSearchExclusions.Add(Metadata.InformationRegisters.ObjectsDataToRegisterInExchanges.FullName());
	RefSearchExclusions.Add(Metadata.InformationRegisters.DataExchangeResults.FullName());
	
EndProcedure

// See SafeModeManagerOverridable.OnFillPermissionsToAccessExternalResources.
Procedure OnFillPermissionsToAccessExternalResources(PermissionsRequests) Export
	
	If Not Constants.UseDataSynchronization.Get() Then
		Return;
	EndIf;
	
	CreateRequestsToUseExternalResources(PermissionsRequests);
	
EndProcedure

// See SSLSubsystemsIntegration.OnRegisterExternalModulesManagers
Procedure OnRegisterExternalModulesManagers(Managers) Export
	
	Managers.Add(DataExchangeServer);
	
EndProcedure

// See JobsQueueOverridable.OnDefineHandlerAliases.
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
	
	NamesAndAliasesMap.Insert("DataExchangeServer.ExecuteDataExchangeWithExternalSystem");
	NamesAndAliasesMap.Insert(Metadata.ScheduledJobs.DataSynchronization.MethodName);
	
EndProcedure

// See SSLSubsystemsIntegration.OnDefineObjectsToExcludeFromCheck.
Procedure OnDefineObjectsToExcludeFromCheck(Objects) Export
	Objects.Add(Metadata.InformationRegisters.InfobaseObjectsMaps);
EndProcedure

#EndRegion

#Region PropertyFunctions

// Returns:
//   String
//
Function DataExchangeRulesImportEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.Load rules';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function DataExchangeCreationEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.Create data exchange';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function DataExchangeDeletionEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.Delete data exchange';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function RegisterDataForInitialExportEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.Register data for initial export';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function DataExportToMapEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.Export data for mapping';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function TempFileDeletionEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.Delete temporary file';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function DataExchangeEventLogEvent() Export
	
	Return NStr("en = 'Data exchange';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function ExportDataToFilesTransferServiceEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.File transfer service.Export data';", Common.DefaultLanguageCode());
	
EndFunction

// Returns:
//   String
//
Function ImportDataFromFilesTransferServiceEventLogEvent() Export
	
	Return NStr("en = 'Data exchange.File transfer service.Import data';", Common.DefaultLanguageCode());
	
EndFunction

#EndRegion

#Region ExchangeSettingsStructureInitialization

Function PredefinedNodeAlias(CorrespondentNode) Export
	
	If Not IsXDTOExchangePlan(CorrespondentNode) Then
		Return "";
	EndIf;
	
	Query = New Query(
	"SELECT
	|	PredefinedNodesAliases.NodeCode AS NodeCode
	|FROM
	|	InformationRegister.PredefinedNodesAliases AS PredefinedNodesAliases
	|WHERE
	|	PredefinedNodesAliases.Peer = &InfobaseNode");
	Query.SetParameter("InfobaseNode", CorrespondentNode);
	
	PredefinedNodeAlias = "";
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		PredefinedNodeAlias = TrimAll(Selection.NodeCode);
	EndIf;
	
	Return PredefinedNodeAlias;
	
EndFunction

Function ExchangeSettingsForInfobaseNode(
	InfobaseNode,
	ActionOnExchange,
	ExchangeMessagesTransportKind,
	UseTransportSettings = True) Export
	
	// 
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	ExchangeSettingsStructure.InfobaseNode = InfobaseNode;
	ExchangeSettingsStructure.ActionOnExchange      = ActionOnExchange;
	ExchangeSettingsStructure.ExchangeTransportKind    = ExchangeMessagesTransportKind;
	ExchangeSettingsStructure.IsDIBExchange           = DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode);
	
	InitExchangeSettingsStructureForInfobaseNode(ExchangeSettingsStructure, UseTransportSettings);
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructure);
	
	// 
	CheckExchangeStructure(ExchangeSettingsStructure, UseTransportSettings);
	
	// 
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	If UseTransportSettings Then
		
		// 
		InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure);
		
	EndIf;
	
	// 
	If ExchangeSettingsStructure.IsDIBExchange Then
		
		InitDataExchangeDataProcessor(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
		
		InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure);
		
	EndIf;
	
	Return ExchangeSettingsStructure;
EndFunction

#EndRegion

#Region ToWorkThroughExternalConnections

Function DataExchangeParametersThroughFileOrString() Export
	
	ParametersStructure = New Structure;
	
	ParametersStructure.Insert("InfobaseNode");
	ParametersStructure.Insert("FullNameOfExchangeMessageFile", "");
	ParametersStructure.Insert("ActionOnExchange");
	ParametersStructure.Insert("ExchangePlanName", "");
	ParametersStructure.Insert("InfobaseNodeCode", "");
	ParametersStructure.Insert("ExchangeMessage", "");
	ParametersStructure.Insert("OperationStartDate");
	
	Return ParametersStructure;
	
EndFunction

Procedure ExecuteDataExchangeForInfobaseNodeOverFileOrString(ExchangeParameters) Export
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	If ExchangeParameters.InfobaseNode = Undefined Then
		
		ExchangePlanName = ExchangeParameters.ExchangePlanName;
		InfobaseNodeCode = ExchangeParameters.InfobaseNodeCode;
		
		ExchangeParameters.InfobaseNode = ExchangePlans[ExchangePlanName].FindByCode(InfobaseNodeCode);
			
		If ExchangeParameters.InfobaseNode.IsEmpty()
			And IsXDTOExchangePlan(ExchangePlanName) Then
			MigrationError = False;
			SynchronizationSetupViaCF = ExchangePlans[ExchangePlanName].SwitchingToSynchronizationViaUniversalInternetFormat(
				InfobaseNodeCode, MigrationError);
			If ValueIsFilled(SynchronizationSetupViaCF) Then
				ExchangeParameters.InfobaseNode = SynchronizationSetupViaCF;
			ElsIf MigrationError Then
				ErrorMessageString = NStr("en = 'Cannot switch to Interim Format Data Exchange.';");
				Raise ErrorMessageString;
			EndIf;
		EndIf;
		
		If ExchangeParameters.InfobaseNode.IsEmpty() Then
			ErrorMessageString = NStr("en = 'Node with ID %2 not found. Exchange plan: %1.';");
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(ErrorMessageString, ExchangePlanName, InfobaseNodeCode);
			Raise ErrorMessageString;
		EndIf;
		
	EndIf;
	
	ExecuteExchangeSettingsUpdate(ExchangeParameters.InfobaseNode);
	
	If Not SynchronizationSetupCompleted(ExchangeParameters.InfobaseNode) Then
		
		ApplicationPresentation = ?(Common.DataSeparationEnabled(),
			Metadata.Synonym, DataExchangeCached.ThisInfobaseName());
			
		CorrespondentData = Common.ObjectAttributesValues(ExchangeParameters.InfobaseNode,
			"Code, Description");
		
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The setup of data synchronization with %2 (ID: %3) in %1 is not completed.';"),
			ApplicationPresentation, CorrespondentData.Description, CorrespondentData.Code);
			
		Raise ErrorMessageString;
	EndIf;
	
	// 
	ExchangeSettingsStructure = ExchangeSettingsForInfobaseNode(
		ExchangeParameters.InfobaseNode, ExchangeParameters.ActionOnExchange, Undefined, False);
	If ValueIsFilled(ExchangeParameters.OperationStartDate) Then
		ExchangeSettingsStructure.StartDate = ExchangeParameters.OperationStartDate;
	EndIf;
	RecordExchangeStartInInformationRegister(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.Cancel Then
		ErrorMessageString = NStr("en = 'Cannot initialize data exchange.';");
		WriteExchangeFinish(ExchangeSettingsStructure);
		Raise ErrorMessageString;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	MessageString = NStr("en = 'Data exchange started. Node: %1';", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.DoDataImport Then
		
		TemporaryFileCreated = False;
		If ExchangeParameters.FullNameOfExchangeMessageFile = ""
			And ExchangeParameters.ExchangeMessage <> "" Then
			
			ExchangeParameters.FullNameOfExchangeMessageFile = GetTempFileName(".xml");
			TextFile = New TextDocument;
			TextFile.SetText(ExchangeParameters.ExchangeMessage);
			TextFile.Write(ExchangeParameters.FullNameOfExchangeMessageFile);
			TemporaryFileCreated = True;
		EndIf;
		
		ReadMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeParameters.FullNameOfExchangeMessageFile, ExchangeParameters.ExchangeMessage);
		
		// 
		StandardProcessing = True;
		
		AfterReadExchangeMessage(
					ExchangeSettingsStructure.InfobaseNode,
					ExchangeParameters.FullNameOfExchangeMessageFile,
					ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
					StandardProcessing);
		// 
		
		If TemporaryFileCreated Then
			
			Try
				DeleteFiles(ExchangeParameters.FullNameOfExchangeMessageFile);
			Except
				WriteLogEvent(DataExchangeEventLogEvent(),
					EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndTry;
		EndIf;
		
	ElsIf ExchangeSettingsStructure.DoDataExport Then
		
		WriteMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeParameters.FullNameOfExchangeMessageFile, ExchangeParameters.ExchangeMessage);
		
	EndIf;
	
	WriteExchangeFinish(ExchangeSettingsStructure);
	
	If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		Raise ExchangeSettingsStructure.ErrorMessageString;
	EndIf;
	
EndProcedure

// Writes changes to the database node to a file in the temporary directory.
//
// Parameters:
//  ExchangeSettingsStructure - Structure -  a structure with all the necessary data and objects to perform the exchange.
// 
Procedure WriteMessageWithNodeChanges(ExchangeSettingsStructure, Val ExchangeMessageFileName = "", ExchangeMessage = "") Export
	
	If ExchangeSettingsStructure.IsDIBExchange Then // 
		
		Cancel = False;
		ErrorMessage = "";
		
		// 
		DataExchangeDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor;
		
		// 
		DataExchangeDataProcessor.SetExchangeMessageFileName(ExchangeMessageFileName);
		
		DataExchangeDataProcessor.RunDataExport(Cancel, ErrorMessage);
		
		If Cancel Then
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ExchangeSettingsStructure.ErrorMessageString = ErrorMessage;
			
		EndIf;
		
	Else
		
		// 
		StandardProcessing         = True;
		ProcessedObjectsCount = 0;
		
		Try
			
			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("InfobaseNode",          ExchangeSettingsStructure.InfobaseNode);
			ExecutionParameters.Insert("TransactionItemsCount",  ExchangeSettingsStructure.TransactionItemsCount);
			ExecutionParameters.Insert("EventLogMessageKey", ExchangeSettingsStructure.EventLogMessageKey);
			ExecutionParameters.Insert("ExchangeMessageFileName",         ExchangeMessageFileName);
			
			Handlers = New Array;
			If Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
			    ModuleMessagesExchangeInternal = Common.CommonModule("MessagesExchangeInner");
			    Handlers.Add(ModuleMessagesExchangeInternal);
			EndIf;
			Handlers.Add(DataExchangeOverridable);
			
			OnSSLDataExportHandler(
				Handlers,
			    ExecutionParameters,
			    StandardProcessing,
			    ExchangeMessage,
			    ProcessedObjectsCount);
			
		Except
			
			ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
					ExchangeSettingsStructure.InfobaseNode.Metadata(), 
					ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
			Return;
		EndTry;
		
		If StandardProcessing = False Then
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			Return;
		EndIf;
		// 
		
		// 
		If ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
			
			GenerateExchangeMessage = IsBlankString(ExchangeMessageFileName);
			If GenerateExchangeMessage Then
				ExchangeMessageFileName = GetTempFileName(".xml");
			EndIf;
			
			// 
			DataExchangeXMLDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor; //DataProcessorObject.ConvertXTDOObjects
			DataExchangeXMLDataProcessor.ExchangeFileName = ExchangeMessageFileName;
			
			// 
			Try
				DataExchangeXMLDataProcessor.RunDataExport();
			Except
				ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
				WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
						ExchangeSettingsStructure.InfobaseNode.Metadata(), 
						ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
				Return;
			EndTry;
			
			If GenerateExchangeMessage Then
				TextFile = New TextDocument;
				TextFile.Read(ExchangeMessageFileName, TextEncoding.UTF8);
				ExchangeMessage = TextFile.GetText();
				DeleteFiles(ExchangeMessageFileName);
			EndIf;
			
			ExchangeSettingsStructure.ExchangeExecutionResult = DataExchangeXMLDataProcessor.ExchangeExecutionResult();
			
			// 
			ExchangeSettingsStructure.ProcessedObjectsCount = DataExchangeXMLDataProcessor.ExportedObjectCounter();
			ExchangeSettingsStructure.MessageOnExchange           = DataExchangeXMLDataProcessor.CommentOnDataExport;
			ExchangeSettingsStructure.ErrorMessageString      = DataExchangeXMLDataProcessor.ErrorMessageString();
			
		Else // 
			
			Cancel = False;
			ProcessedObjectsCount = 0;
			
			Try
				ExecuteStandardNodeChangesExport(Cancel,
									ExchangeSettingsStructure.InfobaseNode,
									ExchangeMessageFileName,
									ExchangeMessage,
									ExchangeSettingsStructure.TransactionItemsCount,
									ExchangeSettingsStructure.EventLogMessageKey,
									ProcessedObjectsCount);
			Except
				ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
				WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
						ExchangeSettingsStructure.InfobaseNode.Metadata(), 
						ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
				ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
				Cancel = True;
			EndTry;
			
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			
			If Cancel Then
				
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Receives an exchange message with new data and uploads the data to the information database.
//
// Parameters:
//  ExchangeSettingsStructure - Structure -  a structure with all the necessary data and objects to perform the exchange.
// 
Procedure ReadMessageWithNodeChanges(ExchangeSettingsStructure,
		Val ExchangeMessageFileName = "", ExchangeMessage = "", Val ParametersOnly = False) Export
	
	If ExchangeSettingsStructure.IsDIBExchange Then // 
		
		Cancel = False;
		
		// 
		DataExchangeDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor; //DataProcessorObject.DistributedInfobasesObjectsConversion
		
		// 
		DataExchangeDataProcessor.SetExchangeMessageFileName(ExchangeMessageFileName);
		
		ErrorMessage = "";
		DataExchangeDataProcessor.RunDataImport(Cancel, ParametersOnly, ErrorMessage);
		
		If Cancel Then
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ExchangeSettingsStructure.ErrorMessageString   = ErrorMessage;
		EndIf;
		
	Else
		
		// 
		StandardProcessing         = True;
		ProcessedObjectsCount = 0;
		
		Try
			
			ExecutionParameters = New Structure;
			ExecutionParameters.Insert("InfobaseNode",          ExchangeSettingsStructure.InfobaseNode);
			ExecutionParameters.Insert("TransactionItemsCount",  ExchangeSettingsStructure.TransactionItemsCount);
			ExecutionParameters.Insert("EventLogMessageKey", ExchangeSettingsStructure.EventLogMessageKey);
			ExecutionParameters.Insert("ExchangeMessageFileName",         ExchangeMessageFileName);
			
			Handlers = New Array;
			If Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
				ModuleMessagesExchangeInternal = Common.CommonModule("MessagesExchangeInner");
				Handlers.Add(ModuleMessagesExchangeInternal);
			EndIf;
			Handlers.Add(DataExchangeOverridable);
			
			OnSSLDataImportHandler(
				Handlers,
				ExecutionParameters,
				StandardProcessing,
				ExchangeMessage,
				ProcessedObjectsCount);
			
		Except
			ErrorMessageString = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, EventLogLevel.Error,
					ExchangeSettingsStructure.InfobaseNode.Metadata(), 
					ExchangeSettingsStructure.InfobaseNode, ErrorMessageString);
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ExchangeSettingsStructure.ErrorMessageString = ErrorMessageString;
			Return;
		EndTry;
		
		If StandardProcessing = False Then
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			Return;
		EndIf;
		// 
		
		// 
		If ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
			
			// 
			DataExchangeXMLDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor; //DataProcessorObject.ConvertXTDOObjects
			DataExchangeXMLDataProcessor.ExchangeFileName = ExchangeMessageFileName;
			
			// 
			If DataExchangeCached.IsXDTOExchangePlan(ExchangeSettingsStructure.ExchangePlanName) Then
				ImportParameters = New Structure;
				ImportParameters.Insert("DataExchangeWithExternalSystem",
					ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem);
				
				DataExchangeXMLDataProcessor.RunDataImport(ImportParameters);
				
				DataReceivedForMapping = False;
				If Not DataExchangeXMLDataProcessor.ExchangeComponents.FlagErrors Then
					DataReceivedForMapping = (DataExchangeXMLDataProcessor.ExchangeComponents.IncomingMessageNumber > 0
						And DataExchangeXMLDataProcessor.ExchangeComponents.MessageNumberReceivedByCorrespondent = 0);
				EndIf;
				ExchangeSettingsStructure.AdditionalParameters.Insert("DataReceivedForMapping", DataReceivedForMapping);
			Else
				DataExchangeXMLDataProcessor.RunDataImport();
			EndIf;
			
			ExchangeSettingsStructure.ExchangeExecutionResult = DataExchangeXMLDataProcessor.ExchangeExecutionResult();
			
			// 
			ExchangeSettingsStructure.ProcessedObjectsCount = DataExchangeXMLDataProcessor.ImportedObjectCounter();
			ExchangeSettingsStructure.MessageOnExchange           = DataExchangeXMLDataProcessor.CommentOnDataImport;
			ExchangeSettingsStructure.ErrorMessageString      = DataExchangeXMLDataProcessor.ErrorMessageString();
			
		Else // 
			
			ProcessedObjectsCount = 0;
			ExchangeExecutionResult = Undefined;
			
			ExecuteStandardNodeChangeImport(
				ExchangeSettingsStructure.InfobaseNode,
				ExchangeMessageFileName,
				ExchangeMessage,
				ExchangeSettingsStructure.TransactionItemsCount,
				ExchangeSettingsStructure.EventLogMessageKey,
				ProcessedObjectsCount,
				ExchangeExecutionResult);
			
			ExchangeSettingsStructure.ProcessedObjectsCount = ProcessedObjectsCount;
			ExchangeSettingsStructure.ExchangeExecutionResult = ExchangeExecutionResult;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InteractiveExportChange

// Saves the settings with the specified name according to the data of the upload Add-on.
//
// Parameters:
//     ExportAddition     - Structure
//                            - РеквизитФормыКоллекция - 
//     SettingPresentation - String                            -  name of the saved setting.
//
Procedure InteractiveExportChangeSaveSettings(ExportAddition, Val SettingPresentation) Export
	
	AdditionDataProcessor = DataProcessors.InteractiveExportChange.Create();
	FillPropertyValues(AdditionDataProcessor, ExportAddition, ,
		"AdditionalRegistration, AdditionalNodeScenarioRegistration");
	
	FillValueTable(AdditionDataProcessor.AdditionalRegistration,             ExportAddition.AdditionalRegistration);
	FillValueTable(AdditionDataProcessor.AdditionalNodeScenarioRegistration, ExportAddition.AdditionalNodeScenarioRegistration);
	
	// 
	Data = AdditionDataProcessor.CommonFilterSettingsComposer();
	
	If IsBlankString(ExportAddition.AllDocumentsComposerAddress) Then
		SettingsSource = ExportAddition.AllDocumentsFilterComposer.Settings;
	Else
		ComposerStructure = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress);
		SettingsSource = ComposerStructure.Settings;
	EndIf;
		
	AdditionDataProcessor.AllDocumentsFilterComposer = New DataCompositionSettingsComposer;
	AdditionDataProcessor.AllDocumentsFilterComposer.Initialize( New DataCompositionAvailableSettingsSource(Data.CompositionSchema) );
	AdditionDataProcessor.AllDocumentsFilterComposer.LoadSettings(SettingsSource);
	
	// 
	AdditionDataProcessor.SaveCurrentValuesInSettings(SettingPresentation);
	
	// 
	ExportAddition.CurrentSettingsItemPresentation = SettingPresentation;
	
EndProcedure

// Name for saving and restoring settings for an interactive upload extension.
//
Function ExportAdditionSettingsAutoSavingName() Export
	Return NStr("en = 'Last data sent (autosaved)';");
EndFunction

// Performs additional registration of objects by settings.
//
// Parameters:
//     ExportAddition     - Structure
//                            - FormDataCollection - 
//
Procedure InteractiveExportChangeRegisterAdditionalData(Val ExportAddition) Export
	
	If ExportAddition.ExportOption <= 0 Then
		Return;
	EndIf;
	
	ObjectOfReport = DataProcessors.InteractiveExportChange.Create();
	FillPropertyValues(ObjectOfReport, ExportAddition,,"AdditionalRegistration, AdditionalNodeScenarioRegistration");
		
	If ObjectOfReport.ExportOption=1 Then
		// 
		
	ElsIf ExportAddition.ExportOption=2 Then
		// 
		ObjectOfReport.AllDocumentsFilterComposer = Undefined;
		ObjectOfReport.AllDocumentsFilterPeriod      = Undefined;
		
		FillValueTable(ObjectOfReport.AdditionalRegistration, ExportAddition.AdditionalRegistration);
		
	ElsIf ExportAddition.ExportOption=3 Then
		// 
		ObjectOfReport.ExportOption = 2;
		
		ObjectOfReport.AllDocumentsFilterComposer = Undefined;
		ObjectOfReport.AllDocumentsFilterPeriod      = Undefined;
		
		FillValueTable(ObjectOfReport.AdditionalRegistration, ExportAddition.AdditionalNodeScenarioRegistration);
	EndIf;
	
	ObjectOfReport.RecordAdditionalChanges();
EndProcedure

#EndRegion

#Region Common

// Registers that the exchange was made and records the information in the Protocol.
//
// Parameters:
//  ExchangeSettingsStructure - Structure -  a structure with all the necessary data and objects to perform the exchange.
// 
Procedure WriteExchangeFinish(ExchangeSettingsStructure) Export
	
	// 
	If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed2;
	EndIf;
	
	// 
	If ExchangeSettingsStructure.IsDIBExchange Then
		MessageString = NStr("en = '%1, %2';", Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
							ExchangeSettingsStructure.ExchangeExecutionResult,
							ExchangeSettingsStructure.ActionOnExchange);
	Else
		MessageString = NStr("en = '%1, %2. Objects processed: %3';", Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString,
							ExchangeSettingsStructure.ExchangeExecutionResult,
							ExchangeSettingsStructure.ActionOnExchange,
							ExchangeSettingsStructure.ProcessedObjectsCount);
	EndIf;
	
	ExchangeSettingsStructure.EndDate = CurrentSessionDate();
	
	SetPrivilegedMode(True);
	
	// 
	WriteExchangeFinishToInformationRegister(ExchangeSettingsStructure);
	
	// 
	If ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		
		AddSuccessfulDataExchangeMessageToInformationRegister(ExchangeSettingsStructure);
		
		InformationRegisters.CommonInfobasesNodesSettings.ClearDataSendingFlag(ExchangeSettingsStructure.InfobaseNode);
		
	EndIf;
	
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
EndProcedure

Procedure RecordExchangeStartInInformationRegister(ExchangeSettingsStructure) Export
	
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode",    ExchangeSettingsStructure.InfobaseNode);
	RecordStructure.Insert("ActionOnExchange",         ExchangeSettingsStructure.ActionOnExchange);
	
	RecordStructure.Insert("StartDate",                ExchangeSettingsStructure.StartDate);
	
	InformationRegisters.DataExchangesStates.UpdateRecord(RecordStructure);
	
EndProcedure

// Creates a log entry about the data exchange event/transport of exchange messages.
//
Procedure WriteEventLogDataExchange(Comment, ExchangeSettingsStructure, IsError = False) Export
	
	Level = ?(IsError, EventLogLevel.Error, EventLogLevel.Information);
	
	If ExchangeSettingsStructure.Property("InfobaseNode") Then
		
		WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, 
			Level,
			ExchangeSettingsStructure.InfobaseNode.Metadata(),
			ExchangeSettingsStructure.InfobaseNode,
			Comment);
			
	Else
		WriteLogEvent(ExchangeSettingsStructure.EventLogMessageKey, Level,,, Comment);
	EndIf;
	
EndProcedure

// Returns whether the data exchange was successful.
//
Function ExchangeExecutionResultCompleted(ExchangeExecutionResult) Export
	
	Return ExchangeExecutionResult = Undefined
		Or ExchangeExecutionResult = Enums.ExchangeExecutionResults.Completed2
		Or ExchangeExecutionResult = Enums.ExchangeExecutionResults.CompletedWithWarnings;
	
EndFunction

Function UniqueExchangeMessageFileName(Extension = "xml") Export
	
	Result = "Message{GUID}." + Extension;
	
	Result = StrReplace(Result, "GUID", String(New UUID));
	
	Return Result;
EndFunction

Function FindNameOfExchangePlanThroughUniversalFormat(ExchangePlanName, SettingID) Export
	
	FoundName = DataExchangeFormatTranslationCached.BroadcastName(ExchangePlanName, "en");
	
	If Metadata.ExchangePlans.Find(FoundName) = Undefined Then
		FoundName = "";
	EndIf;
	
	If FoundName = "" Then

		For Each ExchangePlan In DataExchangeCached.SSLExchangePlans() Do
			
			If DataExchangeCached.IsXDTOExchangePlan(ExchangePlan)
				And DataExchangeCached.ThisIsGlobalExchangeThroughUniversalFormat(ExchangePlan) Then
					
				FoundName = ExchangePlan;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	DataExchangeOverridable.WhenSearchingForNameOfExchangePlanThroughUniversalFormat(
		ExchangePlanName, SettingID, FoundName);
		
	Return FoundName;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region GeneralMethodsOfDataConversionMechanisms

Function ModuleDataSynchronizationBetweenWebApplicationsSetupWizard() Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		Return Common.CommonModule("DataProcessors.DataSynchronizationBetweenWebApplicationsSetupWizard");
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ModuleInteractiveDataExchangeWizardSaaS() Export
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		Return Common.CommonModule("DataProcessors.InteractiveDataExchangeWizardSaaS");
	EndIf;
	
	Return Undefined;
	
EndFunction

Function ModuleDataExchangeCreationWizard() Export
	
	Return Common.CommonModule("DataProcessors.DataExchangeCreationWizard");
	
EndFunction

Function ModuleInteractiveDataExchangeWizard() Export
	
	Return Common.CommonModule("DataProcessors.InteractiveDataExchangeWizard");
	
EndFunction

Function PredefinedNodesOfSSLExchangePlans()
	
	Result = New Array;
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		Result.Add(ExchangePlans[ExchangePlanName].ThisNode());
	EndDo;
	
	Return Result;
	
EndFunction

Function PeriodEndClosingDatesCheckDisabled()
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDates = Common.CommonModule("PeriodClosingDates");
		Return ModulePeriodClosingDates.PeriodEndClosingDatesCheckDisabled();
	EndIf;
	
	Return False;
	
EndFunction

Function NewXDTODataExchangeNode(
		ExchangePlanName,
		SettingID,
		CorrespondentID,
		CorrespondentDescription,
		ExchangeFormatVersion)
	
	ManagerExchangePlan = ExchangePlans[ExchangePlanName];
	
	NewNode = ManagerExchangePlan.CreateNode();
	NewNode.Code          = CorrespondentID;
	NewNode.Description = CorrespondentDescription;
	
	If Common.HasObjectAttribute("SettingsMode", Metadata.ExchangePlans[ExchangePlanName]) Then
		NewNode.SettingsMode = SettingID;
	EndIf;
	
	NewNode.ExchangeFormatVersion = ExchangeFormatVersion;
	
	NewNode.Fill(Undefined);
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And IsSeparatedSSLExchangePlan(ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	Return NewNode.Ref;
	
EndFunction

Function ItemsCountInTransactionOfActionToExecute(Action)
	
	If Action = Enums.ActionsOnExchange.DataExport Then
		ItemCount = DataExportTransactionItemsCount();
	Else
		ItemCount = DataImportTransactionItemCount();
	EndIf;
	
	Return ItemCount;
	
EndFunction

Procedure DisablePeriodEndClosingDatesCheck(Disconnect = True)
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates") Then
		ModulePeriodClosingDates = Common.CommonModule("PeriodClosingDates");
		ModulePeriodClosingDates.DisablePeriodEndClosingDatesCheck(Disconnect);
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeSettingsUpdate(InfobaseNode)
	
	If DataExchangeCached.IsMessagesExchangeNode(InfobaseNode) Then
		Return;
	EndIf;
	
	DeleteExchangeTransportSettingsSet = InformationRegisters.DeleteExchangeTransportSettings.CreateRecordSet();
	DeleteExchangeTransportSettingsSet.Filter.InfobaseNode.Set(InfobaseNode);
	DeleteExchangeTransportSettingsSet.Read();
	
	ProcessingState = InfobaseUpdate.ObjectProcessed(DeleteExchangeTransportSettingsSet);
	If Not ProcessingState.Processed Then
		InformationRegisters.DataExchangeTransportSettings.TransferSettingsOfCorrespondentDataExchangeTransport(InfobaseNode);
	EndIf;
	
	CommonInfobasesNodesSettingsSet = InformationRegisters.CommonInfobasesNodesSettings.CreateRecordSet();
	CommonInfobasesNodesSettingsSet.Filter.InfobaseNode.Set(InfobaseNode);
	CommonInfobasesNodesSettingsSet.Read();
	
	If CommonInfobasesNodesSettingsSet.Count() = 0 Then
		InformationRegisters.CommonInfobasesNodesSettings.UpdateCorrespondentCommonSettings(InfobaseNode);
	Else
		ProcessingState = InfobaseUpdate.ObjectProcessed(CommonInfobasesNodesSettingsSet);
		If Not ProcessingState.Processed Then
			InformationRegisters.CommonInfobasesNodesSettings.UpdateCorrespondentCommonSettings(InfobaseNode);
		EndIf;
	EndIf;
	
	If IsXDTOExchangePlan(InfobaseNode) Then
		XDTODataExchangeSettingsSet = InformationRegisters.XDTODataExchangeSettings.CreateRecordSet();
		XDTODataExchangeSettingsSet.Filter.InfobaseNode.Set(InfobaseNode);
		XDTODataExchangeSettingsSet.Read();
		
		If XDTODataExchangeSettingsSet.Count() = 0 Then
			InformationRegisters.XDTODataExchangeSettings.RefreshDataExchangeSettingsOfCorrespondentXDTO(InfobaseNode);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ExecuteDeferredDocumentsPosting(
		DocumentsForDeferredPosting,
		CorrespondentNode,
		AdditionalPropertiesForDeferredPosting = Undefined,
		ExchangeComponents = Undefined) Export
	
	If DocumentsForDeferredPosting.Count() = 0 Then
		Return; // 
	EndIf;
	
	// 
	DocumentsForDeferredPosting.GroupBy("DocumentRef, DocumentDate");
	
	// 
	ObjectOfComparison = New CompareValues;
	DocumentsForDeferredPosting.Sort("DocumentDate, DocumentRef", ObjectOfComparison);
	
	PeriodEndClosingDatesCheckDisabled = PeriodEndClosingDatesCheckDisabled();
	DisablePeriodEndClosingDatesCheck(True);
	Try
		For Each TableRow In DocumentsForDeferredPosting Do
			
			BeginTime = DataExchangeValuationOfPerformance.StartMeasurement();
			
			If TableRow.DocumentRef.IsEmpty() Then
				Continue;
			EndIf;
			
			If Not Common.RefExists(TableRow.DocumentRef) Then
				Continue;
			EndIf;
			
			AdditionalObjectProperties = Undefined;
			If AdditionalPropertiesForDeferredPosting <> Undefined Then
				AdditionalObjectProperties = AdditionalPropertiesForDeferredPosting.Get(TableRow.DocumentRef);
			EndIf;
			
			ExecuteDocumentPostingOnImport(
				CorrespondentNode,
				TableRow.DocumentRef,
				True,
				AdditionalObjectProperties);
				
			If ExchangeComponents <> Undefined Then
				Event = "DelayedExecutionOfDocuments." + TableRow.DocumentRef.Metadata().FullName();
				DataExchangeValuationOfPerformance.FinishMeasurement(
					BeginTime, Event, TableRow.DocumentRef, ExchangeComponents,
					DataExchangeValuationOfPerformance.EventTypeApplied());
			EndIf;
			
		EndDo;
	Except
		DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
		Raise;
	EndTry;
	DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
	
EndProcedure

Procedure ExecuteDocumentPostingOnImport(
		CorrespondentNode,
		DocumentRef,
		RecordIssuesInExchangeResults,
		AdditionalObjectProperties = Undefined) Export
	
	ErrorDescription          = "";
	DocumentPostedSuccessfully = False;
	
	BeginTransaction();
	Try
		Block = New DataLock;
	    LockItem = Block.Add(Common.TableNameByRef(DocumentRef));
	    LockItem.SetValue("Ref", DocumentRef);
	    Block.Lock();
		
		Object = DocumentRef.GetObject();
		
		// 
		// 
		SetDataExchangeLoad(Object, False, False, CorrespondentNode);
		
		If AdditionalObjectProperties <> Undefined Then
			For Each Property In AdditionalObjectProperties Do
				Object.AdditionalProperties.Insert(Property.Key, Property.Value);
			EndDo;
		EndIf;
		
		Object.AdditionalProperties.Insert("DeferredPosting");
		
		If Object.CheckFilling() Then
			
			// 
			// 
			If Object.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
				Object.AdditionalProperties.Delete("DisableObjectChangeRecordMechanism");
			EndIf;
			
			Object.AdditionalProperties.Insert("SkipPeriodClosingCheck");
			
			// 
			Object.Write(DocumentWriteMode.Posting);
			
			DocumentPostedSuccessfully = Object.Posted;
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		DocumentPostedSuccessfully = False;
		
	EndTry;
	
	If Not DocumentPostedSuccessfully Then
		
		RecordDocumentPostingError(
			Object, CorrespondentNode, ErrorDescription, RecordIssuesInExchangeResults);
		
	EndIf;
	
EndProcedure

Procedure ExecuteDeferredObjectsWrite(ObjectsForDeferredPosting, CorrespondentNode, ExchangeComponents = Undefined) Export
	
	If ObjectsForDeferredPosting.Count() = 0 Then
		Return; // 
	EndIf;
	
	PeriodEndClosingDatesCheckDisabled = PeriodEndClosingDatesCheckDisabled();
	DisablePeriodEndClosingDatesCheck(True);
	Try
		For Each MapObject In ObjectsForDeferredPosting Do
			
			BeginTime = DataExchangeValuationOfPerformance.StartMeasurement();
			
			If MapObject.Key.IsEmpty() Then
				Continue;
			EndIf;
			
			If Not Common.RefExists(MapObject.Key) Then
				Continue;
			EndIf;
			
			ErrorDescription       = "";
			ObjectWrittenSuccessfully = False;
			
			BeginTransaction();
			Try
				Block = New DataLock;
				LockItem = Block.Add(Common.TableNameByRef(MapObject.Key));
				LockItem.SetValue("Ref", MapObject.Key);
				Block.Lock();
				
				Object = MapObject.Key.GetObject();
			
				// 
				// 
				SetDataExchangeLoad(Object, False, False, CorrespondentNode);
				
				AdditionalProperties = MapObject.Value;
				
				For Each Property In AdditionalProperties Do
					
					Object.AdditionalProperties.Insert(Property.Key, Property.Value);
					
				EndDo;
				
				Object.AdditionalProperties.Insert("DeferredWriting");
				
				If Object.CheckFilling() Then
					
					// 
					// 
					If Object.AdditionalProperties.Property("DisableObjectChangeRecordMechanism") Then
						Object.AdditionalProperties.Delete("DisableObjectChangeRecordMechanism");
					EndIf;
					
					Object.AdditionalProperties.Insert("SkipPeriodClosingCheck");
					
					// 
					ObjectVersionInfo = Undefined;
					If Object.AdditionalProperties.Property("ObjectVersionInfo", ObjectVersionInfo) Then
						DataExchangeEvents.OnCreateObjectVersion(Object, ObjectVersionInfo, True, CorrespondentNode);
					EndIf;
					Object.Write();
					
					ObjectWrittenSuccessfully = True;
					
				Else
					
					ObjectWrittenSuccessfully = False;
					
					ErrorDescription = NStr("en = 'Attribute filling verification error';");
					
				EndIf;
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
				
				ObjectWrittenSuccessfully = False;
				
			EndTry;
			
			If Not ObjectWrittenSuccessfully Then
				
				RecordObjectWriteError(Object, CorrespondentNode, ErrorDescription);
				
			EndIf;
			
			If ExchangeComponents <> Undefined Then
				Event = "ExecuteDeferredObjectsWrite" + Object.Metadata().FullName();
				DataExchangeValuationOfPerformance.FinishMeasurement(
					BeginTime, Event, Object, ExchangeComponents,
					DataExchangeValuationOfPerformance.EventTypeRule());
			EndIf;
			
		EndDo;
	Except
		DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
		Raise;
	EndTry;
	DisablePeriodEndClosingDatesCheck(PeriodEndClosingDatesCheckDisabled);
	
EndProcedure

Procedure BlockTheExchangeNode(ExchangeNode, Cancel) Export
	
	Try
		
		LockDataForEdit(ExchangeNode);
		
	Except
		
		Cancel = True;
		
		MessageTemplate = NStr("en = 'Cannot lock the exchange plan node [%1].
			|Data exchange is probably already in progress. Try again later.';", Common.DefaultLanguageCode());
		
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ExchangeNode);
		
		WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Error,
			ExchangeNode.Metadata(), ExchangeNode, ErrorMessage);
			
		Raise ErrorMessage;
		
	EndTry;
	
EndProcedure

Procedure BeforePerformingExchanges(InfobaseNode, Cancel)
	
	CheckCanSynchronizeData();
	
	CheckDataExchangeUsage();
	
EndProcedure

Procedure AfterPerformingTheExchanges(InfobaseNode, Cancel)
	
	UnblockTheExchangeNode(InfobaseNode, Cancel);
	
EndProcedure

Procedure UnblockTheExchangeNode(ExchangeNode, Cancel) Export
	
	Try
		
		UnlockDataForEdit(ExchangeNode);
		
	Except
		
		Cancel = True;
		
		MessageTemplate = NStr("en = 'Cannot unlock the exchange plan node [%1].
			|Data exchange is probably already in progress. Try again later.';", Common.DefaultLanguageCode());
		
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ExchangeNode);
		
		WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Error,
			ExchangeNode.Metadata(), ExchangeNode, ErrorMessage);
			
		Raise ErrorMessage;
		
	EndTry;
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

Procedure SetDefaultDataImportTransactionItemsCount() Export
	
	If Not Common.DataSeparationEnabled()
		And DataImportTransactionItemCount() = 0 Then
		SetDataImportTransactionItemsCount(1);
	EndIf;
	
EndProcedure

// Fills in the split data handler that depends on changes to the undivided data.
//
// Parameters:
//   Parameters - Structure - :
//     * SeparatedHandlers - See InfobaseUpdate.NewUpdateHandlerTable
// 
Procedure FillSeparatedDataHandlers(Parameters = Undefined) Export
	
	If Parameters <> Undefined Then
		Handlers = Parameters.SeparatedHandlers;
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "DataExchangeServer.SetPredefinedNodeCodes";
		Handler.ExecutionMode = "Seamless";
	EndIf;
	
EndProcedure

Procedure SetPredefinedNodeCodes() Export
	
	CodeFromSaaSMode = "";
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And Common.SubsystemExists("CloudTechnology.Core")
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleSaaSOperations       = Common.CommonModule("SaaSOperations");
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		
		CodeFromSaaSMode = TrimAll(ModuleDataExchangeSaaS.ExchangePlanNodeCodeInService(ModuleSaaSOperations.SessionSeparatorValue()));
	EndIf;
	
	NodesCollection = New Array;
	For Each NodeRef1 In PredefinedNodesOfSSLExchangePlans() Do
		If Not IsXDTOExchangePlan(NodeRef1) Then
			Continue;
		ElsIf Not DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(NodeRef1) Then
			Continue;
		EndIf;
		
		NodesCollection.Add(NodeRef1);
	EndDo;
	
	BeginTransaction();
	Try
		Block = New DataLock;
		For Each NodeRef1 In NodesCollection Do
			LockItem = Block.Add(Common.TableNameByRef(NodeRef1));
			LockItem.SetValue("Ref", NodeRef1);
		EndDo;
		Block.Lock();
		
		VirtualCodes = InformationRegisters.PredefinedNodesAliases.CreateRecordSet();
		
		For Each NodeRef1 In NodesCollection Do
			
			PredefinedNodeCode = TrimAll(Common.ObjectAttributeValue(NodeRef1, "Code"));
			If Not ValueIsFilled(PredefinedNodeCode)
				// 
				Or StrLen(PredefinedNodeCode) < 36
				// 
				Or PredefinedNodeCode = CodeFromSaaSMode Then
				
				DataExchangeUUID = String(New UUID);
				
				LockDataForEdit(NodeRef1);
				ObjectNode = NodeRef1.GetObject();
				
				ObjectNode.Code = DataExchangeUUID;
				ObjectNode.DataExchange.Load = True;
				ObjectNode.Write();
				
				If ValueIsFilled(PredefinedNodeCode) Then
					// 
					QueryText = 
					"SELECT
					|	T.Ref AS Ref
					|FROM
					|	#ExchangePlanTable AS T
					|WHERE
					|	NOT T.ThisNode
					|	AND NOT T.DeletionMark";
					
					QueryText = StrReplace(QueryText,
						"#ExchangePlanTable", "ExchangePlan." + DataExchangeCached.GetExchangePlanName(NodeRef1));
					
					Query = New Query(QueryText);
					
					ExchangePlanCorrespondents = Query.Execute().Select();
					While ExchangePlanCorrespondents.Next() Do
						VirtualCode = VirtualCodes.Add();
						VirtualCode.Peer = ExchangePlanCorrespondents.Ref;
						VirtualCode.NodeCode       = PredefinedNodeCode;
					EndDo;
				EndIf;
				
			EndIf;
		EndDo;
		
		If VirtualCodes.Count() > 0 Then
			VirtualCodes.Write();
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Deletes the data synchronization Settings role from all profiles that it belongs to.
Procedure DeleteDataSynchronizationSetupRole() Export
	
	If Not Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		Return;
	EndIf;
	
	ModuleAccessManagement = Common.CommonModule("AccessManagement");
	
	NewRoles = New Array;
	RolesToReplace = New Map;
	RolesToReplace.Insert("? DataSynchronizationSetup", NewRoles);
	
	ModuleAccessManagement.ReplaceRolesInProfiles(RolesToReplace);
	
EndProcedure

Procedure SetUpMessageArchivingAutomatedWorkstation() Export
	
	If Not IsStandaloneWorkplace() Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleStandaloneModeInternal = Common.CommonModule("StandaloneModeInternal");
		
		Node = ModuleStandaloneModeInternal.ApplicationInSaaS();
		
		If InformationRegisters.ExchangeMessageArchiveSettings.GetSettings(Node) = Undefined Then
			
			Settings = InformationRegisters.ExchangeMessageArchiveSettings.CreateRecordManager();
			Settings.InfobaseNode = Node;
			Settings.FilesCount = 1;
			Settings.StoreOnDisk = False;
			Settings.ShouldCompressFiles = True;
			Settings.Write();  //  
			
		EndIf;
	
	EndIf;
	
EndProcedure

#EndRegion

#Region ExchangeMessages

// Gets the exchange message to the temporary directory of the OS user.
//
// Parameters:
//  Cancel                        - Boolean -  failure flag; raised if an error occurs.
//  InfobaseNode       - ExchangePlanRef -  the exchange plan node for which the exchange message is being received
//                                                    .
//  ExchangeMessagesTransportKind - EnumRef.ExchangeMessagesTransportTypes -  mode of transport for receiving
//                                                                                    the exchange message.
//  OutputMessages            - Boolean -  if True, messages are displayed to the user.
//
//  Returns:
//   Structure with the following keys:
//     * time_name of the exchange message Catalog - the full name of the exchange folder where the exchange message was uploaded.
//     * Exchange message file_name - the full file name of the exchange message.
//     * ID of the data packagefile - the date when the exchange message file was modified.
//
Function GetExchangeMessageToTemporaryDirectory(Cancel, InfobaseNode, ExchangeMessagesTransportKind, OutputMessages = True) Export
	
	// 
	Result = New Structure;
	Result.Insert("TempExchangeMessagesDirectoryName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	ExchangeSettingsStructure = ExchangeTransportSettings(InfobaseNode, ExchangeMessagesTransportKind);
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	
	// 
	If ExchangeSettingsStructure.Cancel Then
		
		If OutputMessages Then
			NString = NStr("en = 'Failed to initialize exchange message transport processing.';");
			Common.MessageToUser(NString,,,, Cancel);
		EndIf;
		
		WriteExchangeFinish(ExchangeSettingsStructure);
		Return Result;
	EndIf;
	
	// 
	ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
		
		// 
		ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure);
		
	EndIf;

	If ExchangeSettingsStructure.ExchangeExecutionResult <> Undefined Then
		
		If OutputMessages Then
			NString = NStr("en = 'Errors occurred when receiving exchange messages.';");
			Common.MessageToUser(NString,,,, Cancel);
		EndIf;
		
		// 
		ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure);
		
		WriteExchangeFinish(ExchangeSettingsStructure);
		Return Result;
	EndIf;
	
	Result.TempExchangeMessagesDirectoryName = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageDirectoryName();
	Result.ExchangeMessageFileName              = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileName();
	Result.DataPackageFileID       = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileDate();
	
	Return Result;
EndFunction

// Receives an exchange message from the correspondent's information base to the temporary directory of the OS user.
//
// Parameters:
//  Cancel                        - Boolean -  failure flag; raised if an error occurs.
//  InfobaseNode       - ExchangePlanRef -  the exchange plan node for which the exchange message is being received
//                                                    .
//  OutputMessages            - Boolean -  if True, messages are displayed to the user.
//
//  Returns:
//   Structure with the following keys:
//     * time_name of the exchange message Catalog - the full name of the exchange folder where the exchange message was uploaded.
//     * Exchange message file_name - the full file name of the exchange message.
//     * ID of the data packagefile - the date when the exchange message file was modified.
//
Function GetExchangeMessageToTempDirectoryFromCorrespondentInfobase(Cancel, InfobaseNode, OutputMessages = True) Export
	
	// 
	Result = New Structure;
	Result.Insert("TempExchangeMessagesDirectoryName", "");
	Result.Insert("ExchangeMessageFileName",              "");
	Result.Insert("DataPackageFileID",       Undefined);
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	CorrespondentExchangePlanName = DataExchangeCached.GetNameOfCorrespondentExchangePlan(InfobaseNode);
	
	CurrentExchangePlanNode = DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName);
	CurrentExchangePlanNodeCode = NodeIDForExchange(InfobaseNode);

	MessageFileNameTemplate = MessageFileNameTemplate(CurrentExchangePlanNode, InfobaseNode, False);
	
	// 
	ExchangeMessageFileDate = Date('00010101');
	ExchangeMessageDirectoryName = "";
	ErrorMessageString = "";
	
	Try
		ExchangeMessageDirectoryName = CreateTempExchangeMessagesDirectory();
	Except
		If OutputMessages Then
			Message = NStr("en = 'Data exchange failed: %1';");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message, 
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Common.MessageToUser(Message,,,, Cancel);
		EndIf;
		Return Result;
	EndTry;
	
	// 
	ConnectionData = DataExchangeCached.ExternalConnectionForInfobaseNode(InfobaseNode);
	ExternalConnection = ConnectionData.Join;
	
	If ExternalConnection = Undefined Then
		
		Message = NStr("en = 'Data exchange failed: %1';");
		If OutputMessages Then
			MessageForUser = StringFunctionsClientServer.SubstituteParametersToString(Message, ConnectionData.BriefErrorDetails);
			Common.MessageToUser(MessageForUser,,,, Cancel);
		EndIf;
		
		// 
		ExchangeSettingsStructure = New Structure("EventLogMessageKey");
		ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
		
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ConnectionData.DetailedErrorDetails);
		WriteEventLogDataExchange(Message, ExchangeSettingsStructure, True);
		
		Return Result;
	EndIf;
	
	ExchangeMessageFileName = CommonClientServer.GetFullFileName(ExchangeMessageDirectoryName, MessageFileNameTemplate + ".xml");
	
	NodeAlias = PredefinedNodeAlias(InfobaseNode);
	If ValueIsFilled(NodeAlias) Then
		// 
		// 
		ExchangePlanManager = ExternalConnection.ExchangePlans[CorrespondentExchangePlanName];
		If ExchangePlanManager.FindByCode(NodeAlias) <> ExchangePlanManager.EmptyRef() Then
			CurrentExchangePlanNodeCode = NodeAlias;
		EndIf;
	EndIf;
	
	ExternalConnection.DataExchangeExternalConnection.ExportForInfobaseNode(Cancel, 
		CorrespondentExchangePlanName, CurrentExchangePlanNodeCode, ExchangeMessageFileName, ErrorMessageString);
	
	If Cancel Then
		
		If OutputMessages Then
			// 
			Message = NStr("en = 'Data export failed: %1';");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ConnectionData.BriefErrorDetails);
			Common.MessageToUser(Message,,,, Cancel);
		EndIf;
		
		Return Result;
	EndIf;
	
	FileExchangeMessages = New File(ExchangeMessageFileName);
	If FileExchangeMessages.Exists() Then
		ExchangeMessageFileDate = FileExchangeMessages.GetModificationTime();
	EndIf;
	
	Result.TempExchangeMessagesDirectoryName = ExchangeMessageDirectoryName;
	Result.ExchangeMessageFileName              = ExchangeMessageFileName;
	Result.DataPackageFileID       = ExchangeMessageFileDate;
	
	Return Result;
EndFunction

// Performs the file deletion messages exchange that were not removed due to failures in the system.
// Exchange files with a placement date more than a day from the current universal date,
// and files for matching with a placement date more than 7 days from the current universal date are subject to deletion.
// RS is analyzed.Messages are exchanged by data and RS.Messages are exchanged in the data domain.
//
// Parameters:
//   No.
//
Procedure DeleteObsoleteExchangeMessages() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ObsoleteSynchronizationDataDeletion);
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		Return;
	EndIf;
	
	CheckExchangeManagementRights();
	
	SetPrivilegedMode(True);
	
	If Common.SeparatedDataUsageAvailable() Then
		// 
		QueryText =
		"SELECT
		|	DataExchangeMessages.MessageID AS MessageID,
		|	DataExchangeMessages.MessageFileName AS FileName,
		|	DataExchangeMessages.MessageStoredDate AS MessageStoredDate,
		|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
		|	CASE
		|		WHEN CommonInfobasesNodesSettings.InfobaseNode IS NULL
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS MessageForMapping
		|INTO TTExchangeMessages
		|FROM
		|	InformationRegister.DataExchangeMessages AS DataExchangeMessages
		|		LEFT JOIN InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
		|		ON (CommonInfobasesNodesSettings.MessageForDataMapping = DataExchangeMessages.MessageID)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTExchangeMessages.MessageID AS MessageID,
		|	TTExchangeMessages.FileName AS FileName,
		|	TTExchangeMessages.MessageForMapping AS MessageForMapping,
		|	TTExchangeMessages.InfobaseNode AS InfobaseNode
		|FROM
		|	TTExchangeMessages AS TTExchangeMessages
		|WHERE
		|	CASE
		|			WHEN TTExchangeMessages.MessageForMapping
		|				THEN TTExchangeMessages.MessageStoredDate < &RelevanceDateForMapping
		|			ELSE TTExchangeMessages.MessageStoredDate < &UpdateDate
		|		END";
		
		Query = New Query;
		Query.SetParameter("UpdateDate",                 CurrentUniversalDate() - 60 * 60 * 24);
		Query.SetParameter("RelevanceDateForMapping", CurrentUniversalDate() - 60 * 60 * 24 * 7);
		Query.Text = QueryText;
		
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			
			MessageFileFullName = CommonClientServer.GetFullFileName(TempFilesStorageDirectory(), Selection.FileName);
			
			MessageFile = New File(MessageFileFullName);
			
			If MessageFile.Exists() Then
				
				Try
					DeleteFiles(MessageFile.FullName);
				Except
					WriteLogEvent(DataExchangeEventLogEvent(),
						EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
					Continue;
				EndTry;
			EndIf;
			
			// 
			RecordStructure = New Structure;
			RecordStructure.Insert("MessageID", String(Selection.MessageID));
			InformationRegisters.DataExchangeMessages.DeleteRecord(RecordStructure);
			
			If Selection.MessageForMapping Then
				RecordStructure = New Structure;
				RecordStructure.Insert("InfobaseNode",          Selection.InfobaseNode);
				RecordStructure.Insert("MessageForDataMapping", "");
				
				DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "CommonInfobasesNodesSettings");
			EndIf;
			
		EndDo;
		
	EndIf;
	
	// 
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.OnDeleteObsoleteExchangeMessages();
	EndIf;
	
EndProcedure

// Uploads an exchange message that contains
// configuration changes before updating the database.
//
Procedure ExportMessageAfterInfobaseUpdate()
	
	// 
	DisableDataExchangeMessageImportRepeatBeforeStart();
	
	Try
		If GetFunctionalOption("UseDataSynchronization") Then
			
			InfobaseNode = MasterNode();
			
			If InfobaseNode <> Undefined Then
				
				ExecuteExport = True;
				
				TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(InfobaseNode);
				
				TransportKind = TransportSettings.DefaultExchangeMessagesTransportKind;
				
				If TransportKind = Enums.ExchangeMessagesTransportTypes.WS
					And Not TransportSettings.WSRememberPassword Then
					
					ExecuteExport = False;
					
					InformationRegisters.CommonInfobasesNodesSettings.SetDataSendingFlag(InfobaseNode);
					
				EndIf;
				
				If ExecuteExport Then
					
					// 
					Cancel = False;
					
					ExchangeParameters = ExchangeParameters();
					ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
					ExchangeParameters.ExecuteImport1 = False;
					ExchangeParameters.ExecuteExport2 = True;
					
					ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	Except
		WriteLogEvent(DataExchangeEventLogEvent(),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#EndRegion

#Region SerializationMethodsExchangeExecution

// Procedure for recording changes for an exchange message.
// It is applicable for cases when the metadata structure of the exchanged databases is the same for all objects participating in the exchange.
//
Procedure ExecuteStandardNodeChangesExport(Cancel,
							InfobaseNode,
							FileName,
							ExchangeMessage,
							TransactionItemsCount = 0,
							EventLogMessageKey = "",
							ProcessedObjectsCount = 0)
	
	XMLWriter = New XMLWriter;	
	If Not IsBlankString(FileName) Then
		XMLWriter.OpenFile(FileName);
	Else
		XMLWriter.SetString();
	EndIf;
	XMLWriter.WriteXMLDeclaration();
	
	// 
	WriteMessage1 = ExchangePlans.CreateMessageWriter();
	
	WriteMessage1.BeginWrite(XMLWriter, InfobaseNode);
	
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	PredefinedDataTable = DataExchangeInternal.PredefinedDataTable1();
	PredefinedDataTable.Columns.Add("Export", New TypeDescription("Boolean"));
	PredefinedDataTable.Indexes.Add("Ref");
	
	// 
	ChangesSelection = SelectChanges(WriteMessage1.Recipient, WriteMessage1.MessageNo);
	
	If IsBlankString(EventLogMessageKey) Then
		EventLogMessageKey = DataExchangeEventLogEvent();
	EndIf;
	
	RecipientObject = InfobaseNode.GetObject();
	
	ExportingParameters = New Structure;
	ExportingParameters.Insert("XMLWriter",                      XMLWriter);
	ExportingParameters.Insert("Recipient",                     RecipientObject);
	ExportingParameters.Insert("InitialDataExport",        InitialDataExportFlagIsSet(InfobaseNode));
	ExportingParameters.Insert("TransactionItemsCount", TransactionItemsCount);
	ExportingParameters.Insert("ProcessedObjectsCount",   ProcessedObjectsCount);
	ExportingParameters.Insert("PredefinedDataTable",        PredefinedDataTable);
	
	UseTransactions = TransactionItemsCount <> 1;
	
	ContinueExport = True;
	If UseTransactions Then
		While ContinueExport Do
			BeginTransaction();
			Try
				ExecuteStandardDataBatchExport(ChangesSelection, ExportingParameters, ContinueExport);
				CommitTransaction();
			Except
				RollbackTransaction();
				
				WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
					InfobaseNode.Metadata(), InfobaseNode,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Cancel = True;
				Break;
			EndTry;
		EndDo;
	Else
		Try
			While ContinueExport Do
				ExecuteStandardDataBatchExport(ChangesSelection, ExportingParameters, ContinueExport);
			EndDo;
		Except
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
				InfobaseNode.Metadata(), InfobaseNode, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Cancel = True;
		EndTry;
	EndIf;
	
	If Cancel Then
		WriteMessage1.CancelWrite();
		XMLWriter.Close();
		Return;
	EndIf;
	
	ExportPredefinedItemsTable(ExportingParameters);
	
	WriteMessage1.EndWrite();
	ExchangeMessage = XMLWriter.Close();
	
	ProcessedObjectsCount = ExportingParameters.ProcessedObjectsCount;
	
EndProcedure

Procedure ExecuteStandardDataBatchExport(ChangesSelection, ExportingParameters, ContinueExport)
	
	WrittenItemsCount = 0;
	
	While (ExportingParameters.TransactionItemsCount = 0
			Or WrittenItemsCount <= ExportingParameters.TransactionItemsCount)
		And ChangesSelection.Next() Do
		
		Data = ChangesSelection.Get();
		
		// 
		// 
		// 
		// 
		ItemSend = DataItemSend.Auto;
		
		StandardSubsystemsServer.OnSendDataToSlave(Data, ItemSend, ExportingParameters.InitialDataExport, ExportingParameters.Recipient);
		
		If ItemSend = DataItemSend.Delete Then
			
			If Common.IsRegister(Data.Metadata()) Then
				
				// 
				
			Else
				
				Data = New ObjectDeletion(Data.Ref);
				
			EndIf;
			
		ElsIf ItemSend = DataItemSend.Ignore Then
			
			Continue;
			
		EndIf;
		
		// 
		WriteXML(ExportingParameters.XMLWriter, Data);
		WrittenItemsCount = WrittenItemsCount + 1;
		
		DataExchangeInternal.MarkRefsToPredefinedData(Data, ExportingParameters.PredefinedDataTable);
		
	EndDo;
	
	ContinueExport = (WrittenItemsCount > 0);
	
	ExportingParameters.ProcessedObjectsCount = ExportingParameters.ProcessedObjectsCount + WrittenItemsCount;
	
EndProcedure

Procedure ExportPredefinedItemsTable(ExportingParameters)
	
	ExportingParameters.PredefinedDataTable.Sort("TableName");
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString("UTF-8");
	
	XMLWriter.WriteStartElement("PredefinedData");
	
	CountExported = 0;
	
	For Each PredefinedDataRow In ExportingParameters.PredefinedDataTable Do
		If Not PredefinedDataRow.Export Then
			Continue;
		EndIf;
		
		XMLWriter.WriteStartElement(PredefinedDataRow.XMLTypeName1);
		XMLWriter.WriteAttribute("PredefinedDataName", PredefinedDataRow.PredefinedDataName);
		XMLWriter.WriteText(XMLString(PredefinedDataRow.Ref));
		XMLWriter.WriteEndElement();
		
		CountExported = CountExported + 1;
	EndDo;
	
	XMLWriter.WriteEndElement(); // PredefinedData
	
	PredefinedItemsComment = XMLWriter.Close();
	
	If CountExported > 0 Then
		ExportingParameters.XMLWriter.WriteComment(PredefinedItemsComment);
	EndIf;
	
EndProcedure

// Procedure for reading changes from an exchange message.
// It is applicable for cases when the metadata structure of the exchanged databases is the same for all objects participating in the exchange.
//
Procedure ExecuteStandardNodeChangeImport(
		InfobaseNode,
		FileName,
		ExchangeMessage,
		TransactionItemsCount,
		EventLogMessageKey,
		ProcessedObjectsCount,
		ExchangeExecutionResult)
		
	If IsBlankString(EventLogMessageKey) Then
		EventLogMessageKey = DataExchangeEventLogEvent();
	EndIf;
	
	ImportParameters = New Structure;
	ImportParameters.Insert("InfobaseNode",       InfobaseNode);
	ImportParameters.Insert("ExchangeMessage",              ExchangeMessage);
	ImportParameters.Insert("FileName",                     FileName);
	ImportParameters.Insert("XMLReader",                    Undefined);
	ImportParameters.Insert("MessageReader",              Undefined);
	
	ImportParameters.Insert("TransactionItemsCount", TransactionItemsCount);
	ImportParameters.Insert("ProcessedObjectsCount",   0);
	
	PredefinedDataTable = DataExchangeInternal.PredefinedDataTable1();
	PredefinedDataTable.Columns.Add("SourceRef1");
	PredefinedDataTable.Columns.Add("OriginalReferenceFilled", New TypeDescription("Boolean"));
	
	ImportParameters.Insert("PredefinedDataTable", PredefinedDataTable);
	
	ErrorMessage = "";
	FillInitialRefsInPredefinedDataTable(ImportParameters, ErrorMessage);
	
	ImportParameters.PredefinedDataTable = PredefinedDataTable.Copy(New Structure("OriginalReferenceFilled", True));
	ImportParameters.PredefinedDataTable.Indexes.Add("SourceRef1");
	PredefinedDataTable = Undefined;
	
	If Not IsBlankString(ErrorMessage) Then
		WriteLogEvent(EventLogMessageKey, EventLogLevel.Warning,
			InfobaseNode.Metadata(), InfobaseNode, ErrorMessage);
	EndIf;
	
	InitializeMessageReaderForStandardImport(ImportParameters, ExchangeExecutionResult, ErrorMessage);
	
	If ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error Then
		WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
			InfobaseNode.Metadata(), InfobaseNode, ErrorMessage);
		Return;
	ElsIf ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted Then
		WriteLogEvent(EventLogMessageKey, EventLogLevel.Warning,
			InfobaseNode.Metadata(), InfobaseNode, ErrorMessage);
		Return;
	EndIf;
	
	XMLReader       = ImportParameters.XMLReader;
	MessageReader = ImportParameters.MessageReader;
	
	BackupParameters = BackupParameters(MessageReader.Sender, MessageReader.ReceivedNo);
	
	// 
	If Not BackupParameters.BackupRestored Then
		ExchangePlans.DeleteChangeRecords(MessageReader.Sender, MessageReader.ReceivedNo);
		InformationRegisters.CommonInfobasesNodesSettings.ClearInitialDataExportFlag(
			MessageReader.Sender, MessageReader.ReceivedNo);
	EndIf;
		
	UseTransactions = TransactionItemsCount <> 1;
	
	ContinueImport = True;
	If UseTransactions Then
		While ContinueImport Do
			DataExchangeInternal.DisableAccessKeysUpdate(True);
			BeginTransaction();
			Try
				ExecuteStandardDataBatchImport(ImportParameters, ContinueImport);
				DataExchangeInternal.DisableAccessKeysUpdate(False);
				CommitTransaction();
			Except
				RollbackTransaction();
				DataExchangeInternal.DisableAccessKeysUpdate(False, False);
				
				ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
				WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
					InfobaseNode.Metadata(), InfobaseNode,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				Break;
			EndTry;
		EndDo;
	Else
		DataExchangeInternal.DisableAccessKeysUpdate(True);
		Try
			While ContinueImport Do
				ExecuteStandardDataBatchImport(ImportParameters, ContinueImport);
			EndDo;
			DataExchangeInternal.DisableAccessKeysUpdate(False);
		Except
			DataExchangeInternal.DisableAccessKeysUpdate(False);
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
				InfobaseNode.Metadata(), InfobaseNode,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
		
	EndIf;
	
	If ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error Then
		MessageReader.CancelRead();
	Else
		// 
		CurrentNodeName = "";
		While MessageReader.XMLReader.NodeType = XMLNodeType.StartElement
			Or (MessageReader.XMLReader.NodeType = XMLNodeType.EndElement
				And MessageReader.XMLReader.Name = CurrentNodeName) Do
			CurrentNodeName = MessageReader.XMLReader.Name;
			MessageReader.XMLReader.Ignore();
		EndDo;
		
		Try
			MessageReader.EndRead();
			OnRestoreFromBackup(BackupParameters);
		Except
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Error,
				InfobaseNode.Metadata(), InfobaseNode,
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	XMLReader.Close();
	
	ProcessedObjectsCount = ImportParameters.ProcessedObjectsCount;
	
EndProcedure

Procedure FillInitialRefsInPredefinedDataTable(ImportParameters, ErrorMessage)
	
	XMLReader = New XMLReader;
	ReaderSettings = New XMLReaderSettings(, , , , , , , False); // 
	Try
		If Not IsBlankString(ImportParameters.ExchangeMessage) Then
			XMLReader.SetString(ImportParameters.ExchangeMessage, ReaderSettings);
		Else
			XMLReader.OpenFile(ImportParameters.FileName, ReaderSettings);
		EndIf;
		
		IsBody = False;
		While XMLReader.Read() Do
			If XMLReader.NodeType = XMLNodeType.StartElement Then
				If XMLReader.LocalName = "Message" Then
					Continue;
				ElsIf XMLReader.LocalName = "Header" Then
					XMLReader.Skip();
				ElsIf XMLReader.LocalName = "Body" Then
					IsBody = True;
					Continue;
				ElsIf IsBody And CanReadXML(XMLReader) Then
					XMLReader.Skip();
				ElsIf IsBody And XMLReader.LocalName = "PredefinedData" Then
					ProcessPredefinedItemsSectionInExchangeMessage(
						XMLReader, ImportParameters.PredefinedDataTable);
				EndIf;
			ElsIf XMLReader.NodeType = XMLNodeType.EndElement Then
				If XMLReader.LocalName = "Message" Then
					Break;
				ElsIf XMLReader.LocalName = "Header" Then
					Continue;
				ElsIf XMLReader.LocalName = "Body" Then
					Break;
				EndIf;
			ElsIf IsBody And XMLReader.NodeType = XMLNodeType.Comment Then
				XMLReaderComment = New XMLReader;
				XMLReaderComment.SetString(XMLReader.Value);
				XMLReaderComment.Read(); // 
				
				ProcessPredefinedItemsSectionInExchangeMessage(
					XMLReaderComment, ImportParameters.PredefinedDataTable);
					
				XMLReaderComment.Close();
			EndIf;
		EndDo;
	Except
		ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());
	EndTry;
	
	XMLReader.Close();
	
EndProcedure

Procedure InitializeMessageReaderForStandardImport(ImportParameters, ExchangeExecutionResult, ErrorMessage)
	
	XMLReader = New XMLReader;
	Try
		If Not IsBlankString(ImportParameters.ExchangeMessage) Then
			XMLReader.SetString(ImportParameters.ExchangeMessage);
		Else
			XMLReader.OpenFile(ImportParameters.FileName);
		EndIf;
		
		MessageReader = ExchangePlans.CreateMessageReader();
		MessageReader.BeginRead(XMLReader, AllowedMessageNo.Greater);
	Except
		ErrorInfo  = ErrorInfo();
		
		BriefInformation   = ErrorProcessing.BriefErrorDescription(ErrorInfo);
		DetailedInformation = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
		If IsErrorMessageNumberLessOrEqualToPreviouslyReceivedMessageNumber(BriefInformation) Then
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted;
			ErrorMessage = BriefInformation;
		Else
			ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
			ErrorMessage = DetailedInformation;
		EndIf;
		
		Return;
	EndTry;
	
	If MessageReader.Sender <> ImportParameters.InfobaseNode Then
		// 
		ExchangeExecutionResult = Enums.ExchangeExecutionResults.Error;
		
		ErrorMessage = NStr("en = 'The exchange message contains data for another infobase node.';",
			Common.DefaultLanguageCode());
		Return;
	EndIf;
	
	ImportParameters.XMLReader       = XMLReader;
	ImportParameters.MessageReader = MessageReader;
	
EndProcedure

Procedure ExecuteStandardDataBatchImport(ImportParameters, ContinueImport)
	
	XMLReader       = ImportParameters.XMLReader;
	MessageReader = ImportParameters.MessageReader; // ExchangeMessageReader
	
	WrittenItemsCount = 0;
	
	While (ImportParameters.TransactionItemsCount = 0
			Or WrittenItemsCount <= ImportParameters.TransactionItemsCount)
		And CanReadXML(XMLReader) Do
		
		Data = ReadXML(XMLReader);
		
		ItemReceive = DataItemReceive.Auto;
		SendBack = False;
		
		StandardSubsystemsServer.OnReceiveDataFromMaster(
			Data, ItemReceive, SendBack, MessageReader.Sender.GetObject());
			
		ImportParameters.ProcessedObjectsCount = ImportParameters.ProcessedObjectsCount + 1;
		
		If ItemReceive = DataItemReceive.Ignore Then
			Continue;
		EndIf;
			
		// 
		//  
		// 
		If TypeOf(Data) = Type("ObjectDeletion") Then
			Data = Data.Ref.GetObject();
			
			If Data = Undefined Then
				Continue;
			EndIf;
			
			Data.DeletionMark = True;
			
			If Common.IsDocument(Data.Metadata()) Then
				Data.Posted = False;
			EndIf;
		Else
			DataExchangeInternal.ReplaceRefsToPredefinedItems(Data, ImportParameters.PredefinedDataTable);
		EndIf;
		
		If Not SendBack Then
			Data.DataExchange.Sender = MessageReader.Sender;
		EndIf;
		Data.DataExchange.Load = True;
		
		Data.Write();
		
		WrittenItemsCount = WrittenItemsCount + 1;
		
	EndDo;
	
	ContinueImport = (WrittenItemsCount > 0);
	
EndProcedure

Procedure ProcessPredefinedItemsSectionInExchangeMessage(XMLReader, PredefinedDataTable)
	
	If XMLReader.NodeType = XMLNodeType.StartElement
		And XMLReader.LocalName = "PredefinedData" Then
		
		XMLReader.Read();
		While CanReadXML(XMLReader) Do
			XMLTypeName1          = XMLReader.LocalName;
			PredefinedName = XMLReader.GetAttribute("PredefinedDataName");
			SourceRef1      = ReadXML(XMLReader);
			
			RowsPredefinedData = PredefinedDataTable.FindRows(
				New Structure("XMLTypeName1, PredefinedDataName", XMLTypeName1, PredefinedName));
			For Each RowPredefinedData In RowsPredefinedData Do
				RowPredefinedData.SourceRef1 = SourceRef1;
				RowPredefinedData.OriginalReferenceFilled = True;
			EndDo;
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region PropertyFunctions

Function FullNameOfFileOfDeferredUpdateData()
	
	Return GetTempFileName(".xml");
	
EndFunction

// Returns the file name of the data exchange message based on the data of the sending node and the receiving node.
//
Function ExchangeMessageFileName(SenderNodeCode, RecipientNodeCode, IsOutgoingMessage)
	
	NameTemplate = "[Prefix]_[SenderNode]_[RecipientNode]";
	If StrLen(SenderNodeCode) = 36 And IsOutgoingMessage Then
		SourceIBPrefix = Constants.DistributedInfobaseNodePrefix.Get();
		If ValueIsFilled(SourceIBPrefix) Then
			NameTemplate = "[Prefix]_[SourceIBPrefix]_[SenderNode]_[RecipientNode]";
		EndIf;
	EndIf;
	NameTemplate = StrReplace(NameTemplate, "[Prefix]",         "Message");
	NameTemplate = StrReplace(NameTemplate, "[SourceIBPrefix]",SourceIBPrefix);
	NameTemplate = StrReplace(NameTemplate, "[SenderNode]", SenderNodeCode);
	NameTemplate = StrReplace(NameTemplate, "[RecipientNode]",  RecipientNodeCode);
	
	Return NameTemplate;
EndFunction

// Returns the name of the temporary folder for data exchange messages.
// The folder name matches the template:
// "Exchange82 {GUID}", 
// where GUID is a string of unique identifier.
//
// Parameters:
//  No.
// 
// Returns:
//  String - 
//
Function TempExchangeMessagesDirectoryName()
	
	Return StrReplace("Exchange82 {GUID}", "GUID", Upper(String(New UUID)));
	
EndFunction

// Returns the name of the exchange message transport processing.
//
// Parameters:
//  TransportKind - EnumRef.ExchangeMessagesTransportTypes -  type of transport that you want to
//                                                                     the name of the treatment.
// 
//  Returns:
//    String - 
//
Function DataExchangeMessageTransportDataProcessorName(TransportKind)
	
	TypesOfTransportAndProcessing = New Map();
	TypesOfTransportAndProcessing.Insert(Enums.ExchangeMessagesTransportTypes.EMAIL,	Metadata.DataProcessors.ExchangeMessageTransportEMAIL.Name);
	TypesOfTransportAndProcessing.Insert(Enums.ExchangeMessagesTransportTypes.FILE,	Metadata.DataProcessors.ExchangeMessageTransportFILE.Name);
	TypesOfTransportAndProcessing.Insert(Enums.ExchangeMessagesTransportTypes.FTP,	Metadata.DataProcessors.ExchangeMessageTransportFTP.Name);
	
	If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		TypesOfTransportAndProcessing.Insert(Enums.ExchangeMessagesTransportTypes.ExternalSystem, "ExchangeMessagesTransportExternalSystem");
	EndIf;
	
	Return TypesOfTransportAndProcessing.Get(TransportKind);
		
EndFunction

// Double procedures on the server Abendanimation.Maximum number of fields of object comparison().
//
// Returns:
//   Number
//
Function MaxObjectsMappingFieldsCount() Export
	
	Return 5;
	
EndFunction

// Property function: returns a literal for a string of unlimited length.
//
// Returns:
//  String - 
//
Function UnlimitedLengthString() Export
	
	Return "(odb)";
	
EndFunction

// Property function: returns the literal of the node designation-XML, which contains the value of the PRO constant.
//
// Returns:
//  String - 
//
Function FilterItemPropertyConstantValue() Export
	
	Return "ConstantValue";
	
EndFunction

// Property function: returns the literal of the node designation-XML, which contains the algorithm for getting the value.
//
// Returns:
//  String - 
//
Function FilterItemPropertyValueAlgorithm() Export
	
	Return "ValueAlgorithm";
	
EndFunction

// Property function: returns the name of the file that is used to check whether transport processing is enabled.
//
// Returns:
//  String - 
//
Function TempConnectionTestFileName() Export
	FilePostfix = String(New UUID());
	Return "ConnectionCheckFile_" + FilePostfix + ".tmp";
	
EndFunction

Function IsErrorMessageNumberLessOrEqualToPreviouslyReceivedMessageNumber(ErrorDescription)
	
	Return StrFind(Lower(ErrorDescription), Lower(NStr("en = 'The message number is less than or equal to';"))) > 0;
	
EndFunction

#EndRegion

#Region ExchangeMessagesTransport

Procedure ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure)
	
	// 
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor; // DataProcessorObject.ExchangeMessageTransportEMAIL,  DataProcessorObject.ExchangeMessageTransportFILE,  DataProcessorObject.ExchangeMessageTransportFTP
	
	// 
	If Not ExchangeMessageTransportDataProcessor.ExecuteActionsBeforeProcessMessage() Then
		
		WriteEventLogDataExchange(ExchangeMessageTransportDataProcessor.ErrorMessageStringEL, ExchangeSettingsStructure, True);
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport;
		
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeMessageTransportSending(ExchangeSettingsStructure)
	
	// 
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor; // DataProcessorObject.ExchangeMessageTransportEMAIL,  DataProcessorObject.ExchangeMessageTransportFILE,  DataProcessorObject.ExchangeMessageTransportFTP
	
	// 
	If Not ExchangeMessageTransportDataProcessor.ConnectionIsSet()
		Or Not ExchangeMessageTransportDataProcessor.SendMessage() Then
		
		WriteEventLogDataExchange(ExchangeMessageTransportDataProcessor.ErrorMessageStringEL, ExchangeSettingsStructure, True);
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport;
		
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure, UseAlias = True, ErrorsStack = Undefined)
	
	If ErrorsStack = Undefined Then
		ErrorsStack = New Array;
	EndIf;
	
	// 
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor; // DataProcessorObject.ExchangeMessageTransportEMAIL,  DataProcessorObject.ExchangeMessageTransportFILE,  DataProcessorObject.ExchangeMessageTransportFTP
	ExchangeMessageTransportDataProcessor.InfobaseNode = ExchangeSettingsStructure.InfobaseNode;
	
	// 
	If Not ExchangeMessageTransportDataProcessor.ConnectionIsSet()
		Or Not ExchangeMessageTransportDataProcessor.GetMessage() Then
		
		ErrorsStack.Add(ExchangeMessageTransportDataProcessor.ErrorMessageStringEL);
		
		If Not UseAlias Then
			// 
			For Each CurrentError In ErrorsStack Do
				WriteEventLogDataExchange(CurrentError, ExchangeSettingsStructure, True);
			EndDo;
		EndIf;
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport;
		
	EndIf;
	
	If UseAlias
		And ExchangeSettingsStructure.ExchangeExecutionResult <> Undefined Then
		// 
		
		Transliteration = Undefined;
		If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
			ExchangeSettingsStructure.TransportSettings.Property("FILETransliterateExchangeMessageFileNames", Transliteration);
		ElsIf ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
			ExchangeSettingsStructure.TransportSettings.Property("EMAILTransliterateExchangeMessageFileNames", Transliteration);
		ElsIf ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
			ExchangeSettingsStructure.TransportSettings.Property("FTPTransliterateExchangeMessageFileNames", Transliteration);
		EndIf;
		Transliteration = ?(Transliteration = Undefined, False, Transliteration);
		
		FileNameTemplatePrevious = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNameTemplate;
		ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNameTemplate = MessageFileNameTemplate(
				ExchangeSettingsStructure.CurrentExchangePlanNode,
				ExchangeSettingsStructure.InfobaseNode,
				False,
				Transliteration, 
				True);
		If FileNameTemplatePrevious <> ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.MessageFileNameTemplate Then
			// 
			ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
			ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure, False, ErrorsStack);
		Else
			// 
			For Each CurrentError In ErrorsStack Do
				WriteEventLogDataExchange(CurrentError, ExchangeSettingsStructure, True);
			EndDo;
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure)
	
	// 
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor; // DataProcessorObject.ExchangeMessageTransportEMAIL,  DataProcessorObject.ExchangeMessageTransportFILE,  DataProcessorObject.ExchangeMessageTransportFTP
	
	// 
	ExchangeMessageTransportDataProcessor.ExecuteActionsAfterProcessMessage();
	
EndProcedure

// Gets the proxy server settings.
//
Function ProxyServerSettings(SecureConnection)
	
	Proxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		Protocol = ?(SecureConnection = Undefined, "ftp", "ftps");
		Proxy = ModuleNetworkDownload.GetProxy(Protocol);
	EndIf;
	
	Return Proxy;
	
EndFunction
#EndRegion

#Region FileTransferService

// Getting the file name by its ID from the storage.
// If there is no file with the specified ID, an exception is thrown.
// If a file is found, its name is returned, and information about this file is deleted from the storage.
//
// Parameters:
//  FileID  - UUID -  ID of the received file.
//  FileName            - String -  the name of the file from the repository.
//
Procedure OnReceiveFileFromStorage(Val FileID, FileName)
	
	QueryText =
	"SELECT
	|	DataExchangeMessages.MessageFileName AS FileName
	|FROM
	|	InformationRegister.DataExchangeMessages AS DataExchangeMessages
	|WHERE
	|	DataExchangeMessages.MessageID = &MessageID";
	
	Query = New Query;
	Query.SetParameter("MessageID", String(FileID));
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		LongDesc = NStr("en = 'File with ID %1 not found.';");
		Raise StringFunctionsClientServer.SubstituteParametersToString(LongDesc, String(FileID));
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	FileName = Selection.FileName;
	
	// 
	RecordStructure = New Structure;
	RecordStructure.Insert("MessageID", String(FileID));
	InformationRegisters.DataExchangeMessages.DeleteRecord(RecordStructure);
	
EndProcedure

// Putting a file in storage.
//
Procedure OnPutFileToStorage(Val RecordStructure)
	
	InformationRegisters.DataExchangeMessages.AddRecord(RecordStructure);
	
EndProcedure

#EndRegion

#Region InitialDataExportChangesRegistration

// Registers changes for the initial data upload, taking into account the upload start date and the list of companies.
// The procedure is universal and can be used to register data changes by the upload start date
// and the list of companies for object data types and register record sets.
// If the list of companies is not specified (Companies = Undefined), changes are registered only by
// the upload start date.
// Data for all metadata objects included in the exchange plan must be registered.
// If the autoregistration flag is set for the metadata object in the exchange plan
// , or if the autoregistration flag is not set and registration rules
// are not set, changes will be registered for all data of this type.
// If registration rules are set for the metadata object, changes will be 
// registered based on the upload start date and the list of companies.
// For documents, changes can be registered by the upload start date and by the list of companies.
// For business processes and tasks, changes can be registered by the upload start date.
// For register record sets, changes can be registered by the upload start date and by the list of companies.
// This procedure can serve as a prototype for developing your own change registration procedures
// for the initial data upload.
//
// Parameters:
//
//  Recipient - ExchangePlanRef -  the exchange plan node
//               that you want to register data changes for.
//  ExportStartDate - Date -  the date on which you need to
//               register data changes for uploading. Changes will be registered for data
//               that is located on the time axis after this date.
//  Companies - Array
//              - Undefined - 
//               
//               
//
Procedure RegisterDataByExportStartDateAndCompanies(Val Recipient, ExportStartDate,
	Companies = Undefined,
	Data = Undefined) Export
	
	FilterByCompanies = (Companies <> Undefined);
	FilterByExportStartDate = ValueIsFilled(ExportStartDate);
	
	If Not FilterByCompanies And Not FilterByExportStartDate Then
		
		If TypeOf(Data) = Type("Array") Then
			
			For Each MetadataObject In Data Do
				
				ExchangePlans.RecordChanges(Recipient, MetadataObject);
				
			EndDo;
			
		Else
			
			ExchangePlans.RecordChanges(Recipient, Data);
			
		EndIf;
		
		Return;
	EndIf;
	
	FilterByExportStartDateAndCompanies = FilterByExportStartDate And FilterByCompanies;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Recipient);
	
	ExchangePlanContent = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	UseFilterByMetadata = (TypeOf(Data) = Type("Array"));
	
	For Each ExchangePlanContentItem In ExchangePlanContent Do
		
		If UseFilterByMetadata
			And Data.Find(ExchangePlanContentItem.Metadata) = Undefined Then
			
			Continue;
			
		EndIf;
		
		FullObjectName = ExchangePlanContentItem.Metadata.FullName();
		
		If ExchangePlanContentItem.AutoRecord = AutoChangeRecord.Deny
			And DataExchangeCached.ObjectRegistrationRulesExist(ExchangePlanName, FullObjectName) Then
			
			If Common.IsDocument(ExchangePlanContentItem.Metadata) Then // Documents
				
				If FilterByExportStartDateAndCompanies
					// 
					And ExchangePlanContentItem.Metadata.Attributes.Find("Organization") <> Undefined Then
					
					Selection = DocumentsSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies);
					
					While Selection.Next() Do
						
						ExchangePlans.RecordChanges(Recipient, Selection.Ref);
						
					EndDo;
					
					Continue;
					
				Else // 
					
					Selection = ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate);
					
					While Selection.Next() Do
						
						ExchangePlans.RecordChanges(Recipient, Selection.Ref);
						
					EndDo;
					
					Continue;
					
				EndIf;
				
			ElsIf Common.IsBusinessProcess(ExchangePlanContentItem.Metadata)
				Or Common.IsTask(ExchangePlanContentItem.Metadata) Then // 
				
				// 
				Selection = ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate);
				
				While Selection.Next() Do
					
					ExchangePlans.RecordChanges(Recipient, Selection.Ref);
					
				EndDo;
				
				Continue;
				
			ElsIf Common.IsRegister(ExchangePlanContentItem.Metadata) Then // Registers
				
				// 
				If Common.IsInformationRegister(ExchangePlanContentItem.Metadata)
					And ExchangePlanContentItem.Metadata.WriteMode = Metadata.ObjectProperties.RegisterWriteMode.Independent Then
					
					MainFilter = MainInformationRegisterFilter(ExchangePlanContentItem.Metadata);
					
					FilterByPeriod     = (MainFilter.Find("Period") <> Undefined);
					FilterByCompany = (MainFilter.Find("Organization") <> Undefined);
					
					// 
					If FilterByExportStartDateAndCompanies And FilterByPeriod And FilterByCompany Then
						
						Selection = MainInformationRegisterFilterValuesSelectionByExportStartDateAndCompanies(MainFilter, FullObjectName, ExportStartDate, Companies);
						
					ElsIf FilterByExportStartDate And FilterByPeriod Then // 
						
						Selection = MainInformationRegisterFilterValuesSelectionByExportStartDate(MainFilter, FullObjectName, ExportStartDate);
						
					ElsIf FilterByCompanies And FilterByCompany Then // 
						
						Selection = MainInformationRegisterFilterValuesSelectionByCompanies(MainFilter, FullObjectName, Companies);
						
					Else
						
						Selection = Undefined;
						
					EndIf;
					
					If Selection <> Undefined Then
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							For Each DimensionName In MainFilter Do
								
								RecordSet.Filter[DimensionName].Value = Selection[DimensionName];
								RecordSet.Filter[DimensionName].Use = True;
								
							EndDo;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					EndIf;
					
				Else // 
					HasPeriodInRegister = Common.IsAccountingRegister(ExchangePlanContentItem.Metadata)
							Or Common.IsAccumulationRegister(ExchangePlanContentItem.Metadata)
							Or (Common.IsInformationRegister(ExchangePlanContentItem.Metadata)
								And ExchangePlanContentItem.Metadata.InformationRegisterPeriodicity 
									<> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical);
					If FilterByExportStartDateAndCompanies
						And HasPeriodInRegister
						// 
						And ExchangePlanContentItem.Metadata.Dimensions.Find("Organization") <> Undefined Then
						
						Selection = RecordSetsRecordersSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies);
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							RecordSet.Filter.Recorder.Value = Selection.Recorder;
							RecordSet.Filter.Recorder.Use = True;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					// 
					ElsIf HasPeriodInRegister Then
						
						Selection = RecordSetsRecordersSelectionByExportStartDate(FullObjectName, ExportStartDate);
						
						RecordSet = Common.ObjectManagerByFullName(FullObjectName).CreateRecordSet();
						
						While Selection.Next() Do
							
							RecordSet.Filter.Recorder.Value = Selection.Recorder;
							RecordSet.Filter.Recorder.Use = True;
							
							ExchangePlans.RecordChanges(Recipient, RecordSet);
							
						EndDo;
						
						Continue;
						
					EndIf;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		ExchangePlans.RecordChanges(Recipient, ExchangePlanContentItem.Metadata);
		
	EndDo;
	
EndProcedure

Function DocumentsSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies)
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref
	|FROM
	|	&FullObjectName AS Table
	|WHERE
	|	Table.Organization IN(&Companies)
	|	AND Table.Date >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function ObjectsSelectionByExportStartDate(FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref
	|FROM
	|	&FullObjectName AS Table
	|WHERE
	|	Table.Date >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function RecordSetsRecordersSelectionByExportStartDateAndCompanies(FullObjectName, ExportStartDate, Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	&FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Organization IN(&Companies)
	|	AND RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function RecordSetsRecordersSelectionByExportStartDate(FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT DISTINCT
	|	RegisterTable.Recorder AS Recorder
	|FROM
	|	&FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByExportStartDateAndCompanies(MainFilter,
	FullObjectName,
	ExportStartDate,
	Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	&Dimensions
	|FROM
	|	&FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Organization IN(&Companies)
	|	AND RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "&Dimensions", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByExportStartDate(MainFilter, FullObjectName, ExportStartDate)
	
	QueryText =
	"SELECT DISTINCT
	|	&Dimensions
	|FROM
	|	&FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Period >= &ExportStartDate";
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "&Dimensions", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("ExportStartDate", ExportStartDate);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilterValuesSelectionByCompanies(MainFilter, FullObjectName, Companies)
	
	QueryText =
	"SELECT DISTINCT
	|	&Dimensions
	|FROM
	|	&FullObjectName AS RegisterTable
	|WHERE
	|	RegisterTable.Organization IN(&Companies)";
	
	QueryText = StrReplace(QueryText, "&FullObjectName", FullObjectName);
	QueryText = StrReplace(QueryText, "&Dimensions", StrConcat(MainFilter, ","));
	
	Query = New Query;
	Query.SetParameter("Companies", Companies);
	Query.Text = QueryText;
	
	Return Query.Execute().Select();
EndFunction

Function MainInformationRegisterFilter(MetadataObject)
	
	Result = New Array;
	
	If MetadataObject.InformationRegisterPeriodicity <> Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical
		And MetadataObject.MainFilterOnPeriod Then
		
		Result.Add("Period");
		
	EndIf;
	
	For Each Dimension In MetadataObject.Dimensions Do
		
		If Dimension.MainFilter Then
			
			Result.Add(Dimension.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region WrappersToOperateWithExchangePlanManagerApplicationInterface

Function CommonNodeData(Val ExchangePlanName, Val CorrespondentVersion, Val SettingID) Export
	
	If IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	
	SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName, 
								SettingID, CorrespondentVersion);
	Result = SettingOptionDetails.CommonNodeData;
	
	Return StrReplace(Result, " ", "");
	
EndFunction

Procedure OnConnectToCorrespondent(Val ExchangePlanName, Val CorrespondentVersion) Export
	If Not HasExchangePlanManagerAlgorithm("OnConnectToCorrespondent", ExchangePlanName) Then
		Return;
	ElsIf IsBlankString(CorrespondentVersion) Then
		CorrespondentVersion = "0.0.0.0";
	EndIf;
	
	ExchangePlans[ExchangePlanName].OnConnectToCorrespondent(CorrespondentVersion);
	
EndProcedure

// Fills in the settings for the exchange plan, which are then used by the data exchange subsystem.
// Parameters:
//   ExchangePlanName              - String -  name of the exchange plan.
//   CorrespondentVersion        - String -  version of the corresponding configuration.
//   CorrespondentName           - String -  name of the correspondent configuration.
//   CorrespondentInSaaS - Boolean, Undefined -  indicates that the correspondent is in the service model.
// Returns:
//   See DefaultExchangePlanSettings.
//
Function ExchangePlanSettings(ExchangePlanName, CorrespondentVersion, CorrespondentName, CorrespondentInSaaS) Export
	ExchangePlanSettings = DefaultExchangePlanSettings(ExchangePlanName);
	SetPrivilegedMode(True);
	ExchangePlans[ExchangePlanName].OnGetSettings(ExchangePlanSettings);
	HasOptionsReceivingHandler = ExchangePlanSettings.Algorithms.OnGetExchangeSettingsOptions;
	// 
	If HasOptionsReceivingHandler Then
		FilterParameters = ContextParametersOfSettingsOptionsReceipt(CorrespondentName, CorrespondentVersion, CorrespondentInSaaS);
		ExchangePlans[ExchangePlanName].OnGetExchangeSettingsOptions(ExchangePlanSettings.ExchangeSettingsOptions, FilterParameters);
	Else
		// 
		SettingsMode = ExchangePlanSettings.ExchangeSettingsOptions.Add();
		SettingsMode.SettingID = "";
		SettingsMode.CorrespondentInSaaS = Common.DataSeparationEnabled() 
			And ExchangePlanSettings.ExchangePlanUsedInSaaS;
		SettingsMode.CorrespondentInLocalMode = True;
	EndIf;
	SetPrivilegedMode(False);

	Return ExchangePlanSettings;
EndFunction

// Fills in the settings related to the exchange configuration option, which are then used by the data exchange subsystem.
//
// Parameters:
//   ExchangePlanName         - String -  name of the exchange plan.
//   SettingID - String -  ID of the exchange configuration option.
//   CorrespondentVersion   - String -  version of the corresponding configuration.
//   CorrespondentName      - String -  name of the correspondent configuration.
//
// Returns:
//   See DefaultExchangeSettingOptionDetails
//
Function SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion, CorrespondentName) Export
	SettingOptionDetails = DefaultExchangeSettingOptionDetails(ExchangePlanName);
	HasOptionDetailsHandler = HasExchangePlanManagerAlgorithm("OnGetSettingOptionDetails", ExchangePlanName);
	If HasOptionDetailsHandler Then
		OptionParameters = ContextParametersOfSettingOptionDetailsReceipt(CorrespondentName, CorrespondentVersion);
		ExchangePlans[ExchangePlanName].OnGetSettingOptionDetails(
							SettingOptionDetails, SettingID, OptionParameters);
	EndIf;
	Return SettingOptionDetails;
EndFunction

#EndRegion

#Region DataSynchronizationPasswordsOperations

// Returns the value of the password synchronization for the specified node.
// If there is no password, it is returned Undefined.
//
// Returns:
//  String, Undefined - 
//
Function DataSynchronizationPassword(Val InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.DataSynchronizationPasswords.Get(InfobaseNode);
EndFunction

// Returns an indication that the data synchronization password was set by the user.
//
Function DataSynchronizationPasswordSpecified(Val InfobaseNode) Export
	
	Return DataSynchronizationPassword(InfobaseNode) <> Undefined;
	
EndFunction

#EndRegion

#Region SharedDataControl

// Called when checking whether undivided data is available for writing.
//
Procedure ExecuteSharedDataOnWriteCheck(Val Data) Export
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And Not IsSeparatedObject(Data) Then
		
		ExceptionText = NStr("en = 'Insufficient rights for this operation.';", Common.DefaultLanguageCode());
		
		WriteLogEvent(
			ExceptionText,
			EventLogLevel.Error,
			Data.Metadata());
		
		Raise ExceptionText;
	EndIf;
	
EndProcedure

Function IsSeparatedObject(Val Object)
	
	FullName = Object.Metadata().FullName();
	
	If Common.SubsystemExists("CloudTechnology.Core") Then
		ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
		IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject(FullName);
	Else
		IsSeparatedMetadataObject = False;
	EndIf;
	
	Return IsSeparatedMetadataObject;
	
EndFunction

#EndRegion

#Region DataExchangeMonitorOperations

// Returns a structure with data from the last exchange for the specified database node.
//
// Parameters:
//  No.
// 
// Returns:
//  СостоянияОбменовДанными - 
//
Function DataExchangesStatesForInfobaseNode(Val InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	// 
	DataExchangesStates = New Structure;
	DataExchangesStates.Insert("InfobaseNode");
	DataExchangesStates.Insert("DataImportResult", "Undefined");
	DataExchangesStates.Insert("DataExportResult", "Undefined");
	
	QueryText = "
	|// {ЗАПРОС №0}
	|////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|	THEN ""Success""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|	THEN ""CompletedWithWarnings""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
	|	THEN ""Warning_ExchangeMessageAlreadyAccepted""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.ErrorMessageTransport)
	|	THEN ""ErrorMessageTransport""
	|	
	|	ELSE ""Error""
	|	
	|	END AS ExchangeExecutionResult
	|FROM
	|	InformationRegister.DataExchangesStates AS DataExchangesStates
	|WHERE
	|	  DataExchangesStates.InfobaseNode = &InfobaseNode
	|	AND DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
	|;
	|// {ЗАПРОС №1}
	|////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
	|	THEN ""Success""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
	|	THEN ""CompletedWithWarnings""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
	|	THEN ""Warning_ExchangeMessageAlreadyAccepted""
	|	
	|	WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.ErrorMessageTransport)
	|	THEN ""ErrorMessageTransport""
	|	
	|	ELSE ""Error""
	|	END AS ExchangeExecutionResult
	|	
	|FROM
	|	InformationRegister.DataExchangesStates AS DataExchangesStates
	|WHERE
	|	  DataExchangesStates.InfobaseNode = &InfobaseNode
	|	AND DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
	|;
	|";
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.AdaptTheTextOfTheRequestAboutTheResultsOfTheExchangeInTheService(QueryText);
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("InfobaseNode", InfobaseNode);
	
	QueryResultsArray = Query.ExecuteBatch(); // Array of QueryResult
	
	DataImportResultsSelection = QueryResultsArray[0].Select();
	DataExportResultsSelection = QueryResultsArray[1].Select();
	
	If DataImportResultsSelection.Next() Then
		
		DataExchangesStates.DataImportResult = DataImportResultsSelection.ExchangeExecutionResult;
		
	EndIf;
	
	If DataExportResultsSelection.Next() Then
		
		DataExchangesStates.DataExportResult = DataExportResultsSelection.ExchangeExecutionResult;
		
	EndIf;
	
	DataExchangesStates.InfobaseNode = InfobaseNode;
	
	Return DataExchangesStates;
EndFunction

// Returns a structure with data from the last exchange for the specified node of the information base and actions during the exchange.
//
// Parameters:
//  No.
// 
// Returns:
//  СостоянияОбменовДанными - 
//
Function DataExchangesStates(Val InfobaseNode, ActionOnExchange) Export
	
	// 
	DataExchangesStates = New Structure;
	DataExchangesStates.Insert("StartDate",    Date('00010101'));
	DataExchangesStates.Insert("EndDate", Date('00010101'));
	
	QueryText = "
	|SELECT
	|	StartDate,
	|	EndDate
	|FROM
	|	InformationRegister.DataExchangesStates AS DataExchangesStates
	|WHERE
	|	  DataExchangesStates.InfobaseNode = &InfobaseNode
	|	AND DataExchangesStates.ActionOnExchange      = &ActionOnExchange
	|";
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.AdaptTheTextOfTheRequestAboutTheResultsOfTheExchangeInTheService(QueryText);
		
	EndIf;
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("InfobaseNode", InfobaseNode);
	Query.SetParameter("ActionOnExchange",      ActionOnExchange);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		
		FillPropertyValues(DataExchangesStates, Selection);
		
	EndIf;
	
	Return DataExchangesStates;
	
EndFunction

#EndRegion

#Region SessionInitialization

// Gets an array of all exchange plans for which data is exchanged.
// The presence of an exchange with any exchange plan is determined by the presence of nodes in this exchange plan other than the predefined one.
//
// Parameters:
//  No.
// 
// Returns:
//  МассивПлановОбмена - 
//
Function GetExchangePlansInUse() Export
	
	//  returned value
	ExchangePlansArray = New Array;
	
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		If Not ExchangePlanContainsNoNodes(ExchangePlanName) Then
			
			ExchangePlansArray.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return ExchangePlansArray;
	
EndFunction

// Retrieves a table of object registration rules from the information database.
//
// Parameters:
//  No.
// 
// Returns:
//  ПравилаРегистрацииОбъектов - 
// 
Function GetObjectsRegistrationRules() Export
	
	// 
	ObjectsRegistrationRules = ObjectsRegistrationRulesTableInitialization();
	
	QueryText = 
		"SELECT
		|	Rules.RulesAreRead AS RulesAreRead,
		|	Rules.ExchangePlanName AS ExchangePlanName,
		|	Rules.RulesSource AS RulesSource,
		|	Rules.RegistrationManagerName AS RegistrationManagerName
		|FROM
		|	InformationRegister.DataExchangeRules AS Rules
		|WHERE
		|	(Rules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsRegistrationRules)
		|				AND Rules.RulesAreImported
		|			OR Rules.RulesSource IN (&RuleSourcesManagers))";
	
	Query = New Query;
	Query.Text = QueryText;
	
	RuleSourcesManagers = New Array;
	RuleSourcesManagers.Add(Enums.DataExchangeRulesSources.StandardManager);
	RuleSourcesManagers.Add(Enums.DataExchangeRulesSources.CustomManager);
	
	Query.SetParameter("RuleSourcesManagers", RuleSourcesManagers);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		If Selection.RulesSource = Enums.DataExchangeRulesSources.StandardManager
			Or Selection.RulesSource = Enums.DataExchangeRulesSources.CustomManager Then
			
			If Selection.RulesSource = Enums.DataExchangeRulesSources.StandardManager Then 
				RegistrationManagerName = DataExchangeCached.RegistrationManagerName(Selection.ExchangePlanName);
			Else
				RegistrationManagerName = Selection.RegistrationManagerName;	
			EndIf;
			
			Manager = Common.CommonModule(RegistrationManagerName);
			Manager.InitializingRegistrationRules(ObjectsRegistrationRules, RegistrationManagerName);
			
		Else
			
			RulesAreRead = Selection.RulesAreRead.Get();
			If RulesAreRead = Undefined Then
				Continue;
			EndIf;
			
			FillPropertiesValuesForORRValuesTable(ObjectsRegistrationRules, RulesAreRead);
			
		EndIf;
		
	EndDo;
	
	Return ObjectsRegistrationRules;
	
EndFunction

Function ObjectsRegistrationRulesTableInitialization() Export
	
	// 
	Rules = New ValueTable;
	
	Columns = Rules.Columns;
	
	Columns.Add("MetadataObjectName3", New TypeDescription("String"));
	Columns.Add("Id",       New TypeDescription("String"));
	Columns.Add("ExchangePlanName",      New TypeDescription("String"));
	
	Columns.Add("FlagAttributeName", New TypeDescription("String"));
	
	Columns.Add("QueryText",    New TypeDescription("String"));
	Columns.Add("ObjectProperties", New TypeDescription("Structure"));
	
	Columns.Add("ObjectPropertiesAsString", New TypeDescription("String"));
	
	// 
	Columns.Add("RuleByObjectPropertiesEmpty", New TypeDescription("Boolean"));
	
	// 
	Columns.Add("BeforeProcess",            New TypeDescription("String"));
	Columns.Add("OnProcess",               New TypeDescription("String"));
	Columns.Add("OnProcessAdditional", New TypeDescription("String"));
	Columns.Add("AfterProcess",             New TypeDescription("String"));
	
	Columns.Add("HasBeforeProcessHandler",            New TypeDescription("Boolean"));
	Columns.Add("HasOnProcessHandler",               New TypeDescription("Boolean"));
	Columns.Add("HasOnProcessHandlerAdditional", New TypeDescription("Boolean"));
	Columns.Add("HasAfterProcessHandler",             New TypeDescription("Boolean"));
	Columns.Add("BatchExecutionOfHandlers",           New TypeDescription("Boolean"));
	
	Columns.Add("FilterByObjectProperties", New TypeDescription("ValueTree"));
	
	// 
	Columns.Add("SelectionByProperties", New TypeDescription("ValueTree"));
	
	// 
	Rules.Indexes.Add("ExchangePlanName, MetadataObjectName3");
	
	Columns.Add("FilterByExchangePlanProperties", New TypeDescription("ValueTree"));
	Columns.Add("RegistrationManagerName");
	
	Return Rules;
	
EndFunction

Function ExchangePlanContainsNoNodes(Val ExchangePlanName)
	
	Query = New Query(
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	#ExchangePlanTableName AS ExchangePlan
	|WHERE
	|	NOT ExchangePlan.ThisNode");
	
	Query.Text = StrReplace(Query.Text, "#ExchangePlanTableName", "ExchangePlan." + ExchangePlanName);
	
	Return Query.Execute().IsEmpty();
	
EndFunction

Procedure FillPropertiesValuesForORRValuesTable(DestinationTable, SourceTable1)
	
	For Each SourceRow1 In SourceTable1 Do
		
		FillPropertyValues(DestinationTable.Add(), SourceRow1);
		
	EndDo;
	
EndProcedure

Function DataSynchronizationRulesDetails(Val InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	CorrespondentVersion = CorrespondentVersion(InfobaseNode);
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	Setting = NodeFiltersSettingsValues(InfobaseNode, CorrespondentVersion);
	
	DataSynchronizationRulesDetails = DataTransferRestrictionsDetails(
		ExchangePlanName, Setting, CorrespondentVersion,SavedExchangePlanNodeSettingOption(InfobaseNode));
	
	SetPrivilegedMode(False);
	
	Return DataSynchronizationRulesDetails;
	
EndFunction

Function NodeFiltersSettingsValues(Val InfobaseNode, Val CorrespondentVersion)
	
	Result = New Structure;
	
	InfobaseNodeObject = InfobaseNode.GetObject();
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	NodeFiltersSetting = NodeFiltersSetting(ExchangePlanName,
		CorrespondentVersion, SavedExchangePlanNodeSettingOption(InfobaseNode));
	
	For Each Setting In NodeFiltersSetting Do
		
		If TypeOf(Setting.Value) = Type("Structure") Then
			
			TabularSection = New Structure;
			
			For Each Column In Setting.Value Do
				
				TabularSection.Insert(Column.Key, InfobaseNodeObject[Setting.Key].UnloadColumn(Column.Key));
				
			EndDo;
			
			Result.Insert(Setting.Key, TabularSection);
			
		Else
			
			Result.Insert(Setting.Key, InfobaseNodeObject[Setting.Key]);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Procedure SetDataExchangeMessageImportModeBeforeStart(Val Property, Val EnableMode) Export
	
	// 
	
	If IsSubordinateDIBNode() Then
		
		NewStructure = New Structure(SessionParameters.DataExchangeMessageImportModeBeforeStart);
		If EnableMode Then
			If Not NewStructure.Property(Property) Then
				NewStructure.Insert(Property);
			EndIf;
		Else
			If NewStructure.Property(Property) Then
				NewStructure.Delete(Property);
			EndIf;
		EndIf;
		
		SessionParameters.DataExchangeMessageImportModeBeforeStart =
			New FixedStructure(NewStructure);
	Else
		
		SessionParameters.DataExchangeMessageImportModeBeforeStart = New FixedStructure;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DataExchangeIssuesMonitorOperations

Function DataExchangeIssueCount(ExchangeNodes = Undefined)
	
	IssueSearchParameters = InformationRegisters.DataExchangeResults.IssueSearchParameters();
	IssueSearchParameters.ExchangePlanNodes = ExchangeNodes;
	
	IssuesTypes = New Array;
	IssuesTypes.Add(Enums.DataExchangeIssuesTypes.BlankAttributes);
	IssuesTypes.Add(Enums.DataExchangeIssuesTypes.UnpostedDocument);
	IssuesTypes.Add(Enums.DataExchangeIssuesTypes.ConvertedObjectValidationError);
	
	IssueSearchParameters.IssueType = IssuesTypes;
	
	Return InformationRegisters.DataExchangeResults.IssuesCount(IssueSearchParameters);
	
EndFunction

Function VersioningIssuesCount(ExchangeNodes = Undefined, Val QueryOptions = Undefined) Export
	
	If QueryOptions = Undefined Then
		QueryOptions = QueryParametersVersioningIssuesCount();
	EndIf;
	
	VersioningUsed = DataExchangeCached.VersioningUsed(, True);
	
	If VersioningUsed Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		Return ModuleObjectsVersioning.ConflictOrRejectedItemCount(
			ExchangeNodes,
			QueryOptions.IsConflictsCount,
			QueryOptions.IncludingIgnored,
			QueryOptions.Period,
			QueryOptions.SearchString);
	EndIf;
		
	Return 0;
	
EndFunction

Function QueryParametersVersioningIssuesCount() Export
	
	Result = New Structure;
	
	Result.Insert("IsConflictsCount",      Undefined);
	Result.Insert("IncludingIgnored", False);
	Result.Insert("Period",                     Undefined);
	Result.Insert("SearchString",               "");
	
	Return Result;
	
EndFunction

// Registers errors when a document is delayed in the exchange issue monitor.
//
// Parameters:
//  Object - DocumentObject -  a document where errors occurred during deferred processing.
//  ExchangeNode - ExchangePlanRef - 
//  
//    
//    
//    
//    
//  RecordIssuesInExchangeResults - Boolean -  it is necessary to record the problem.
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
Procedure RecordDocumentPostingError(
		Object,
		ExchangeNode,
		ExceptionText,
		RecordIssuesInExchangeResults = True)
	
	UserMessages = GetUserMessages(True);
	MessageText = ExceptionText;
	For Each Message In UserMessages Do
		
		If StrFind(Message.Text, "StandardSubsystems.TimeConsumingOperations") > 0 Then
			
			Continue;
			
		EndIf;
		
		MessageText = MessageText + ?(IsBlankString(MessageText), "", Chars.LF) + Message.Text;
		
	EndDo;
	MessageText = TrimAll(MessageText);
	
	MessageString = "";
	If Not IsBlankString(MessageText) Then
		MessageString = NStr("en = 'Cannot post ""%1"" received from another infobase.
			|Reason: %2.
			|Some attributes may be required.';",
			Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, String(Object), MessageText);
	Else
		MessageString = NStr("en = 'Cannot post ""%1"" received from another infobase.
			|Some attributes may be required.';",
			Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(
			MessageString, String(Object));
	EndIf;
	
	WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Warning,,, MessageString);
	
	If RecordIssuesInExchangeResults Then
		Try
			InformationRegisters.DataExchangeResults.RecordDocumentCheckError(Object.Ref, ExchangeNode,
				MessageText, Enums.DataExchangeIssuesTypes.UnpostedDocument);
		Except
			MessageString = NStr("en = 'An error occurred when saving the data exchange result for the %1 object:
								   |%2';", Common.DefaultLanguageCode());
			ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			
			MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, 
				String(Object), ErrorDescription);
			
			WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Error,,, MessageString);	
		EndTry	
	EndIf;
	
EndProcedure

// Registers errors when an object is being recorded in the exchange problem monitor.
//
// Parameters:
//   Object - CatalogObject, ДокументОбъект и т.п. -  the object that errors occurred during deferred recording.
//   ExchangeNode - ExchangePlanRef - 
//   
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
// 
// 	
// 
//
// 
//
Procedure RecordObjectWriteError(
		Object,
		ExchangeNode,
		ExceptionText)
	
	UserMessages = GetUserMessages(True);
	MessageText = ExceptionText;
	For Each Message In UserMessages Do
		
		If StrFind(Message.Text, "StandardSubsystems.TimeConsumingOperations") > 0 Then
			
			Continue;
			
		EndIf;
		
		MessageText = MessageText + ?(IsBlankString(MessageText), "", Chars.LF) + Message.Text;
		
	EndDo;
	
	ErrorReason = MessageText;
	If Not IsBlankString(TrimAll(MessageText)) Then
		
		ErrorReason = " " + NStr("en = 'Reason: %1.';");
		ErrorReason = StringFunctionsClientServer.SubstituteParametersToString(ErrorReason, MessageText);
		
	EndIf;
	
	MessageString = NStr("en = 'Failed to save %1 received from another infobase. %2
		|Some attributes may be required.';",
		Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(Object), ErrorReason);
	
	WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Warning,,, MessageString);
	
	Try
		InformationRegisters.DataExchangeResults.RecordDocumentCheckError(Object.Ref, ExchangeNode,
			MessageText, Enums.DataExchangeIssuesTypes.BlankAttributes);
	Except
		MessageString = NStr("en = 'An error occurred when saving the data exchange result for the %1 object:
								   |%2';", Common.DefaultLanguageCode());
		ErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, 
			String(Object), ErrorDescription);
		
		WriteLogEvent(DataExchangeEventLogEvent(), EventLogLevel.Error,,, MessageString);		
	EndTry
	
EndProcedure

#EndRegion

#Region ProgressBar

// Counting the number of information security objects to be uploaded when creating the initial image.
//
// Parameters:
//   Recipient - ExchangePlanObject -  the exchange plan node corresponding to the recipient.
//
// Returns:
//   Number
//
Function CalculateObjectsCountInInfobase(Recipient)
	
	ExchangePlanName = Recipient.Metadata().Name;
	ObjectsCounter = 0;
	ExchangePlanContent = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	// 
	RefObjectsStructure = New Structure;
	RefObjectsStructure.Insert("Catalog", Metadata.Catalogs);
	RefObjectsStructure.Insert("Document", Metadata.Documents);
	RefObjectsStructure.Insert("ChartOfCharacteristicTypes", Metadata.ChartsOfCharacteristicTypes);
	RefObjectsStructure.Insert("ChartOfCalculationTypes", Metadata.ChartsOfCalculationTypes);
	RefObjectsStructure.Insert("ChartOfAccounts", Metadata.ChartsOfAccounts);
	RefObjectsStructure.Insert("BusinessProcess", Metadata.BusinessProcesses);
	RefObjectsStructure.Insert("Task", Metadata.Tasks);
	RefObjectsStructure.Insert("ChartOfAccounts", Metadata.ChartsOfAccounts);

	LinkRequestTextTemplate = 
	"SELECT
	|	COUNT(AliasOfTheMetadataTable.Ref) AS ObjectCount
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable";
	
	For Each RefObject1 In RefObjectsStructure Do
		
		For Each MetadataObject In RefObject1.Value Do
			
			If ExchangePlanContent.Find(MetadataObject) = Undefined Then
				
				Continue;
				
			EndIf;
			
			FullObjectName = RefObject1.Key + "." + MetadataObject.Name;
			QueryText = StrReplace(LinkRequestTextTemplate, "&MetadataTableName", FullObjectName);
			
			Query = New Query(QueryText);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				ObjectsCounter = ObjectsCounter + Selection.ObjectCount;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	// 
	For Each MetadataObject In Metadata.Constants Do
		If ExchangePlanContent.Find(MetadataObject) = Undefined Then
			Continue;
		EndIf;
		ObjectsCounter = ObjectsCounter + 1;
	EndDo;

	// 
	RequestTextTemplateWithoutARegistrar = 
	"SELECT
	|	COUNT(*) AS ObjectCount
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable";
	
	RequestTextTemplateWithRegistrar = 
	"SELECT
	|	COUNT(DISTINCT AliasOfTheMetadataTable.Recorder) AS ObjectCount
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable";
	
	For Each MetadataObject In Metadata.InformationRegisters Do
		
		If ExchangePlanContent.Find(MetadataObject) = Undefined Then
			
			Continue;
			
		EndIf;
		
		FullObjectName = "InformationRegister."+MetadataObject.Name;
		If MetadataObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.RecorderPosition Then
			
			QueryText = StrReplace(RequestTextTemplateWithRegistrar, "&MetadataTableName", FullObjectName);
			
		Else
			
			QueryText =  StrReplace(RequestTextTemplateWithoutARegistrar, "&MetadataTableName", FullObjectName);
			
		EndIf;
		
		Query = New Query(QueryText);
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			
			ObjectsCounter = ObjectsCounter + Selection.ObjectCount;
			
		EndIf;
		
	EndDo;
	
	// 
	RegistersStructure = New Structure;
	RegistersStructure.Insert("AccumulationRegister", Metadata.AccumulationRegisters);
	RegistersStructure.Insert("CalculationRegister", Metadata.CalculationRegisters);
	RegistersStructure.Insert("AccountingRegister", Metadata.AccountingRegisters);
	RegistersStructure.Insert("Sequence", Metadata.Sequences);

	For Each Register In RegistersStructure Do
		
		For Each MetadataObject In Register.Value Do
			
			If ExchangePlanContent.Find(MetadataObject) = Undefined Then
				
				Continue;
				
			EndIf;
			
			FullObjectName = Register.Key +"."+MetadataObject.Name;
			QueryText = StrReplace(RequestTextTemplateWithRegistrar, "&MetadataTableName", FullObjectName);
			
			Query = New Query(QueryText);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				
				ObjectsCounter = ObjectsCounter + Selection.ObjectCount;
				
			EndIf;
			
		EndDo;
		
	EndDo;

	Return ObjectsCounter;
	
EndFunction

// Counting the number of objects registered in the exchange plan.
//
// Parameters:
//   Recipient - ExchangePlanObject
//
// Returns:
//   Number
//
Function CalculateRegisteredObjectsCount(Recipient) Export
	
	ChangesSelection = ExchangePlans.SelectChanges(Recipient.Ref, Recipient.SentNo + 1);
	ObjectsToExportCount = 0;
	While ChangesSelection.Next() Do
		ObjectsToExportCount = ObjectsToExportCount + 1;
	EndDo;
	Return ObjectsToExportCount;
	
EndFunction

#EndRegion

#Region ExchangeMessageFromMasterNodeConstantOperations

// Reads information about the data exchange message from the information database.
//
// Returns:
//   Structure - 
//                       - BinaryData - 
//
Function DataExchangeMessageFromMasterNode() Export
	
	Return Constants.DataExchangeMessageFromMasterNode.Get().Get();
	
EndFunction

// Writes the exchange message file received from the master node to disk.
// Saves the path to the recorded message in the constant message exchange of the main Node.
//
// Parameters:
//  ExchangeMessage - BinaryData -  a read exchange message.
//  MasterNode - ExchangePlanRef -  the node from which the message was received.
//
Procedure SetDataExchangeMessageFromMasterNode(ExchangeMessage, MasterNode) Export
	
	PathToFile = "[Directory][Path].xml";
	PathToFile = StrReplace(PathToFile, "[Directory]", TempFilesStorageDirectory());
	PathToFile = StrReplace(PathToFile, "[Path]", New UUID);
	
	ExchangeMessage.Write(PathToFile);
	
	MessageStructure = New Structure;
	MessageStructure.Insert("PathToFile", PathToFile);
	
	Constants.DataExchangeMessageFromMasterNode.Set(New ValueStorage(MessageStructure));
	
	WriteDataReceivingEvent(MasterNode, NStr("en = 'The exchange message is cached.';"));
	
EndProcedure

// Deletes the exchange message file from disk and clears the constant of the exchange message from the main Node.
//
Procedure ClearDataExchangeMessageFromMasterNode() Export
	
	ExchangeMessage = DataExchangeMessageFromMasterNode();
	
	If TypeOf(ExchangeMessage) = Type("Structure") Then
		
		DeleteFiles(ExchangeMessage.PathToFile);
		
	EndIf;
	
	Constants.DataExchangeMessageFromMasterNode.Set(New ValueStorage(Undefined));
	
	WriteDataReceivingEvent(MasterNode(), NStr("en = 'The exchange message is deleted from the cache.';"));
	
EndProcedure

#EndRegion

#Region SecurityProfiles

Procedure CreateRequestsToUseExternalResources(PermissionsRequests)
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	Constants.DataExchangeMessageDirectoryForLinux.CreateValueManager().OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	Constants.DataExchangeMessageDirectoryForWindows.CreateValueManager().OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	
	If Common.SeparatedDataUsageAvailable() Then
		InformationRegisters.DataExchangeTransportSettings.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	EndIf;
	
	InformationRegisters.DataExchangeRules.OnFillPermissionsToAccessExternalResources(PermissionsRequests);
	
EndProcedure

// Parameters:
//   PermissionsRequests - Array of UUID -  collection of permission requests.
//   Object - ConstantValueManager -  the Manager of the value of the data object.
//
Procedure RequestExternalResourcesForDataExchangeMessagesDirectory(PermissionsRequests, Object) Export
	
	ConstantValue = Object.Value;
	ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
	If Not IsBlankString(ConstantValue) Then
		
		Permissions = New Array;
		Permissions.Add(ModuleSafeModeManager.PermissionToUseFileSystemDirectory(
			ConstantValue, True, True));
		
		PermissionsRequests.Add(
			ModuleSafeModeManager.RequestToUseExternalResources(Permissions,
				Common.MetadataObjectID(Object.Metadata())));
		
	EndIf;
	
EndProcedure

// Returns the security profile name template for the external module.
// The function must return the same value when called multiple times.
//
// Parameters:
//  ExternalModule - MetadataObjectExchangePlan - 
//
// Returns:
//   String - 
//  
//
Function SecurityProfileNameTemplate(Val ExternalModule) Export
	
	Template = "Exchange_[ExchangePlanName]_%1"; // 
	Return StrReplace(Template, "[ExchangePlanName]", ExternalModule.Name);
	
EndFunction

// Returns an icon displaying the external module.
// 
// Parameters:
//  ExternalModule- AnyRef -  link to the external module
// 
// Returns:
//  Picture - 
//
Function ExternalModuleIcon(Val ExternalModule) Export
	
	Return PictureLib.DataSynchronization;
	
EndFunction

Function ExternalModuleContainerDictionary() Export
	
	Result = New Structure();
	
	Result.Insert("Nominative", NStr("en = 'Data synchronization setup';"));
	Result.Insert("Genitive",  NStr("en = 'Data synchronization settings';"));
	
	Return Result;
	
EndFunction

Function ExternalModulesContainers() Export
	
	Result = New Array();
	DataExchangeOverridable.GetExchangePlans(Result);
	Return Result;
	
EndFunction

#EndRegion

#Region ActionsExecution

Procedure ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(Cancel, InfobaseNode,
	ActionOnExchange,
	TransactionItemsCount,
	MessageForDataMapping = False)
	
	SetPrivilegedMode(True);
	
	// 
	ExchangeSettingsStructure = ExchangeSettingsForExternalConnection(
		InfobaseNode,
		ActionOnExchange,
		TransactionItemsCount);
	
	WriteLogEventDataExchangeStart(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.Cancel Then
		// 
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
		WriteExchangeFinish(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndIf;
	
	ErrorMessageString = "";
	
	// 
	ExternalConnection = DataExchangeCached.GetExternalConnectionForInfobaseNode(
		InfobaseNode,
		ErrorMessageString);
	
	If ExternalConnection = Undefined Then
		
		// 
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		// 
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
		WriteExchangeFinish(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndIf;
	
	// 
	SSLVersionByExternalConnection = ExternalConnection.StandardSubsystemsServer.LibraryVersion();
	ExchangeWithSSL20 = CommonClientServer.CompareVersions("2.1.1.10", SSLVersionByExternalConnection) > 0;
	
	// 
	Structure = New Structure("ExchangePlanName, CorrespondentExchangePlanName, 
		|CurrentExchangePlanNodeCode1, TransactionItemsCount");
	
	FillPropertyValues(Structure, ExchangeSettingsStructure);
	
	// 
	ActionOnStringExchange = ?(ActionOnExchange = Enums.ActionsOnExchange.DataExport,
								Common.EnumerationValueName(Enums.ActionsOnExchange.DataImport),
								Common.EnumerationValueName(Enums.ActionsOnExchange.DataExport));
	//
	
	Structure.Insert("ActionOnStringExchange", ActionOnStringExchange);
	Structure.Insert("DebugMode", False);
	Structure.Insert("ExchangeProtocolFileName", "");
	
	IsXDTOExchangePlan = IsXDTOExchangePlan(InfobaseNode);
	If IsXDTOExchangePlan Then
		// 
		PredefinedNodeAlias = PredefinedNodeAlias(InfobaseNode);
		ExchangePlanManager = ExternalConnection.ExchangePlans[Structure.CorrespondentExchangePlanName];
		CheckNodeExistenceInCorrespondent = True;
		If ValueIsFilled(PredefinedNodeAlias) Then
			// 
			// 
			If ExchangePlanManager.FindByCode(PredefinedNodeAlias) <> ExchangePlanManager.EmptyRef() Then
				Structure.CurrentExchangePlanNodeCode1 = PredefinedNodeAlias;
				CheckNodeExistenceInCorrespondent = False;
			EndIf;
		EndIf;
		If CheckNodeExistenceInCorrespondent Then
			ExchangePlanRef = ExchangePlanManager.FindByCode(Structure.CurrentExchangePlanNodeCode1);
			If Not ValueIsFilled(ExchangePlanRef.Code) Then
				// 
				MessageText = NStr("en = 'Switch the peer infobase to Interim Format Data Exchange.';");
				WriteEventLogDataExchange(MessageText, ExchangeSettingsStructure, False);

				ParametersStructure = New Structure();
				ParametersStructure.Insert("Code", Structure.CurrentExchangePlanNodeCode1);
				ParametersStructure.Insert("SettingsMode", 
					Common.ObjectAttributeValue(InfobaseNode, "SettingsMode"));
				ParametersStructure.Insert("Error", False);
				ParametersStructure.Insert("ErrorMessage", "");
				
				HasErrors = False;
				ErrorMessageString = "";
				TransferResult = 
					ExchangePlanManager.SwitchingToSynchronizationViaUniversalFormatExternalConnection(ParametersStructure);
				If ParametersStructure.Error Then
					HasErrors = True;
					NString = NStr("en = 'Error switching to Interim Format Data Exchange: %1. The exchange is canceled.';",
						Common.DefaultLanguageCode());
					ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NString, 
						ParametersStructure.ErrorMessage);
				ElsIf TransferResult = Undefined Then
					HasErrors = True;
					ErrorMessageString = NStr("en = 'Switching to Interim Format Data Exchange failed';");
				EndIf;
				If HasErrors Then
					WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
					ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
					WriteExchangeFinish(ExchangeSettingsStructure);
					Cancel = True;
					Return;
				Else
					Message = NStr("en = 'Switching Interim Format Data Exchange completed.';");
					WriteEventLogDataExchange(Message, ExchangeSettingsStructure, False);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
	CorrespondentStructure = Common.CopyRecursive(Structure, False);
	CorrespondentStructure.ExchangePlanName = Structure.CorrespondentExchangePlanName;
	CorrespondentStructure.CorrespondentExchangePlanName = Structure.ExchangePlanName;
	
	Try
		ExchangeSettingsStructureExternalConnection = ExternalConnection.DataExchangeExternalConnection.ExchangeSettingsStructure(CorrespondentStructure);
	Except
		WriteEventLogDataExchange(ErrorProcessing.DetailErrorDescription(ErrorInfo()),
			ExchangeSettingsStructure, True);
		
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
		WriteExchangeFinish(ExchangeSettingsStructure);
		Cancel = True;
		Return;
	EndTry;
	
	If ExchangeSettingsStructureExternalConnection.Property("DataSynchronizationSetupCompleted") Then
		If Not MessageForDataMapping
			And ExchangeSettingsStructureExternalConnection.DataSynchronizationSetupCompleted = False Then
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'To continue, set up synchronization in ""%1"".
				|The data exchange is canceled.';"),
				ExchangeSettingsStructureExternalConnection.InfobaseNodeDescription);
			WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
			WriteExchangeFinish(ExchangeSettingsStructure);
			Cancel = True;
			Return;
			
		EndIf;
	EndIf;
	
	If ExchangeSettingsStructureExternalConnection.Property("MessageReceivedForDataMapping") Then
		If Not MessageForDataMapping
			And ExchangeSettingsStructureExternalConnection.MessageReceivedForDataMapping = True Then
			
			ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'To continue, open %1 and import the data mapping message.
				|The data exchange is canceled.';"),
				ExchangeSettingsStructureExternalConnection.InfobaseNodeDescription);
			WriteEventLogDataExchange(ErrorMessage, ExchangeSettingsStructure, True);
			
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
			WriteExchangeFinish(ExchangeSettingsStructure);
			Cancel = True;
			Return;
			
		EndIf;
	EndIf;
	
	ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
	ExchangeSettingsStructureExternalConnection.Insert("StartDate", ExternalConnection.CurrentSessionDate());
	
	ExternalConnection.DataExchangeExternalConnection.WriteLogEventDataExchangeStart(ExchangeSettingsStructureExternalConnection);
	// 
	If ExchangeSettingsStructure.DoDataImport Then
		If Not IsXDTOExchangePlan Then
			// 
			ObjectsConversionRules = ExternalConnection.DataExchangeExternalConnection.GetObjectConversionRules(ExchangeSettingsStructureExternalConnection.ExchangePlanName);
			
			If ObjectsConversionRules = Undefined Then
				
				// 
				NString = NStr("en = 'Conversion rules are not specified for exchange plan %1 in the second infobase. The exchange is canceled.';",
					Common.DefaultLanguageCode());
				ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NString, ExchangeSettingsStructureExternalConnection.ExchangePlanName);
				WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
				WriteExchangeInitializationFinish(ExchangeSettingsStructure);
				Return;
			EndIf;
		EndIf;
		
		// 
		DataProcessorForDataImport = ExchangeSettingsStructure.DataExchangeDataProcessor;
		DataProcessorForDataImport.ExchangeFileName = "";
		DataProcessorForDataImport.ObjectCountPerTransaction = ExchangeSettingsStructure.TransactionItemsCount;
		DataProcessorForDataImport.UseTransactions = (DataProcessorForDataImport.ObjectCountPerTransaction <> 1);
		DataProcessorForDataImport.DataImportedOverExternalConnection = True;
		
		// 
		If IsXDTOExchangePlan Then
			DataExchangeDataProcessorExternalConnection = ExternalConnection.DataProcessors.ConvertXTDOObjects.Create();
			DataExchangeDataProcessorExternalConnection.ExchangeMode = "Upload0";
		Else
			DataExchangeDataProcessorExternalConnection = ExternalConnection.DataProcessors.InfobaseObjectConversion.Create();
			DataExchangeDataProcessorExternalConnection.SavedSettings = ObjectsConversionRules;
			DataExchangeDataProcessorExternalConnection.DataImportExecutedInExternalConnection = False;
			DataExchangeDataProcessorExternalConnection.ExchangeMode = "Upload0";
			Try
				DataExchangeDataProcessorExternalConnection.RestoreRulesFromInternalFormat();
			Except
				WriteEventLogDataExchange(
					StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Error occurred in peer infobase: %1';"),
					ErrorProcessing.DetailErrorDescription(ErrorInfo())), ExchangeSettingsStructure, True);
				
				// 
				ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
				WriteExchangeFinish(ExchangeSettingsStructure);
				Cancel = True;
				Return;
			EndTry;
			// 
			DataExchangeDataProcessorExternalConnection.BackgroundExchangeNode = Undefined;
			DataExchangeDataProcessorExternalConnection.DontExportObjectsByRefs = True;
			DataExchangeDataProcessorExternalConnection.ExchangeRulesFileName = "1";
			DataExchangeDataProcessorExternalConnection.ExternalConnection = Undefined;
		EndIf;

		DataExchangeDataProcessorExternalConnection.NodeForExchange = ExchangeSettingsStructureExternalConnection.InfobaseNode;
		If DataExchangeDataProcessorExternalConnection.Metadata().Attributes.Find("SetExchangePlanNodeLock") <> Undefined Then
			
			DataExchangeDataProcessorExternalConnection.SetExchangePlanNodeLock = True;
			
		EndIf;
		
		SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessorExternalConnection, ExchangeSettingsStructureExternalConnection, ExchangeWithSSL20);
		
		If Not IsXDTOExchangePlan Then
			DestinationConfigurationVersion = "";
			SourceVersionFromRules = "";
			MessageText = "";
			ExternalConnectionParameters = New Structure;
			ExternalConnectionParameters.Insert("ExternalConnection", ExternalConnection);
			ExternalConnectionParameters.Insert("SSLVersionByExternalConnection", SSLVersionByExternalConnection);
			ExternalConnectionParameters.Insert("EventLogMessageKey", ExchangeSettingsStructureExternalConnection.EventLogMessageKey);
			ExternalConnectionParameters.Insert("InfobaseNode", ExchangeSettingsStructureExternalConnection.InfobaseNode);
			
			ObjectsConversionRules.Get().Conversion.Property("SourceConfigurationVersion", DestinationConfigurationVersion);
			DataProcessorForDataImport.SavedSettings.Get().Conversion.Property("SourceConfigurationVersion", SourceVersionFromRules);
			
			If DifferentCorrespondentVersions(ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.EventLogMessageKey,
				SourceVersionFromRules, DestinationConfigurationVersion, MessageText, ExternalConnectionParameters) Then
				
				DataExchangeDataProcessorExternalConnection = Undefined;
				Return;
				
			EndIf;
		EndIf;
		// 
		DataExchangeDataProcessorExternalConnection.RunDataExport(DataProcessorForDataImport);
		
		// 
		ExchangeSettingsStructure.ExchangeExecutionResult    = DataProcessorForDataImport.ExchangeExecutionResult();
		ExchangeSettingsStructure.ProcessedObjectsCount = DataProcessorForDataImport.ImportedObjectCounter();
		ExchangeSettingsStructureExternalConnection.ExchangeExecutionResultString = DataExchangeDataProcessorExternalConnection.ExchangeExecutionResultString();
		ExchangeSettingsStructureExternalConnection.ProcessedObjectsCount     = DataExchangeDataProcessorExternalConnection.ExportedObjectCounter();
		ExchangeSettingsStructure.MessageOnExchange           = DataProcessorForDataImport.CommentOnDataImport;
		ExchangeSettingsStructure.ErrorMessageString      = DataProcessorForDataImport.ErrorMessageString();
		ExchangeSettingsStructureExternalConnection.MessageOnExchange               = DataExchangeDataProcessorExternalConnection.CommentOnDataExport;
		ExchangeSettingsStructureExternalConnection.ErrorMessageString          = DataExchangeDataProcessorExternalConnection.ErrorMessageString();
		
		DataExchangeDataProcessorExternalConnection = Undefined;
		
	ElsIf ExchangeSettingsStructure.DoDataExport Then
				
		// 
		If IsXDTOExchangePlan Then
			DataProcessorForDataImport = ExternalConnection.DataProcessors.ConvertXTDOObjects.Create();
		Else
			DataProcessorForDataImport = ExternalConnection.DataProcessors.InfobaseObjectConversion.Create();
			DataProcessorForDataImport.DataImportedOverExternalConnection = True;
		EndIf;
		DataProcessorForDataImport.ExchangeMode = "Load";
		DataProcessorForDataImport.ExchangeNodeDataImport = ExchangeSettingsStructureExternalConnection.InfobaseNode;
		
		SetCommonParametersForDataExchangeProcessing(DataProcessorForDataImport, ExchangeSettingsStructureExternalConnection, ExchangeWithSSL20);
		
		HasMapSupport            = True;
		DataSynchronizationSetupCompleted = True;
		InterfaceVersions = InterfaceVersionsThroughExternalConnection(ExternalConnection);

		If InterfaceVersions.Find("3.0.1.1") <> Undefined
			Or InterfaceVersions.Find("3.0.2.1") <> Undefined Then
			
			ErrorMessage = "";
			InfoBaseAdmParams = ExternalConnection.DataExchangeExternalConnection.GetInfobaseParameters_2_0_1_6(
				ExchangeSettingsStructure.ExchangePlanName, ExchangeSettingsStructure.CurrentExchangePlanNodeCode1, ErrorMessage);
			CorrespondentParameters = Common.ValueFromXMLString(InfoBaseAdmParams);
			If CorrespondentParameters.Property("DataMappingSupported") Then
				HasMapSupport = CorrespondentParameters.DataMappingSupported;
			EndIf;
			If CorrespondentParameters.Property("DataSynchronizationSetupCompleted") Then
				DataSynchronizationSetupCompleted = CorrespondentParameters.DataSynchronizationSetupCompleted;
			EndIf;
			
		EndIf;
		
		If MessageForDataMapping
			And (HasMapSupport Or Not DataSynchronizationSetupCompleted) Then
			DataProcessorForDataImport.DataImportMode = "ImportMessageForDataMapping";
		EndIf;
		
		DataProcessorForDataImport.ObjectCountPerTransaction = ExchangeSettingsStructure.TransactionItemsCount;
		DataProcessorForDataImport.UseTransactions = (DataProcessorForDataImport.ObjectCountPerTransaction <> 1);
		
		// 
		DataExchangeXMLDataProcessor = ExchangeSettingsStructure.DataExchangeDataProcessor; //DataProcessorObject.ConvertXTDOObjects
		DataExchangeXMLDataProcessor.ExchangeFileName = "";
		
		If Not IsXDTOExchangePlan Then
			
			DataExchangeXMLDataProcessor.ExternalConnection = ExternalConnection;
			DataExchangeXMLDataProcessor.DataImportExecutedInExternalConnection = True;
			
		EndIf;
		
		// 
		DataExchangeXMLDataProcessor.RunDataExport(DataProcessorForDataImport);
		
		// 
		ExchangeSettingsStructure.ExchangeExecutionResult    = DataExchangeXMLDataProcessor.ExchangeExecutionResult();
		ExchangeSettingsStructure.ProcessedObjectsCount = DataExchangeXMLDataProcessor.ExportedObjectCounter();
		ExchangeSettingsStructureExternalConnection.ExchangeExecutionResultString = DataProcessorForDataImport.ExchangeExecutionResultString();
		ExchangeSettingsStructureExternalConnection.ProcessedObjectsCount     = DataProcessorForDataImport.ImportedObjectCounter();
		ExchangeSettingsStructure.MessageOnExchange           = DataExchangeXMLDataProcessor.CommentOnDataExport;
		ExchangeSettingsStructure.ErrorMessageString      = DataExchangeXMLDataProcessor.ErrorMessageString();
		ExchangeSettingsStructureExternalConnection.MessageOnExchange               = DataProcessorForDataImport.CommentOnDataImport;
		ExchangeSettingsStructureExternalConnection.ErrorMessageString          = DataProcessorForDataImport.ErrorMessageString();
		DataProcessorForDataImport = Undefined;
		
	EndIf;
	
	WriteExchangeFinish(ExchangeSettingsStructure);
	
	ExternalConnection.DataExchangeExternalConnection.WriteExchangeFinish(ExchangeSettingsStructureExternalConnection);
	
	If Not ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
		
		Cancel = True;
		
	EndIf;
	
EndProcedure

Procedure ExecuteDataExchangeOverFileResource(ExchangeSettingsStructure, Val ParametersOnly = False)
	
	If ExchangeSettingsStructure.DoDataImport Then
		
		If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
			ExecuteDataExchangeWithExternalSystemDataImport(ExchangeSettingsStructure);
			Return;
		EndIf;
		
		// 
		ExchangeMessage = "";
		StandardProcessing = True;
		
		BeforeReadExchangeMessage(ExchangeSettingsStructure.InfobaseNode, ExchangeMessage, StandardProcessing);
		// 
		
		If StandardProcessing Then
			
			ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure);
			
			If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
				
				ExecuteExchangeMessageTransportReceiving(ExchangeSettingsStructure);
				
				If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
					
					ExchangeMessage = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileName();
					
				EndIf;
				
			EndIf;
			
		EndIf;
			
		// 
		If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
			
			HasMapSupport = ExchangePlanSettingValue(
				DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode),
				"DataMappingSupported",
				SavedExchangePlanNodeSettingOption(ExchangeSettingsStructure.InfobaseNode));
			
			If ExchangeSettingsStructure.AdditionalParameters.Property("MessageForDataMapping")
				And (HasMapSupport 
					Or Not SynchronizationSetupCompleted(ExchangeSettingsStructure.InfobaseNode)) Then
				
				NameOfFileToPutInStorage = CommonClientServer.GetFullFileName(
					TempFilesStorageDirectory(),
					UniqueExchangeMessageFileName());
					
				// 
				FileID = PutFileInStorage(NameOfFileToPutInStorage);
				MoveFile(ExchangeMessage, NameOfFileToPutInStorage);
				
				DataExchangeInternal.PutMessageForDataMapping(
					ExchangeSettingsStructure.InfobaseNode, FileID);
				
				StandardProcessing = True;
			Else
				
				ReadMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeMessage, , ParametersOnly);
				
				// 
				StandardProcessing = True;
				
				AfterReadExchangeMessage(
							ExchangeSettingsStructure.InfobaseNode,
							ExchangeMessage,
							ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
							StandardProcessing,
							Not ParametersOnly);
				// 
				
			EndIf;
			
		EndIf;
		
		// 
		StandardProcessing = True;
		
		AfterReadExchangeMessage(
					ExchangeSettingsStructure.InfobaseNode,
					ExchangeMessage,
					ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult),
					StandardProcessing,
					Not ParametersOnly);
		// 
		
		If StandardProcessing Then
			
			ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure);
			
		EndIf;
		
	ElsIf ExchangeSettingsStructure.DoDataExport Then
		
		If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
			ExecuteDataExchangeWithExternalSystemExportXDTOSettings(ExchangeSettingsStructure);
			Return;
		EndIf;
		
		ExecuteExchangeMessageTransportBeforeProcessing(ExchangeSettingsStructure);
		
		// 
		If ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
			
			WriteMessageWithNodeChanges(ExchangeSettingsStructure, ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor.ExchangeMessageFileName());
			
		EndIf;
		
		// 
		If ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) Then
			
			ExecuteExchangeMessageTransportSending(ExchangeSettingsStructure);
			
		EndIf;
		
		ExecuteExchangeMessageTransportAfterProcessing(ExchangeSettingsStructure);
		
	EndIf;
	
EndProcedure

// Performs the data exchange process separately for each line of the exchange script (settings).
// The data exchange process consists of two stages:
// - initialization of the exchange - preparation of the data exchange subsystem for the exchange process
// - data exchange is the process of reading a message file with subsequent loading of this data into the information system 
//                          or uploading changes to the message file.
// The initialization stage is performed once per session and is stored in the session cache on the server 
// until the session is restarted or the values of the data exchange subsystem are reset.
// Reset of reused values occurs when data changes that affect the data exchange process
// (transport settings, exchange execution settings, selection settings on exchange plan nodes).
//
// The exchange can be performed completely for all lines of the script,
// or it can be performed for a separate line of the PM exchange script.
//
// Parameters:
//  Cancel                     - Boolean -  failure flag; raised if an error occurs during script execution.
//  ExchangeExecutionSettings - CatalogRef.DataExchangeScenarios -  a reference
//                              list element that will be used for data exchange.
//  LineNumber               - Number -  number of the line that will be used for data exchange.
//                              If not specified, then the data exchange will be executed for all rows.
// 
Procedure ExecuteDataExchangeByDataExchangeScenario(Cancel, ExchangeExecutionSettings, LineNumber = Undefined) Export
	
	SetPrivilegedMode(True);
	
	IsSubordinateDIBNodeRequiringUpdate = (IsSubordinateDIBNode() And UpdateInstallationRequired());
	
	QueryText =
	"SELECT
	|	ExchangeExecutionSettingsExchangeSettings.Ref                         AS ExchangeExecutionSettings,
	|	ExchangeExecutionSettingsExchangeSettings.LineNumber                    AS LineNumber,
	|	ExchangeExecutionSettingsExchangeSettings.CurrentAction            AS CurrentAction,
	|	ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind            AS ExchangeTransportKind,
	|	ExchangeExecutionSettingsExchangeSettings.InfobaseNode         AS InfobaseNode,
	|
	|	CASE WHEN ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.COM)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ExchangeOverExternalConnection,
	|
	|	CASE WHEN ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.WS)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ExchangeOverWebService,
	|
	|	CASE WHEN ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind = VALUE(Enum.ExchangeMessagesTransportTypes.ExternalSystem)
	|		THEN TRUE
	|		ELSE FALSE
	|	END AS ExchangeWithExternalSystem
	|FROM
	|	Catalog.DataExchangeScenarios.ExchangeSettings AS ExchangeExecutionSettingsExchangeSettings
	|WHERE
	|	ExchangeExecutionSettingsExchangeSettings.Ref = &ExchangeExecutionSettings
	|		AND &LineNumberCondition
	|
	|ORDER BY
	|	ExchangeExecutionSettingsExchangeSettings.LineNumber";
	
	LineNumberCondition = ?(LineNumber = Undefined, "", "AND ExchangeExecutionSettingsExchangeSettings.LineNumber = &LineNumber");
	
	QueryText = StrReplace(QueryText, "AND &LineNumberCondition", LineNumberCondition);
	
	Query = New Query(QueryText);
	Query.SetParameter("ExchangeExecutionSettings", ExchangeExecutionSettings);
	Query.SetParameter("LineNumber", LineNumber);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		If IsSubordinateDIBNodeRequiringUpdate
			And DataExchangeCached.IsDistributedInfobaseNode(Selection.InfobaseNode) Then
			
			Continue;
			
		EndIf;
		
		If Not SynchronizationSetupCompleted(Selection.InfobaseNode)
			And Not Selection.ExchangeWithExternalSystem Then
			
			Continue;
			
		EndIf;
		
		CancelByScenarioString = False;
		
		BeforePerformingExchanges(Selection.InfobaseNode, CancelByScenarioString);
		If CancelByScenarioString Then
			
			Cancel = True;
			Continue;
			
		EndIf;
		
		If Selection.ExchangeOverExternalConnection Then
			
			CheckExternalConnectionAvailability();
			
			TransactionItemsCount = ItemsCountInTransactionOfActionToExecute(Selection.CurrentAction);
			
			ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(CancelByScenarioString,
				Selection.InfobaseNode, Selection.CurrentAction, TransactionItemsCount);
			
		ElsIf Selection.ExchangeOverWebService Then
			
			ExchangeParameters = ExchangeParameters();
			ExchangeParameters.TimeConsumingOperationAllowed = True;
			ExchangeParameters.TheTimeoutOnTheServer = 30;
			
			DataExchangeWebService.ExecuteExchangeActionForInfobaseNodeUsingWebService(CancelByScenarioString,
				Selection.InfobaseNode, Selection.CurrentAction, ExchangeParameters);
			
		Else
			
			// 
			ExchangeSettingsStructure = DataExchangeSettings(Selection.ExchangeExecutionSettings, Selection.LineNumber);
			
			// 
			If ExchangeSettingsStructure.Cancel Then
				
				CancelByScenarioString = True;
				
			Else
				
				ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
				
				// 
				MessageString = NStr("en = 'Data exchange started. Setting: %1';", Common.DefaultLanguageCode());
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.ExchangeExecutionSettingDescription);
				WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
				
				// 
				ExecuteDataExchangeOverFileResource(ExchangeSettingsStructure);
				
				CancelByScenarioString = (ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult) <> True);
				
			EndIf;
			
			// 
			WriteExchangeFinish(ExchangeSettingsStructure);
			
		EndIf;
		
		AfterPerformingTheExchanges(Selection.InfobaseNode, CancelByScenarioString);
		
		If CancelByScenarioString Then
			
			Cancel = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// The entry point for executing data exchange according to the scenario of sharing a regular job.
//
// Parameters:
//  ExchangeScenarioCode - String -  code of the "data exchange Scenarios" reference element for which data exchange will be performed
//                               .
// 
Procedure ExecuteDataExchangeByScheduledJob(ExchangeScenarioCode) Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DataSynchronization);
	
	If Not ValueIsFilled(ExchangeScenarioCode) Then
		
		Raise NStr("en = 'Data exchange scenario not specified.';");
		
	EndIf;
		
	Query = New Query;
	Query.SetParameter("Code", ExchangeScenarioCode);
	
	Query.Text = 
	"SELECT
	|	DataExchangeScenarios.Ref AS Ref
	|FROM
	|	Catalog.DataExchangeScenarios AS DataExchangeScenarios
	|WHERE
	|		 DataExchangeScenarios.Code = &Code
	|	AND NOT DataExchangeScenarios.DeletionMark
	|";
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		
		MessageString = NStr("en = 'Data exchange scenario with code %1 is not found.';");
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeScenarioCode);
		Raise MessageString;
		
	EndIf;
	
	Selection = QueryResult.Select();
	If Selection.Next() Then
		
		ExecuteDataExchangeByDataExchangeScenario(False, Selection.Ref);
		
	EndIf;
	
EndProcedure

// The entry point for performing the data exchange iteration is loading and unloading data for the exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef -  the exchange plan node for which the data exchange iteration is performed.
//  ExchangeParameters - Structure:
//    * ExecuteImport1 - Boolean -  flag of the need to load data.
//        Optional, the default value is True.
//    * ExecuteExport2 - Boolean -  flag of the need to perform data unloading.
//        Optional, the default value is True.
//    * ExchangeMessagesTransportKind - EnumRef.ExchangeMessagesTransportTypes -  the type of transport 
//        that will be used in the data exchange process. 
//        If the value is not set in the PC, then the default value is Enumerations.viewtransportcommunication exchange.FILE.
//        Optional, the default value is Undefined.
//    * TimeConsumingOperation - Boolean -  contains information about whether the operation is lengthy.
//        Optional, the default value is False.
//    * OperationID - String -  contains the ID of a long-running operation in the form of a string.
//        Optional, the default value is an empty string.
//    * FileID - String -  id of the message file in the service.
//        Optional, the default value is an empty string.
//    * TimeConsumingOperationAllowed - Boolean -  contains a sign that a long-term operation is allowed.
//        Optional, the default value is False.
//    * AuthenticationParameters - Structure -  contains authentication parameters for exchange via a Web service.
//        Optional, the default value is Undefined.
//    * ParametersOnly - Boolean -  contains a sign of selective data loading during the exchange of RIB.
//        Optional, the default value is False.
//  Cancel - Boolean -  failure flag; raised if an error occurs during the exchange.
//  AdditionalParameters - Structure -  reserved for service use.
// 
Procedure ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel, AdditionalParameters = Undefined) Export
	
	BeforePerformingExchanges(InfobaseNode, Cancel);
	
	If Cancel = True Then
		
		Return;
		
	EndIf;
	
	ActionImport = Enums.ActionsOnExchange.DataImport;
	ActionExport = Enums.ActionsOnExchange.DataExport;
	
	If AdditionalParameters = Undefined Then
		
		AdditionalParameters = New Structure;
		
	EndIf;
	
	// 
	If ExchangeParameters.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		
		CheckExternalConnectionAvailability();
		
		If ExchangeParameters.ExecuteImport1 Then
			ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(Cancel,
				InfobaseNode, ActionImport, Undefined);
		EndIf;
		
		If ExchangeParameters.ExecuteExport2 Then
			ExecuteExchangeActionForInfobaseNodeUsingExternalConnection(Cancel,
				InfobaseNode, ActionExport, Undefined, ExchangeParameters.MessageForDataMapping);
		EndIf;
		
	ElsIf ExchangeParameters.ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WS Then // 
		
		If ExchangeParameters.ExecuteImport1 Then
			DataExchangeWebService.ExecuteExchangeActionForInfobaseNodeUsingWebService(Cancel,
				InfobaseNode, ActionImport, ExchangeParameters);
		EndIf;
		
		If ExchangeParameters.ExecuteExport2 Then
			DataExchangeWebService.ExecuteExchangeActionForInfobaseNodeUsingWebService(Cancel,
				InfobaseNode, ActionExport, ExchangeParameters);
		EndIf;
			
	Else // 
		
		ParametersOnly = ExchangeParameters.ParametersOnly;
		ExchangeMessagesTransportKind = ExchangeParameters.ExchangeMessagesTransportKind;
		
		If ExchangeParameters.ExecuteImport1 Then
			ExecuteExchangeActionForInfobaseNode(Cancel, InfobaseNode,
				ActionImport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
		EndIf;
		
		If ExchangeParameters.ExecuteExport2 Then
			ExecuteExchangeActionForInfobaseNode(Cancel, InfobaseNode,
				ActionExport, ExchangeMessagesTransportKind, ParametersOnly, AdditionalParameters);
		EndIf;
		
	EndIf;
	
	AfterPerformingTheExchanges(InfobaseNode, Cancel);
	
EndProcedure

#EndRegion

#Region ForWorkViaExternalConnection_Private

Procedure ExportToTempStorageForInfobaseNode(Val ExchangePlanName, Val InfobaseNodeCode, Address) Export
	
	FullNameOfExchangeMessageFile = GetTempFileName("xml");
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = FullNameOfExchangeMessageFile;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	Address = PutToTempStorage(New BinaryData(FullNameOfExchangeMessageFile));
	
	DeleteFiles(FullNameOfExchangeMessageFile);
	
EndProcedure

Procedure ExportForInfobaseNodeViaFile(Val ExchangePlanName,
	Val InfobaseNodeCode,
	Val FullNameOfExchangeMessageFile) Export
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.FullNameOfExchangeMessageFile = FullNameOfExchangeMessageFile;
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
EndProcedure

Procedure ExportForInfobaseNodeViaString(Val ExchangePlanName, Val InfobaseNodeCode, ExchangeMessage) Export
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataExport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	DataExchangeParameters.ExchangeMessage               = ExchangeMessage;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	ExchangeMessage = DataExchangeParameters.ExchangeMessage;
	
EndProcedure

Procedure ImportForInfobaseNodeViaString(Val ExchangePlanName, Val InfobaseNodeCode, ExchangeMessage) Export
	
	DataExchangeParameters = DataExchangeParametersThroughFileOrString();
	
	DataExchangeParameters.ActionOnExchange             = Enums.ActionsOnExchange.DataImport;
	DataExchangeParameters.ExchangePlanName                = ExchangePlanName;
	DataExchangeParameters.InfobaseNodeCode     = InfobaseNodeCode;
	DataExchangeParameters.ExchangeMessage               = ExchangeMessage;
	
	ExecuteDataExchangeForInfobaseNodeOverFileOrString(DataExchangeParameters);
	
	ExchangeMessage = DataExchangeParameters.ExchangeMessage;
	
EndProcedure

Procedure WriteExchangeFinishUsingExternalConnection(ExchangeSettingsStructure) Export
	
	SetPrivilegedMode(True);
	
	WriteExchangeFinish(ExchangeSettingsStructure);
	
EndProcedure

Function ExchangeOverExternalConnectionSettingsStructure(Structure) Export
	
	CheckDataExchangeUsage();
	
	SetPrivilegedMode(True);
	
	InfobaseNode = ExchangePlans[Structure.ExchangePlanName].FindByCode(Structure.CurrentExchangePlanNodeCode1);
	
	ActionOnExchange = Enums.ActionsOnExchange[Structure.ActionOnStringExchange];
	
	ExchangeSettingsStructureExternalConnection = New Structure;
	ExchangeSettingsStructureExternalConnection.Insert("ExchangePlanName",                   Structure.ExchangePlanName);
	ExchangeSettingsStructureExternalConnection.Insert("DebugMode",                     Structure.DebugMode);
	
	ExchangeSettingsStructureExternalConnection.Insert("InfobaseNode",             InfobaseNode);
	ExchangeSettingsStructureExternalConnection.Insert("InfobaseNodeDescription", String(InfobaseNode));
	
	ExchangeSettingsStructureExternalConnection.Insert("EventLogMessageKey",  EventLogMessageKey(InfobaseNode, ActionOnExchange));
	
	ExchangeSettingsStructureExternalConnection.Insert("ExchangeExecutionResult",        Undefined);
	ExchangeSettingsStructureExternalConnection.Insert("ExchangeExecutionResultString", "");
	
	ExchangeSettingsStructureExternalConnection.Insert("ActionOnExchange", ActionOnExchange);
	
	ExchangeSettingsStructureExternalConnection.Insert("ExportHandlersDebug ", False);
	ExchangeSettingsStructureExternalConnection.Insert("ImportHandlersDebug", False);
	ExchangeSettingsStructureExternalConnection.Insert("ExportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructureExternalConnection.Insert("ImportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructureExternalConnection.Insert("DataExchangeLoggingMode", False);
	ExchangeSettingsStructureExternalConnection.Insert("ExchangeProtocolFileName", "");
	ExchangeSettingsStructureExternalConnection.Insert("ContinueOnError", False);
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructureExternalConnection, True);
	
	ExchangeSettingsStructureExternalConnection.Insert("ProcessedObjectsCount", 0);
	
	ExchangeSettingsStructureExternalConnection.Insert("StartDate",    Undefined);
	ExchangeSettingsStructureExternalConnection.Insert("EndDate", Undefined);
	
	ExchangeSettingsStructureExternalConnection.Insert("MessageOnExchange",      "");
	ExchangeSettingsStructureExternalConnection.Insert("ErrorMessageString", "");
	
	ExchangeSettingsStructureExternalConnection.Insert("TransactionItemsCount", Structure.TransactionItemsCount);
	
	ExchangeSettingsStructureExternalConnection.Insert("IsDIBExchange", False);
	
	ExchangeSettingsStructureExternalConnection.Insert("DataSynchronizationSetupCompleted",     False);
	ExchangeSettingsStructureExternalConnection.Insert("MessageReceivedForDataMapping",   False);
	ExchangeSettingsStructureExternalConnection.Insert("DataMappingSupported",         True);
	
	If ValueIsFilled(InfobaseNode) Then
		ExchangeSettingsStructureExternalConnection.DataSynchronizationSetupCompleted   = SynchronizationSetupCompleted(InfobaseNode);
		ExchangeSettingsStructureExternalConnection.MessageReceivedForDataMapping = MessageWithDataForMappingReceived(InfobaseNode);
		ExchangeSettingsStructureExternalConnection.DataMappingSupported = ExchangePlanSettingValue(Structure.ExchangePlanName,
			"DataMappingSupported", SavedExchangePlanNodeSettingOption(InfobaseNode));
	EndIf;
	
	Return ExchangeSettingsStructureExternalConnection;
EndFunction

Function GetObjectConversionRulesViaExternalConnection(ExchangePlanName, GetCorrespondentRules = False) Export
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.DataExchangeRules.ParsedRulesOfObjectConversion(ExchangePlanName, GetCorrespondentRules);
	
EndFunction

Procedure ExecuteDataExchangeWithExternalSystemDataImport(ExchangeSettingsStructure)
	
	TempDirectoryName = CreateTempExchangeMessagesDirectory();
	
	MessageFileName = CommonClientServer.GetFullFileName(
		TempDirectoryName, UniqueExchangeMessageFileName());
		
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor; // 
	
	MessageReceived = False;
	Try
		MessageReceived = ExchangeMessageTransportDataProcessor.GetMessage(MessageFileName);
	Except
		Information = ErrorInfo();
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport;
		WriteEventLogDataExchange(ErrorProcessing.DetailErrorDescription(Information), ExchangeSettingsStructure, True);
	EndTry;
	
	MessageProcessed = False;
	ExecuteHandlerAfterImport = False;
	
	If MessageReceived
		And ExchangeSettingsStructure.ExchangeExecutionResult = Undefined Then
		
		ExecuteHandlerAfterImport = True;
		
		ReadMessageWithNodeChanges(ExchangeSettingsStructure, MessageFileName);
		
		MessageProcessed = ExchangeExecutionResultCompleted(ExchangeSettingsStructure.ExchangeExecutionResult);
		
	EndIf;
	
	Try
		DeleteFiles(TempDirectoryName);
	Except
		WriteEventLogDataExchange(ErrorProcessing.DetailErrorDescription(Information), ExchangeSettingsStructure);
	EndTry;
	
	SettingCompleted = SynchronizationSetupCompleted(ExchangeSettingsStructure.InfobaseNode);
	
	If ExecuteHandlerAfterImport Then
		HasNextMessage = False;
		Try
			ExchangeMessageTransportDataProcessor.AfterProcessingReceivedMessage(MessageProcessed, HasNextMessage);
		Except
			Information = ErrorInfo();
			ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport;
			WriteEventLogDataExchange(ErrorProcessing.DetailErrorDescription(Information), ExchangeSettingsStructure, True);
			HasNextMessage = False;
		EndTry;
		
		If MessageProcessed
			And Not SettingCompleted Then
			
			ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
			
			If HasExchangePlanManagerAlgorithm("BeforeDataSynchronizationSetup", ExchangePlanName) Then
		
				Context = New Structure;
				Context.Insert("Peer",          ExchangeSettingsStructure.InfobaseNode);
				Context.Insert("SettingID", SavedExchangePlanNodeSettingOption(ExchangeSettingsStructure.InfobaseNode));
				Context.Insert("InitialSetting",     Not SettingCompleted);
				
				WizardFormName  = "";
				
				ExchangePlans[ExchangePlanName].BeforeDataSynchronizationSetup(Context, SettingCompleted, WizardFormName);
				
				If SettingCompleted Then
					CompleteDataSynchronizationSetup(ExchangeSettingsStructure.InfobaseNode);
				EndIf;
				
			EndIf;
			
		EndIf;
		
		If HasNextMessage And SettingCompleted Then
			ExchangeSettingsStructure.ExchangeExecutionResult = Undefined;
			ExecuteDataExchangeWithExternalSystemDataImport(ExchangeSettingsStructure);
		EndIf;
	EndIf;
	
EndProcedure

Procedure ExecuteDataExchangeWithExternalSystemExportXDTOSettings(ExchangeSettingsStructure)
	
	ExchangeMessageTransportDataProcessor = ExchangeSettingsStructure.ExchangeMessageTransportDataProcessor; // 
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
		
	XDTOSettings = New Structure;
	XDTOSettings.Insert("ExchangeFormat",
		ExchangePlanSettingValue(ExchangePlanName, "ExchangeFormat"));
	XDTOSettings.Insert("SupportedVersions",
		DataExchangeXDTOServer.ExhangeFormatVersionsArray(ExchangeSettingsStructure.InfobaseNode));
	XDTOSettings.Insert("SupportedObjects",
		DataExchangeXDTOServer.SupportedObjectsInFormat(ExchangePlanName, , ExchangeSettingsStructure.InfobaseNode));
	
	Try
		ExchangeMessageTransportDataProcessor.SendXDTOSettings(XDTOSettings);
	Except
		Information = ErrorInfo();
		ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.ErrorMessageTransport;
		WriteEventLogDataExchange(ErrorProcessing.DetailErrorDescription(Information), ExchangeSettingsStructure, True);
	EndTry;
	
EndProcedure

Procedure BeforeReadExchangeMessage(Val Recipient, ExchangeMessage, StandardProcessing) Export
	
	If IsSubordinateDIBNode()
		And TypeOf(MasterNode()) = TypeOf(Recipient) Then
		
		SavedExchangeMessage = DataExchangeMessageFromMasterNode();
		
		If TypeOf(SavedExchangeMessage) = Type("BinaryData") Then
			// 
			// 
			SetDataExchangeMessageFromMasterNode(SavedExchangeMessage, Recipient);
			SavedExchangeMessage = DataExchangeMessageFromMasterNode();
		EndIf;
		
		If TypeOf(SavedExchangeMessage) = Type("Structure") Then
			
			StandardProcessing = False;
			
			ExchangeMessage = SavedExchangeMessage.PathToFile;
			
			WriteDataReceivingEvent(Recipient, NStr("en = 'An exchange message is received from the cache.';"));
			
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("MessageReceivedFromCache", True);
			SetPrivilegedMode(False);
			
		Else
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("MessageReceivedFromCache", False);
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure AfterReadExchangeMessage(Val Recipient, Val ExchangeMessage, Val MessageRead,
		StandardProcessing, Val DeleteMessage = True) Export
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart("DownloadingExtensions") Then
		Return;
	EndIf;
	
	If IsSubordinateDIBNode()
		And TypeOf(MasterNode()) = TypeOf(Recipient) Then
		
		If Not MessageRead
		   And DataExchangeInternal.DataExchangeMessageImportModeBeforeStart("MessageReceivedFromCache") Then
			// 
			ClearDataExchangeMessageFromMasterNode();
			Return;
		EndIf;
		
		UpdateCachedMessage = False;
		
		If ConfigurationChanged() Or DataExchangeInternal.LoadExtensionsThatChangeDataStructure() Then
			
			// 
			// 
			// 
			UpdateCachedMessage = True;
			
			If Not MessageRead Then
				
				If Not Constants.LoadDataExchangeMessage.Get() Then
					Constants.LoadDataExchangeMessage.Set(True);
				EndIf;
				
			EndIf;
			
		Else
			
			If DeleteMessage Then
				
				ClearDataExchangeMessageFromMasterNode();
				If Constants.LoadDataExchangeMessage.Get() Then
					Constants.LoadDataExchangeMessage.Set(False);
				EndIf;
				
			Else
				// 
				// 
				// 
				UpdateCachedMessage = True;
			EndIf;
			
		EndIf;
		
		If UpdateCachedMessage Then
			
			PreviousMessage = DataExchangeMessageFromMasterNode();
			
			RefreshCache = False;
			NewMessage = New BinaryData(ExchangeMessage);
			
			StructureType = TypeOf(PreviousMessage) = Type("Structure");
			
			If StructureType Or TypeOf(PreviousMessage) = Type("BinaryData") Then
				
				If StructureType Then
					PreviousMessage = New BinaryData(PreviousMessage.PathToFile);
				EndIf;
				
				If PreviousMessage.Size() <> NewMessage.Size() Then
					RefreshCache = True;
				ElsIf NewMessage <> PreviousMessage Then
					RefreshCache = True;
				EndIf;
				
			Else
				
				RefreshCache = True;
				
			EndIf;
			
			If RefreshCache Then
				SetDataExchangeMessageFromMasterNode(NewMessage, Recipient);
			EndIf;
		EndIf;
		
	EndIf;
	
	If MessageRead And Common.SeparatedDataUsageAvailable() Then
		InformationRegisters.DataSyncEventHandlers.ExecuteHandlers(Recipient, "AfterGetData");
	EndIf;
	
EndProcedure

#EndRegion

#Region InitializeExchangeSettingsStructure_Private

// Initializes the data exchange subsystem to perform the exchange process.
//
// Parameters:
// 
// Returns:
//  Structure -  a structure with all the necessary data and objects to perform the exchange.
//
Function ExchangeSettingsForExternalConnection(InfobaseNode, ActionOnExchange, TransactionItemsCount)
	
	// 
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	ExchangeSettingsStructure.InfobaseNode = InfobaseNode;
	ExchangeSettingsStructure.ActionOnExchange      = ActionOnExchange;
	ExchangeSettingsStructure.IsDIBExchange           = DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode);
	
	PropertyStructure = Common.ObjectAttributesValues(ExchangeSettingsStructure.InfobaseNode, "Code, Description");
	
	ExchangeSettingsStructure.InfobaseNodeCode1 = CorrespondentNodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.InfobaseNodeDescription = PropertyStructure.Description;
	
	ExchangeSettingsStructure.TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(ExchangeSettingsStructure.InfobaseNode);
	
	If TransactionItemsCount = Undefined Then
		TransactionItemsCount = ItemsCountInTransactionOfActionToExecute(ActionOnExchange);
	EndIf;
	
	ExchangeSettingsStructure.TransactionItemsCount = TransactionItemsCount;
	
	// 
	ExchangeSettingsStructure.DoDataImport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport);
	ExchangeSettingsStructure.DoDataExport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport);
	
	ExchangeSettingsStructure.ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.CorrespondentExchangePlanName =
		DataExchangeCached.GetNameOfCorrespondentExchangePlan(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.CurrentExchangePlanNode = DataExchangeCached.GetThisExchangePlanNode(ExchangeSettingsStructure.ExchangePlanName);
	ExchangeSettingsStructure.CurrentExchangePlanNodeCode1 = NodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	
	// 
	ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ActionOnExchange);
	
	ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.COM;
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructure);
	
	// 
	CheckExchangeStructure(ExchangeSettingsStructure);
	
	// 
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	// 
	InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure);
	
	Return ExchangeSettingsStructure;
EndFunction

// Initializes the data exchange subsystem to perform the exchange process.
//
// Parameters:
// 
// Returns:
//  СтруктураНастроекОбмена - 
//
Function DataExchangeSettings(ExchangeExecutionSettings, LineNumber)
	
	// 
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	InitExchangeSettingsStructure(ExchangeSettingsStructure, ExchangeExecutionSettings, LineNumber);
	
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	SetDebugModeSettingsForStructure(ExchangeSettingsStructure);
	
	// 
	CheckExchangeStructure(ExchangeSettingsStructure);
	
	// 
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	// 
	InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure);
	
	// 
	If ExchangeSettingsStructure.IsDIBExchange Then
		
		InitDataExchangeDataProcessor(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.ExchangeByObjectConversionRules Then
		
		InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure);
		
	EndIf;
	
	Return ExchangeSettingsStructure;
EndFunction

// Retrieves the structure of transport settings for data exchange.
//
Function ExchangeTransportSettings(InfobaseNode, ExchangeMessagesTransportKind) Export
	
	// 
	ExchangeSettingsStructure = BaseExchangeSettingsStructure();
	
	ExchangeSettingsStructure.InfobaseNode = InfobaseNode;
	ExchangeSettingsStructure.ActionOnExchange      = Enums.ActionsOnExchange.DataImport;
	ExchangeSettingsStructure.ExchangeTransportKind    = ExchangeMessagesTransportKind;
	
	InitExchangeSettingsStructureForInfobaseNode(ExchangeSettingsStructure, True);
	
	// 
	CheckExchangeStructure(ExchangeSettingsStructure);
	
	// 
	If ExchangeSettingsStructure.Cancel Then
		Return ExchangeSettingsStructure;
	EndIf;
	
	// 
	InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure);
	
	Return ExchangeSettingsStructure;
EndFunction

// The structure of the exchange settings for the interactive download session.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef -  the node information base.
//  ExchangeMessageFileName - String -    the file name of the exchange message.
// 
// Returns:
//   See BaseExchangeSettingsStructure.
//
Function ExchangeSettingsStructureForInteractiveImportSession(Val InfobaseNode, Val ExchangeMessageFileName) Export
	
	Return DataExchangeCached.ExchangeSettingsStructureForInteractiveImportSession(InfobaseNode, ExchangeMessageFileName);
	
EndFunction

Procedure InitExchangeSettingsStructure(ExchangeSettingsStructure, ExchangeExecutionSettings, LineNumber)
	
	QueryText = "
	|SELECT
	|	ExchangeExecutionSettingsExchangeSettings.InfobaseNode         AS InfobaseNode,
	|	ExchangeExecutionSettingsExchangeSettings.InfobaseNode.Code     AS InfobaseNodeCode1,
	|	ExchangeExecutionSettingsExchangeSettings.ExchangeTransportKind            AS ExchangeTransportKind,
	|	ExchangeExecutionSettingsExchangeSettings.CurrentAction            AS ActionOnExchange,
	|	ExchangeExecutionSettingsExchangeSettings.Ref                         AS ExchangeExecutionSettings,
	|	ExchangeExecutionSettingsExchangeSettings.Ref.Description            AS ExchangeExecutionSettingDescription,
	|	CASE
	|		WHEN ExchangeExecutionSettingsExchangeSettings.CurrentAction = VALUE(Enum.ActionsOnExchange.DataImport) THEN TRUE
	|		ELSE FALSE
	|	END                                                                   AS DoDataImport,
	|	CASE
	|		WHEN ExchangeExecutionSettingsExchangeSettings.CurrentAction = VALUE(Enum.ActionsOnExchange.DataExport) THEN TRUE
	|		ELSE FALSE
	|	END                                                                   AS DoDataExport
	|FROM
	|	Catalog.DataExchangeScenarios.ExchangeSettings AS ExchangeExecutionSettingsExchangeSettings
	|WHERE
	|	  ExchangeExecutionSettingsExchangeSettings.Ref      = &ExchangeExecutionSettings
	|	AND ExchangeExecutionSettingsExchangeSettings.LineNumber = &LineNumber
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ExchangeExecutionSettings", ExchangeExecutionSettings);
	Query.SetParameter("LineNumber",               LineNumber);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	// 
	FillPropertyValues(ExchangeSettingsStructure, Selection);
	
	ExchangeSettingsStructure.IsDIBExchange = DataExchangeCached.IsDistributedInfobaseNode(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.EventLogMessageKey = NStr("en = 'Data exchange';");
	
	// 
	CheckMainExchangeSettingsStructureFields(ExchangeSettingsStructure);
	
	If ExchangeSettingsStructure.Cancel Then
		Return;
	EndIf;
	
	//
	ExchangeSettingsStructure.ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.ExchangeByObjectConversionRules = DataExchangeCached.IsUniversalDataExchangeNode(ExchangeSettingsStructure.InfobaseNode);
	
	ExchangeSettingsStructure.CurrentExchangePlanNode    = ExchangePlans[ExchangeSettingsStructure.ExchangePlanName].ThisNode();
	ExchangeSettingsStructure.CurrentExchangePlanNodeCode1 = 
		Common.ObjectAttributeValue(ExchangeSettingsStructure.CurrentExchangePlanNode, "Code");
	
	ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName = DataExchangeMessageTransportDataProcessorName(ExchangeSettingsStructure.ExchangeTransportKind);
	
	// 
	ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ActionOnExchange);
	
	If DataExchangeCached.IsMessagesExchangeNode(ExchangeSettingsStructure.InfobaseNode) Then
		ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
		ExchangeSettingsStructure.TransportSettings = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(ExchangeSettingsStructure.InfobaseNode);
	Else
		ExchangeSettingsStructure.TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ExchangeTransportKind);
	EndIf;
	
	ExchangeSettingsStructure.TransactionItemsCount = ItemsCountInTransactionOfActionToExecute(ExchangeSettingsStructure.ActionOnExchange);
	
EndProcedure

Procedure InitExchangeSettingsStructureForInfobaseNode(
		ExchangeSettingsStructure,
		UseTransportSettings)
	
	PropertyStructure = Common.ObjectAttributesValues(ExchangeSettingsStructure.InfobaseNode, "Code, Description");
	
	ExchangeSettingsStructure.InfobaseNodeCode1 = CorrespondentNodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.InfobaseNodeDescription = PropertyStructure.Description;
	
	// 
	If DataExchangeCached.IsMessagesExchangeNode(ExchangeSettingsStructure.InfobaseNode) Then
		ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
		ExchangeSettingsStructure.TransportSettings = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(
			ExchangeSettingsStructure.InfobaseNode);
	Else
		ExchangeSettingsStructure.TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(ExchangeSettingsStructure.InfobaseNode);
	EndIf;
	
	If ExchangeSettingsStructure.TransportSettings <> Undefined Then
		
		If UseTransportSettings Then
			
			// 
			If ExchangeSettingsStructure.ExchangeTransportKind = Undefined Then
				ExchangeSettingsStructure.ExchangeTransportKind = ExchangeSettingsStructure.TransportSettings.DefaultExchangeMessagesTransportKind;
			EndIf;
			
			// 
			If Not ValueIsFilled(ExchangeSettingsStructure.ExchangeTransportKind) Then
				
				ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.FILE;
				
			EndIf;
			
			ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName = DataExchangeMessageTransportDataProcessorName(ExchangeSettingsStructure.ExchangeTransportKind);
			
		EndIf;
		
		ExchangeSettingsStructure.TransactionItemsCount = ItemsCountInTransactionOfActionToExecute(ExchangeSettingsStructure.ActionOnExchange);
		
		If ExchangeSettingsStructure.TransportSettings.Property("WSUseLargeVolumeDataTransfer") Then
			ExchangeSettingsStructure.UseLargeVolumeDataTransfer = ExchangeSettingsStructure.TransportSettings.WSUseLargeVolumeDataTransfer;
		EndIf;
		
	EndIf;
	
	// 
	ExchangeSettingsStructure.ExchangeExecutionSettings             = Undefined;
	ExchangeSettingsStructure.ExchangeExecutionSettingDescription = "";
	
	// 
	ExchangeSettingsStructure.DoDataImport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport);
	ExchangeSettingsStructure.DoDataExport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport);
	
	ExchangeSettingsStructure.ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.CorrespondentExchangePlanName = 
		DataExchangeCached.GetNameOfCorrespondentExchangePlan(ExchangeSettingsStructure.InfobaseNode);
		
	ExchangeSettingsStructure.ExchangeByObjectConversionRules  = DataExchangeCached.IsUniversalDataExchangeNode(ExchangeSettingsStructure.InfobaseNode);
	ExchangeSettingsStructure.ConversionRulesAreRequired = ExchangePlanSettingValue(ExchangeSettingsStructure.ExchangePlanName, "ConversionRulesAreRequired");
	
	ExchangeSettingsStructure.CurrentExchangePlanNode    = ExchangePlans[ExchangeSettingsStructure.ExchangePlanName].ThisNode();
	ExchangeSettingsStructure.CurrentExchangePlanNodeCode1 = NodeIDForExchange(ExchangeSettingsStructure.InfobaseNode);
	
	// 
	ExchangeSettingsStructure.EventLogMessageKey = EventLogMessageKey(ExchangeSettingsStructure.InfobaseNode, ExchangeSettingsStructure.ActionOnExchange);
	
EndProcedure

// The structure of the exchange settings is basic.
// 
// Returns:
//  Structure:
//   * StartDate - Date
//   * EndDate - Date
//   * LineNumber - Number 
//   * ExchangeExecutionSettings - CatalogRef.DataExchangeScenarios -  a reference
//	                             list element that will be used for data exchange.
//   * ExchangeExecutionSettingDescription - String -  the name of the exchange execution setting.
//   * InfobaseNode - ExchangePlanRef -  the node of the exchange plan for which the data exchange action is performed.
//   * InfobaseNodeCode1 - String
//   * InfobaseNodeDescription - String
//   * ExchangeTransportKind - EnumRef.ExchangeMessagesTransportTypes -  the type of transport
//	                       that will be used in the data exchange process. 
//   * ActionOnExchange - EnumRef.ActionsOnExchange -  the data exchange action that is being performed.
//   * TransactionItemsCount - Number
//   * DoDataImport - Boolean
//   * DoDataExport - Boolean
//   * UseLargeVolumeDataTransfer - Boolean
//   * Cancel - Boolean
//   * IsDIBExchange - Boolean
//   * DataExchangeDataProcessor - DataProcessorObject.ConvertXTDOObjects
//                            - DataProcessorObject.InfobaseObjectConversion
//                            - DataProcessorObject.DistributedInfobasesObjectsConversion
//   * ExchangeMessageTransportDataProcessor - DataProcessorManager
//   * ExchangePlanName - String
//   * CurrentExchangePlanNode - ExchangePlanRef
//   * CurrentExchangePlanNodeCode1 - ExchangePlanRef
//   * ExchangeByObjectConversionRules - Boolean
//   * ConversionRulesAreRequired - Boolean
//   * DataExchangeMessageTransportDataProcessorName - String 
//   * EventLogMessageKey - String
//   * TransportSettings - Arbitrary -  saved settings for the transport of exchange messages from the external system. 
//   * ObjectsConversionRules - ValueStorage -  the read-out rules for converting objects.
//                              - Undefined -  
//   * RulesAreImported - Boolean
//   * ExportHandlersDebug - Boolean
//   * ImportHandlersDebug - Boolean
//   * ExportDebugExternalDataProcessorFileName - String
//   * ImportDebugExternalDataProcessorFileName - String
//   * DataExchangeLoggingMode - Boolean
//   * ExchangeProtocolFileName - String
//   * ContinueOnError - Boolean
//   * AdditionalParameters - Structure
//   * ExchangeExecutionResult - EnumRef.ExchangeExecutionResults
//   * ActionOnExchange - EnumRef.ActionsOnExchange -  the data exchange action that is being performed.
//   * ProcessedObjectsCount - Number
//   * MessageOnExchange - String
//   * ErrorMessageString - String
//
Function BaseExchangeSettingsStructure()
	
	ExchangeSettingsStructure = New Structure;
	
	// 
	
	ExchangeSettingsStructure.Insert("StartDate", CurrentSessionDate());
	ExchangeSettingsStructure.Insert("EndDate");
	
	ExchangeSettingsStructure.Insert("LineNumber");
	ExchangeSettingsStructure.Insert("ExchangeExecutionSettings");
	ExchangeSettingsStructure.Insert("ExchangeExecutionSettingDescription");
	ExchangeSettingsStructure.Insert("InfobaseNode");
	ExchangeSettingsStructure.Insert("InfobaseNodeCode1", "");
	ExchangeSettingsStructure.Insert("InfobaseNodeDescription", "");
	ExchangeSettingsStructure.Insert("ExchangeTransportKind");
	ExchangeSettingsStructure.Insert("ActionOnExchange");
	ExchangeSettingsStructure.Insert("TransactionItemsCount", 1); // 
	ExchangeSettingsStructure.Insert("DoDataImport", False);
	ExchangeSettingsStructure.Insert("DoDataExport", False);
	ExchangeSettingsStructure.Insert("UseLargeVolumeDataTransfer", True);
	
	// 
	ExchangeSettingsStructure.Insert("Cancel", False);
	ExchangeSettingsStructure.Insert("IsDIBExchange", False);
	
	ExchangeSettingsStructure.Insert("DataExchangeDataProcessor");
	ExchangeSettingsStructure.Insert("ExchangeMessageTransportDataProcessor");
	
	ExchangeSettingsStructure.Insert("ExchangePlanName");
	ExchangeSettingsStructure.Insert("CorrespondentExchangePlanName");
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNode");
	ExchangeSettingsStructure.Insert("CurrentExchangePlanNodeCode1");
	
	ExchangeSettingsStructure.Insert("ExchangeByObjectConversionRules",  False);
	ExchangeSettingsStructure.Insert("ConversionRulesAreRequired", True);
	
	ExchangeSettingsStructure.Insert("DataExchangeMessageTransportDataProcessorName");
	
	ExchangeSettingsStructure.Insert("EventLogMessageKey");
	
	ExchangeSettingsStructure.Insert("TransportSettings");
	
	ExchangeSettingsStructure.Insert("ObjectsConversionRules");
	ExchangeSettingsStructure.Insert("RulesAreImported", False);
	
	ExchangeSettingsStructure.Insert("ExportHandlersDebug ", False);
	ExchangeSettingsStructure.Insert("ImportHandlersDebug", False);
	ExchangeSettingsStructure.Insert("ExportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructure.Insert("ImportDebugExternalDataProcessorFileName", "");
	ExchangeSettingsStructure.Insert("DataExchangeLoggingMode", False);
	ExchangeSettingsStructure.Insert("ExchangeProtocolFileName", "");
	ExchangeSettingsStructure.Insert("ContinueOnError", False);
	
	// 
	ExchangeSettingsStructure.Insert("AdditionalParameters", New Structure);
	
	// 
	ExchangeSettingsStructure.Insert("ExchangeExecutionResult");
	ExchangeSettingsStructure.Insert("ActionOnExchange");
	ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
	ExchangeSettingsStructure.Insert("MessageOnExchange",           "");
	ExchangeSettingsStructure.Insert("ErrorMessageString",      "");
	
	Return ExchangeSettingsStructure;
EndFunction

Procedure CheckMainExchangeSettingsStructureFields(ExchangeSettingsStructure)
	
	If Not ValueIsFilled(ExchangeSettingsStructure.InfobaseNode) Then
		
		// 
		ErrorMessageString = NStr(
		"en = 'Peer infobase node is not specified. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
	ElsIf Not ValueIsFilled(ExchangeSettingsStructure.ExchangeTransportKind) Then
		
		ErrorMessageString = NStr("en = 'Exchange transport type is not specified. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
	ElsIf Not ValueIsFilled(ExchangeSettingsStructure.ActionOnExchange) Then
		
		ErrorMessageString = NStr("en = 'Direction (export or import) is not specified. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
	EndIf;
	
EndProcedure

Procedure CheckExchangeStructure(ExchangeSettingsStructure, UseTransportSettings = True)
	
	If Not ValueIsFilled(ExchangeSettingsStructure.InfobaseNode) Then
		
		// 
		ErrorMessageString = NStr(
		"en = 'Peer infobase node is not specified. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
	ElsIf UseTransportSettings And Not ValueIsFilled(ExchangeSettingsStructure.ExchangeTransportKind) Then
		
		ErrorMessageString = NStr("en = 'Exchange transport type is not specified. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
	ElsIf Not ValueIsFilled(ExchangeSettingsStructure.ActionOnExchange) Then
		
		ErrorMessageString = NStr("en = 'Direction (export or import) is not specified. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
	ElsIf Common.ObjectAttributeValue(ExchangeSettingsStructure.InfobaseNode, "DeletionMark") Then
		
		// 
		ErrorMessageString = NStr("en = 'The infobase node is marked for deletion. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
	
	ElsIf ExchangeSettingsStructure.InfobaseNode = ExchangeSettingsStructure.CurrentExchangePlanNode Then
		
		// 
		ErrorMessageString = NStr(
		"en = 'Cannot exchange data with the infobase node. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
	
	ElsIf IsBlankString(ExchangeSettingsStructure.InfobaseNodeCode1)
		  Or IsBlankString(ExchangeSettingsStructure.CurrentExchangePlanNodeCode1) Then
		
		// 
		ErrorMessageString = NStr("en = 'An exchange node contains no code. The data exchange is canceled.';",
			Common.DefaultLanguageCode());
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.ExportHandlersDebug Then
		
		ExportDataProcessorFile = New File(ExchangeSettingsStructure.ExportDebugExternalDataProcessorFileName);
		
		If Not ExportDataProcessorFile.Exists() Then
			
			ErrorMessageString = NStr("en = 'The data processor file required for debugging does not exist. The data exchange is canceled.';",
				Common.DefaultLanguageCode());
			WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
			
			WriteExchangeInitializationFinish(ExchangeSettingsStructure);
			
		EndIf;
		
	ElsIf ExchangeSettingsStructure.ImportHandlersDebug Then
		
		ImportDataProcessorFile1 = New File(ExchangeSettingsStructure.ImportDebugExternalDataProcessorFileName);
		
		If Not ImportDataProcessorFile1.Exists() Then
			
			ErrorMessageString = NStr("en = 'The data processor file required for debugging does not exist. The data exchange is canceled.';",
				Common.DefaultLanguageCode());
			WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
			
			WriteExchangeInitializationFinish(ExchangeSettingsStructure);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure InitDataExchangeDataProcessor(ExchangeSettingsStructure)
	
	// 
	If ExchangeSettingsStructure.Cancel Then
		Return;
	EndIf;
	
	// Creating
	DataExchangeDataProcessor = DataProcessors.DistributedInfobasesObjectsConversion.Create();
	
	// 
	DataExchangeDataProcessor.InfobaseNode          = ExchangeSettingsStructure.InfobaseNode;
	DataExchangeDataProcessor.TransactionItemsCount  = ExchangeSettingsStructure.TransactionItemsCount;
	DataExchangeDataProcessor.EventLogMessageKey = ExchangeSettingsStructure.EventLogMessageKey;
	
	ExchangeSettingsStructure.Insert("DataExchangeDataProcessor", DataExchangeDataProcessor);
	
EndProcedure

Procedure InitDataExchangeDataProcessorByConversionRules(ExchangeSettingsStructure)
	
	Var DataExchangeDataProcessor;
	
	// 
	If ExchangeSettingsStructure.Cancel Then
		Return;
	EndIf;
	
	If ExchangeSettingsStructure.DoDataExport Then
		
		DataExchangeDataProcessor = DataExchangeDataProcessorForExport(ExchangeSettingsStructure);
		
	ElsIf ExchangeSettingsStructure.DoDataImport Then
		
		DataExchangeDataProcessor = DataExchangeDataProcessorForImport(ExchangeSettingsStructure);
		
	EndIf;
	
	ExchangeSettingsStructure.Insert("DataExchangeDataProcessor", DataExchangeDataProcessor);
	
EndProcedure

Procedure InitExchangeMessageTransportDataProcessor(ExchangeSettingsStructure)
	
	If ExchangeSettingsStructure.ExchangeTransportKind = Enums.ExchangeMessagesTransportTypes.ExternalSystem Then
		InitMessagesOfExchangeWithExternalSystemTransportProcessing(ExchangeSettingsStructure);
		Return;
	EndIf;
	
	// 
	ExchangeMessageTransportDataProcessor = DataProcessors[ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName].Create();
	
	IsOutgoingMessage = ExchangeSettingsStructure.DoDataExport;
	
	Transliteration = Undefined;
	SettingsDictionary = New Map;
	SettingsDictionary.Insert(Enums.ExchangeMessagesTransportTypes.FILE,  "FILETransliterateExchangeMessageFileNames");
	SettingsDictionary.Insert(Enums.ExchangeMessagesTransportTypes.EMAIL, "EMAILTransliterateExchangeMessageFileNames");
	SettingsDictionary.Insert(Enums.ExchangeMessagesTransportTypes.FTP,   "FTPTransliterateExchangeMessageFileNames");
	
	PropertyNameTransliteration = SettingsDictionary.Get(ExchangeSettingsStructure.ExchangeTransportKind);
	If ValueIsFilled(PropertyNameTransliteration) Then
		ExchangeSettingsStructure.TransportSettings.Property(PropertyNameTransliteration, Transliteration);
	EndIf;
	
	Transliteration = ?(Transliteration = Undefined, False, Transliteration);
	
	// 
	ExchangeMessageTransportDataProcessor.MessageFileNameTemplate = MessageFileNameTemplate(
		ExchangeSettingsStructure.CurrentExchangePlanNode,
		ExchangeSettingsStructure.InfobaseNode,
		IsOutgoingMessage,
		Transliteration);
	
	// 
	FillPropertyValues(ExchangeMessageTransportDataProcessor, ExchangeSettingsStructure.TransportSettings);
	
	// 
	ExchangeMessageTransportDataProcessor.Initialize();
	
	ExchangeSettingsStructure.Insert("ExchangeMessageTransportDataProcessor", ExchangeMessageTransportDataProcessor);
	
EndProcedure

Function DataExchangeDataProcessorForExport(ExchangeSettingsStructure)
	
	DataProcessorManager = ?(IsXDTOExchangePlan(ExchangeSettingsStructure.InfobaseNode),
		DataProcessors.ConvertXTDOObjects,
		DataProcessors.InfobaseObjectConversion);
	
	DataExchangeDataProcessor = DataProcessorManager.Create();
	
	DataExchangeDataProcessor.ExchangeMode = "Upload0";
	
	// 
	If DataExchangeDataProcessor.Metadata().Attributes.Find("ExchangeRulesFileName") <> Undefined Then
		SetDataExportExchangeRules(DataExchangeDataProcessor, ExchangeSettingsStructure);
		DataExchangeDataProcessor.DontExportObjectsByRefs = True;
		DataExchangeDataProcessor.ExchangeRulesFileName        = "1";
	EndIf;
	
	// 
	If DataExchangeDataProcessor.Metadata().Attributes.Find("BackgroundExchangeNode") <> Undefined Then
		DataExchangeDataProcessor.BackgroundExchangeNode = Undefined;
	EndIf;
		
	DataExchangeDataProcessor.NodeForExchange = ExchangeSettingsStructure.InfobaseNode;
	
	SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessor, ExchangeSettingsStructure);
	
	Return DataExchangeDataProcessor;
	
EndFunction

Function DataExchangeDataProcessorForImport(ExchangeSettingsStructure)
	
	DataProcessorManager = ?(IsXDTOExchangePlan(ExchangeSettingsStructure.InfobaseNode),
		DataProcessors.ConvertXTDOObjects,
		DataProcessors.InfobaseObjectConversion);
	
	DataExchangeDataProcessor = DataProcessorManager.Create();
	
	DataExchangeDataProcessor.ExchangeMode = "Load";
	DataExchangeDataProcessor.ExchangeNodeDataImport = ExchangeSettingsStructure.InfobaseNode;
	
	If DataExchangeDataProcessor.Metadata().Attributes.Find("ExchangeRulesFileName") <> Undefined Then
		SetDataImportExchangeRules(DataExchangeDataProcessor, ExchangeSettingsStructure);
	EndIf;
	
	SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessor, ExchangeSettingsStructure);
	
	Return DataExchangeDataProcessor
	
EndFunction

Procedure SetCommonParametersForDataExchangeProcessing(DataExchangeDataProcessor, ExchangeSettingsStructure, ExchangeWithSSL20 = False)
	
	DataExchangeDataProcessor.AppendDataToExchangeLog = False;
	DataExchangeDataProcessor.ExportAllowedObjectsOnly      = False;
	
	DataExchangeDataProcessor.UseTransactions         = ExchangeSettingsStructure.TransactionItemsCount <> 1;
	DataExchangeDataProcessor.ObjectCountPerTransaction = ExchangeSettingsStructure.TransactionItemsCount;
	
	DataExchangeDataProcessor.EventLogMessageKey = ExchangeSettingsStructure.EventLogMessageKey;
	
	If Not ExchangeWithSSL20 Then
		
		SetDebugModeSettingsForDataProcessor(DataExchangeDataProcessor, ExchangeSettingsStructure);
		
	EndIf;
	
EndProcedure

Procedure SetDataExportExchangeRules(DataExchangeXMLDataProcessor, ExchangeSettingsStructure)
	
	ObjectsConversionRules = InformationRegisters.DataExchangeRules.ParsedRulesOfObjectConversion(ExchangeSettingsStructure.ExchangePlanName);
	
	If ObjectsConversionRules = Undefined Then
		
		// 
		ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Conversion rules are not specified. Exchange plan: %1. The data export is canceled.';", Common.DefaultLanguageCode()),
			ExchangeSettingsStructure.ExchangePlanName);
		WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
		Return;
	EndIf;
	
	DataExchangeXMLDataProcessor.SavedSettings = ObjectsConversionRules;
	
	Try
		DataExchangeXMLDataProcessor.RestoreRulesFromInternalFormat();
	Except
		WriteEventLogDataExchange(ErrorProcessing.DetailErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		Return;
	EndTry;
	
EndProcedure

Procedure SetDataImportExchangeRules(DataExchangeXMLDataProcessor, ExchangeSettingsStructure)
	
	ObjectsConversionRules = InformationRegisters.DataExchangeRules.ParsedRulesOfObjectConversion(ExchangeSettingsStructure.ExchangePlanName, True);
	
	If ObjectsConversionRules = Undefined Then
	
		If Not ExchangeSettingsStructure.Property("ConversionRulesAreRequired")
			Or ExchangeSettingsStructure.ConversionRulesAreRequired = True Then
		
			// 
			NString = NStr("en = 'Conversion rules are not specified. Exchange plan: %1. The data import is canceled.';",
				Common.DefaultLanguageCode());
			ErrorMessageString = StringFunctionsClientServer.SubstituteParametersToString(NString, ExchangeSettingsStructure.ExchangePlanName);
			WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
			WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		
			Return;
			
		EndIf;
			
	EndIf;
	
	DataExchangeXMLDataProcessor.SavedSettings = ObjectsConversionRules;
	
	Try
		DataExchangeXMLDataProcessor.RestoreRulesFromInternalFormat();
	Except
		WriteEventLogDataExchange(ErrorProcessing.BriefErrorDescription(ErrorInfo()), ExchangeSettingsStructure, True);
		WriteExchangeInitializationFinish(ExchangeSettingsStructure);
		Return;
	EndTry;
	
EndProcedure

// Reads debugging settings from the IB and sets them for the exchange structure.
//
Procedure SetDebugModeSettingsForStructure(ExchangeSettingsStructure, IsExternalConnection = False)
	
	QueryText = "SELECT
	|	CASE
	|		WHEN &PerformDataExport
	|			THEN DataExchangeRules.ExportDebugMode
	|		ELSE FALSE
	|	END AS ExportHandlersDebug,
	|	CASE
	|		WHEN &PerformDataExport
	|			THEN DataExchangeRules.ExportDebuggingDataProcessorFileName
	|		ELSE """"
	|	END AS ExportDebugExternalDataProcessorFileName,
	|	CASE
	|		WHEN &PerformDataImport
	|			THEN DataExchangeRules.ImportDebugMode
	|		ELSE FALSE
	|	END AS ImportHandlersDebug,
	|	CASE
	|		WHEN &PerformDataImport
	|			THEN DataExchangeRules.ImportDebuggingDataProcessorFileName
	|		ELSE """"
	|	END AS ImportDebugExternalDataProcessorFileName,
	|	DataExchangeRules.DataExchangeLoggingMode AS DataExchangeLoggingMode,
	|	DataExchangeRules.ExchangeProtocolFileName AS ExchangeProtocolFileName,
	|	DataExchangeRules.NotStopByMistake AS ContinueOnError
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsConversionRules)
	|	AND DataExchangeRules.DebugMode";
	
	Query = New Query;
	Query.Text = QueryText;
	
	DoDataExport = False;
	If Not ExchangeSettingsStructure.Property("DoDataExport", DoDataExport) Then
		DoDataExport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataExport);
	EndIf;
	
	DoDataImport = False;
	If Not ExchangeSettingsStructure.Property("DoDataImport", DoDataImport) Then
		DoDataImport = (ExchangeSettingsStructure.ActionOnExchange = Enums.ActionsOnExchange.DataImport);
	EndIf;
	
	Query.SetParameter("ExchangePlanName", ExchangeSettingsStructure.ExchangePlanName);
	Query.SetParameter("PerformDataExport", DoDataExport);
	Query.SetParameter("PerformDataImport", DoDataImport);
	
	ProtocolFileName = "";
	If IsExternalConnection And ExchangeSettingsStructure.Property("ExchangeProtocolFileName", ProtocolFileName)
		And Not IsBlankString(ProtocolFileName) Then
		
		ExchangeSettingsStructure.ExchangeProtocolFileName = AddLiteralToFileName(ProtocolFileName, "ExternalConnection")
	
	EndIf;
	
	If Not Common.DataSeparationEnabled() Then
	
		Result = Query.Execute();
		
		If Not Result.IsEmpty() Then
		
			SettingsTable = Result.Unload();
			TableRow = SettingsTable[0];
			
			FillPropertyValues(ExchangeSettingsStructure, TableRow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Reads debugging settings from the IB and sets them for the exchange settings structure.
//
Procedure SetDebugModeSettingsForDataProcessor(DataExchangeDataProcessor, ExchangeSettingsStructure)
	
	If ExchangeSettingsStructure.Property("ExportDebugExternalDataProcessorFileName")
		And DataExchangeDataProcessor.Metadata().Attributes.Find("ExportDebugExternalDataProcessorFileName") <> Undefined Then
		
		DataExchangeDataProcessor.ExportHandlersDebug = ExchangeSettingsStructure.ExportHandlersDebug;
		DataExchangeDataProcessor.ImportHandlersDebug = ExchangeSettingsStructure.ImportHandlersDebug;
		DataExchangeDataProcessor.ExportDebugExternalDataProcessorFileName = ExchangeSettingsStructure.ExportDebugExternalDataProcessorFileName;
		DataExchangeDataProcessor.ImportDebugExternalDataProcessorFileName = ExchangeSettingsStructure.ImportDebugExternalDataProcessorFileName;
		DataExchangeDataProcessor.DataExchangeLoggingMode = ExchangeSettingsStructure.DataExchangeLoggingMode;
		DataExchangeDataProcessor.ExchangeProtocolFileName = ExchangeSettingsStructure.ExchangeProtocolFileName;
		DataExchangeDataProcessor.ContinueOnError = ExchangeSettingsStructure.ContinueOnError;
		
		If ExchangeSettingsStructure.DataExchangeLoggingMode Then
			
			If ExchangeSettingsStructure.ExchangeProtocolFileName = "" Then
				DataExchangeDataProcessor.OutputInfoMessagesToMessageWindow = True;
				DataExchangeDataProcessor.OutputInfoMessagesToProtocol = False;
			Else
				DataExchangeDataProcessor.OutputInfoMessagesToMessageWindow = False;
				DataExchangeDataProcessor.OutputInfoMessagesToProtocol = True;
				DataExchangeDataProcessor.ExchangeProtocolFileName = ExchangeSettingsStructure.ExchangeProtocolFileName;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Sets the upload settings for processing.
//
Procedure SetExportDebugSettingsForExchangeRules(DataExchangeDataProcessor, ExchangePlanName, DebugMode) Export
	
	QueryText = "SELECT
	|	DataExchangeRules.ExportDebugMode AS ExportHandlersDebug,
	|	DataExchangeRules.ExportDebuggingDataProcessorFileName AS ExportDebugExternalDataProcessorFileName
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsConversionRules)
	|	AND &DebugMode = TRUE";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	Query.SetParameter("DebugMode", DebugMode);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Or Common.DataSeparationEnabled() Then
		
		DataExchangeDataProcessor.ExportHandlersDebug = False;
		DataExchangeDataProcessor.ExportDebugExternalDataProcessorFileName = "";
		
	Else
		
		SettingsTable = Result.Unload();
		DebuggingSettings = SettingsTable[0];
		
		FillPropertyValues(DataExchangeDataProcessor, DebuggingSettings);
		
	EndIf;
	
EndProcedure

Procedure WriteExchangeInitializationFinish(ExchangeSettingsStructure)
	
	ExchangeSettingsStructure.Cancel = True;
	ExchangeSettingsStructure.ExchangeExecutionResult = Enums.ExchangeExecutionResults.Canceled;
	
EndProcedure

Function MessageFileNameTemplate(CurrentExchangePlanNode, InfobaseNode, IsOutgoingMessage, Transliteration = False, UseVirtualNodeCodeOnGet = False) Export
	
	If IsOutgoingMessage Then
		SenderCode = NodeIDForExchange(InfobaseNode);
		RecipientCode  = CorrespondentNodeIDForExchange(InfobaseNode);
	Else
		SenderCode = CorrespondentNodeIDForExchange(InfobaseNode);
		RecipientCode  = NodeIDForExchange(InfobaseNode);
	EndIf;
	
	If IsOutgoingMessage Or UseVirtualNodeCodeOnGet Then
		// 
		// 
		PredefinedNodeAlias = PredefinedNodeAlias(InfobaseNode);
		If ValueIsFilled(PredefinedNodeAlias) Then
			If IsOutgoingMessage Then
				SenderCode = PredefinedNodeAlias;
			Else
				RecipientCode = PredefinedNodeAlias;
			EndIf;
		EndIf;
	EndIf;
	
	MessageFileName = ExchangeMessageFileName(SenderCode, RecipientCode, IsOutgoingMessage);
	
	// 
	If Transliteration Then
		MessageFileName = StringFunctions.LatinString(MessageFileName);
	EndIf;
	
	Return MessageFileName;
	
EndFunction

Procedure InitMessagesOfExchangeWithExternalSystemTransportProcessing(ExchangeSettingsStructure)
	
	If Common.SubsystemExists("OnlineUserSupport.DataExchangeWithExternalSystems") Then
		
		ExchangeMessageTransportDataProcessor = DataProcessors[ExchangeSettingsStructure.DataExchangeMessageTransportDataProcessorName].Create();
		
		ConnectionParameters = InformationRegisters.DataExchangeTransportSettings.ExternalSystemTransportSettings(
			ExchangeSettingsStructure.InfobaseNode);
		
		// 
		ExchangeMessageTransportDataProcessor.Initialize(ConnectionParameters);
		
		ExchangeSettingsStructure.Insert("ExchangeMessageTransportDataProcessor", ExchangeMessageTransportDataProcessor);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Common_Private

Procedure GetCommonInfobasesNodesSettings(TempTablesManager)
	
	Query = New Query;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		QueryTextResult =
		"SELECT
		|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
		|	ISNULL(CommonInfobasesNodesSettings.CorrespondentVersion, """") AS CorrespondentVersion,
		|	ISNULL(CommonInfobasesNodesSettings.CorrespondentPrefix, """") AS CorrespondentPrefix,
		|	ISNULL(CommonInfobasesNodesSettings.SettingCompleted, FALSE) AS SettingCompleted,
		|	ISNULL(CommonInfobasesNodesSettings.MigrationToWebService_Step, 0) AS MigrationToWebService_Step,
		|	ISNULL(DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind, """") AS TransportKind,
		|	ISNULL(CommonInfobasesNodesSettings.SynchronizationIsUnavailable, FALSE) AS SynchronizationIsUnavailable
		|INTO CommonInfobasesNodesSettings
		|FROM
		|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
		|		LEFT JOIN InformationRegister.DataExchangeTransportSettings AS DataExchangeTransportSettings
		|		ON CommonInfobasesNodesSettings.InfobaseNode = DataExchangeTransportSettings.Peer";
		
	Else
		
		QueryTextResult =
		"SELECT
		|	NULL AS InfobaseNode,
		|	"""" AS CorrespondentVersion,
		|	"""" AS CorrespondentPrefix,
		|	FALSE AS SettingCompleted,
		|	0 AS MigrationToWebService_Step,
		|	"""" AS TransportKind,
		|	FALSE AS SynchronizationIsUnavailable
		|INTO CommonInfobasesNodesSettings";
		
	EndIf;
	
	Query.Text = QueryTextResult;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Function ExchangePlanCatalogs(Val ExchangePlanName)
	
	If TypeOf(ExchangePlanName) <> Type("String") Then
		
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlanName);
		
	EndIf;
	
	Result = New Array;
	
	ExchangePlanContent = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	For Each Item In ExchangePlanContent Do
		
		If Common.IsCatalog(Item.Metadata)
			Or Common.IsChartOfCharacteristicTypes(Item.Metadata) Then
			
			Result.Add(Item.Metadata);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// See ToDoListOverridable.OnDetermineToDoListHandlers
Procedure OnFillToDoListSynchronizationWarnings(ToDoList)
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("View", Metadata.InformationRegisters.DataExchangeResults)
		Or ModuleToDoListServer.UserTaskDisabled("WarningsOnSynchronization") Then
		Return;
	EndIf;
	
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	If SSLExchangePlans.Count() > 0 Then
		
		MonitorTable = DataExchangeMonitorTable(SSLExchangePlans);
		ResultingStructure = InformationRegisters.DataExchangeResults.TheNumberOfWarningsForTheFormElement(MonitorTable.UnloadColumn("InfobaseNode"));
		
	Else
		
		ResultingStructure = New Structure("Count, Title", 0, "");
		
	EndIf;
	
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.CommonForms.DataSyncSettings.FullName());
	
	For Each Section In Sections Do
		
		NotificationOnSynchronizationID = "WarningsOnSynchronization" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = NotificationOnSynchronizationID;
		ToDoItem.HasToDoItems       = ResultingStructure.Count > 0;
		ToDoItem.Count     = ResultingStructure.Count;
		ToDoItem.Presentation  = NStr("en = 'Warnings';");
		ToDoItem.Form          = "InformationRegister.DataExchangeResults.Form.SynchronizationWarnings";
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers
Procedure CheckLoopingWhenFillingOutToDoList(ToDoList)
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.InformationRegisters.SynchronizationCircuit)
		Or ModuleToDoListServer.UserTaskDisabled("WarningOnSyncLoop") Then
		Return;
	EndIf;
	
	SSLExchangePlans = DataExchangeCached.SSLExchangePlans();
	HasLoop = SSLExchangePlans.Count() > 0 And DataExchangeLoopControl.HasLoop();
		
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.CommonForms.DataSyncSettings.FullName());
	
	For Each Section In Sections Do
		
		NotificationOnSynchronizationID = "WarningOnSyncLoop" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = NotificationOnSynchronizationID;
		ToDoItem.HasToDoItems       = HasLoop;
		ToDoItem.Presentation  = NStr("en = 'Synchronization loop is found';");
		ToDoItem.Form          = "InformationRegister.SynchronizationCircuit.Form.SynchronizationLoop";
		ToDoItem.Owner       = Section;
		ToDoItem.Important			= True;
	
	EndDo;
	
EndProcedure

// See ToDoListOverridable.OnDetermineToDoListHandlers.
Procedure OnFillToDoListCheckCompatibilityWithCurrentVersion(ToDoList)
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Edit", Metadata.InformationRegisters.DataExchangeRules)
		Or ModuleToDoListServer.UserTaskDisabled("ExchangeRules") Then
		Return;
	EndIf;
	
	// 
	Sections = ModuleToDoListServer.SectionsForObject("InformationRegister.DataExchangeRules");
	If Sections.Count() = 0 Then 
		Return;
	EndIf;
	
	OutputToDoItem = True;
	VersionChecked = CommonSettingsStorage.Load("ToDoList", "ExchangePlans");
	If VersionChecked <> Undefined Then
		ArrayVersion  = StrSplit(Metadata.Version, ".");
		CurrentVersion = ArrayVersion[0] + ArrayVersion[1] + ArrayVersion[2];
		If VersionChecked = CurrentVersion Then
			OutputToDoItem = False; // 
		EndIf;
	EndIf;
	
	ExchangePlansWithRulesFromFile = ExchangePlansWithRulesFromFile();
	
	For Each Section In Sections Do
		SectionID = "CheckCompatibilityWithCurrentVersion" + StrReplace(Section.FullName(), ".", "");
		
		// 
		ToDoItem = ToDoList.Add();
		ToDoItem.Id = "ExchangeRules";
		ToDoItem.HasToDoItems      = OutputToDoItem And ExchangePlansWithRulesFromFile > 0;
		ToDoItem.Presentation = NStr("en = 'Exchange rules';");
		ToDoItem.Count    = ExchangePlansWithRulesFromFile;
		ToDoItem.Form         = "InformationRegister.DataExchangeRules.Form.DataSynchronizationCheck";
		ToDoItem.Owner      = SectionID;
		
		// 
		ToDoGroup = ToDoList.Find(SectionID, "Id");
		If ToDoGroup = Undefined Then
			ToDoGroup = ToDoList.Add();
			ToDoGroup.Id = SectionID;
			ToDoGroup.HasToDoItems      = ToDoItem.HasToDoItems;
			ToDoGroup.Presentation = NStr("en = 'Check compatibility';");
			If ToDoItem.HasToDoItems Then
				ToDoGroup.Count = ToDoItem.Count;
			EndIf;
			ToDoGroup.Owner = Section;
		Else
			If Not ToDoGroup.HasToDoItems Then
				ToDoGroup.HasToDoItems = ToDoItem.HasToDoItems;
			EndIf;
			
			If ToDoItem.HasToDoItems Then
				ToDoGroup.Count = ToDoGroup.Count + ToDoItem.Count;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Function AdditionalExchangePlanPropertiesAsString(Val PropertiesAsString)
	
	Result = "";
	
	Template = "ExchangePlans.[PropertyAsString] AS [PropertyAsString]";
	
	ArrayProperties = StrSplit(PropertiesAsString, ",", False);
	
	For Each PropertyAsString In ArrayProperties Do
		
		PropertyAsStringInQuery = StrReplace(Template, "[PropertyAsString]", PropertyAsString);
		
		Result = Result + PropertyAsStringInQuery + ", ";
		
	EndDo;
	
	Return Result;
EndFunction

Function ExchangePlansFilterByDataSeparationFlag(ExchangePlansArray1)
	
	Result = New Array;
	
	If Common.DataSeparationEnabled() Then
		
		If Common.SeparatedDataUsageAvailable() Then
			
			For Each ExchangePlanName In ExchangePlansArray1 Do
				
				If Common.SubsystemExists("CloudTechnology.Core") Then
					ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
					IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName);
				Else
					IsSeparatedMetadataObject = False;
				EndIf;
				
				If IsSeparatedMetadataObject Then
					
					Result.Add(ExchangePlanName);
					
				EndIf;
				
			EndDo;
			
		Else
			
			For Each ExchangePlanName In ExchangePlansArray1 Do
				
				If Common.SubsystemExists("CloudTechnology.Core") Then
					ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
					IsSeparatedMetadataObject = ModuleSaaSOperations.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName);
				Else
					IsSeparatedMetadataObject = False;
				EndIf;
				
				If Not IsSeparatedMetadataObject Then
					
					Result.Add(ExchangePlanName);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	Else
		
		For Each ExchangePlanName In ExchangePlansArray1 Do
			
			Result.Add(ExchangePlanName);
			
		EndDo;
		
	EndIf;
	
	Return Result;
EndFunction

Function ExchangePlansFilterByStandaloneModeFlag(ExchangePlansArray1)
	
	Result = New Array;
	
	For Each ExchangePlanName In ExchangePlansArray1 Do
		
		If ExchangePlanName <> DataExchangeCached.StandaloneModeExchangePlan() Then
			
			Result.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// This procedure deletes outdated entries in the information register.
// A record is considered outdated if the exchange plan for which the record was created
// was renamed or deleted.
//
// Parameters:
//  No.
// 
Procedure DeleteObsoleteRecordsFromDataExchangeRulesRegister()
	
	Query = New Query(
	"SELECT DISTINCT
	|	DataExchangeRules.ExchangePlanName AS ExchangePlanName
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	NOT DataExchangeRules.ExchangePlanName IN (&SSLExchangePlans)");
	Query.SetParameter("SSLExchangePlans", DataExchangeCached.SSLExchangePlans());
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
			
		RecordSet = DataExchangeInternal.CreateInformationRegisterRecordSet(New Structure("ExchangePlanName", Selection.ExchangePlanName),
			"DataExchangeRules");
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure GetDataExchangeScriptsForMonitor(TempTablesManager)
	
	Query = New Query;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		QueryText =
			"SELECT
			|	DataExchangeScenariosExchangeSettings.InfobaseNode AS InfobaseNode
			|INTO DataSynchronizationScenarios
			|FROM
			|	Catalog.DataExchangeScenarios.ExchangeSettings AS DataExchangeScenariosExchangeSettings
			|WHERE
			|	DataExchangeScenariosExchangeSettings.Ref.UseScheduledJob = TRUE
			|
			|GROUP BY
			|	DataExchangeScenariosExchangeSettings.InfobaseNode";
					
	Else
		
		QueryText =
			"SELECT
			|	UNDEFINED AS InfobaseNode
			|INTO DataSynchronizationScenarios";
		
	EndIf;
	
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetExchangePlansForDashboard(TempTablesManager, ExchangePlansArray1, Val AdditionalExchangePlanProperties)
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	// 
	QueryOptions = ExchangePlansForMonitorQueryParameters();
	QueryOptions.ExchangePlansArray1                 = ExchangePlansArray1;
	QueryOptions.AdditionalExchangePlanProperties = AdditionalExchangePlanProperties;
	QueryOptions.ResultToTemporaryTable       = True;
	Query.Text = ExchangePlansForMonitorQueryText(QueryOptions);
	Query.Execute();
	
EndProcedure

// Function for declaring the structure of parameters of the textquery function of the exchange plan for the Monitor.
//
// Parameters:
//   No.
//
// Returns:
//   Structure
//
Function ExchangePlansForMonitorQueryParameters()
	
	QueryOptions = New Structure;
	QueryOptions.Insert("ExchangePlansArray1",                 New Array);
	QueryOptions.Insert("AdditionalExchangePlanProperties", "");
	QueryOptions.Insert("ResultToTemporaryTable",       False);
	
	Return QueryOptions;
	
EndFunction

// Returns the text of the query to retrieve data nodes of the exchange plans.
//
// Parameters:
//   QueryOptions - See ExchangePlansForMonitorQueryParameters
//   ExcludeStandaloneModeExchangePlans  - Boolean -  if True, the request body excluded the exchange plans
//                                                    Autonomous operation.
//
// Returns:
//   String - 
//
Function ExchangePlansForMonitorQueryText(QueryOptions = Undefined, ExcludeStandaloneModeExchangePlans = True) Export
	
	If QueryOptions = Undefined Then
		QueryOptions = ExchangePlansForMonitorQueryParameters();
	EndIf;
	
	ExchangePlansArray1                 = QueryOptions.ExchangePlansArray1;
	AdditionalExchangePlanProperties = QueryOptions.AdditionalExchangePlanProperties;
	ResultToTemporaryTable       = QueryOptions.ResultToTemporaryTable;
	
	If Not ValueIsFilled(ExchangePlansArray1) Then
		ExchangePlansArray1 = DataExchangeCached.SSLExchangePlans();
	EndIf;
	
	MethodExchangePlans = ExchangePlansFilterByDataSeparationFlag(ExchangePlansArray1);
	
	If DataExchangeCached.StandaloneModeSupported()
		And ExcludeStandaloneModeExchangePlans Then
		
		// 
		MethodExchangePlans = ExchangePlansFilterByStandaloneModeFlag(MethodExchangePlans);
		
	EndIf;
	
	AdditionalExchangePlanPropertiesAsString = ?(IsBlankString(AdditionalExchangePlanProperties), "", AdditionalExchangePlanProperties + ", ");
	
	AssociationSection = "
	|
	|UNION ALL
	|";
	
	QueryTemplate = AssociationSection + 
	"//////////////////////////////////////////////////////// {&ИмяТаблицыПланаОбмена}
	|SELECT
	|
	|	&AdditionalExchangePlanProperties,
	|
	|	Ref                      AS InfobaseNode,
	|	Description                AS Description,
	|	""&ExchangePlanNameSynonym"" AS ExchangePlanName
	|FROM
	|	&ExchangePlanTableName
	|WHERE
	|	     NOT ThisNode
	|	AND NOT DeletionMark
	|";
	
	QueryText = "";
	
	If MethodExchangePlans.Count() > 0 Then
		
		TemplateForTheNameOfTheExchangePlanTable = "ExchangePlan.%1";
		
		For Each ExchangePlanName In MethodExchangePlans Do
			
			ExchangePlanTableName = StringFunctionsClientServer.SubstituteParametersToString(TemplateForTheNameOfTheExchangePlanTable, ExchangePlanName);
			
			ExchangePlanQueryText = StrReplace(QueryTemplate,              "&ExchangePlanTableName", ExchangePlanTableName);
			ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "&ExchangePlanNameSynonym", Metadata.ExchangePlans[ExchangePlanName].Synonym);
			ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "&AdditionalExchangePlanProperties,", AdditionalExchangePlanPropertiesAsString);
			
			// 
			If IsBlankString(QueryText) Then
				
				ExchangePlanQueryText = StrReplace(ExchangePlanQueryText, "UNION ALL", "");
				
			EndIf;
			
			QueryText = QueryText + ExchangePlanQueryText;
			
		EndDo;
		
	Else
		
		AdditionalPropertiesWithoutDataSourceAsString = "";
		
		If Not IsBlankString(AdditionalExchangePlanProperties) Then
			
			AdditionalProperties = StrSplit(AdditionalExchangePlanProperties, ",");
			
			AdditionalPropertiesWithoutDataSource = New Array;
			
			For Each Property In AdditionalProperties Do
				
				AdditionalPropertiesWithoutDataSource.Add(StrReplace("UNDEFINED AS [Property]", "[Property]", Property));
				
			EndDo;
			
			AdditionalPropertiesWithoutDataSourceAsString = StrConcat(AdditionalPropertiesWithoutDataSource, ",") + ", ";
			
		EndIf;
		
		QueryText = "
		|SELECT
		|
		|	&AdditionalPropertiesWithoutDataSourceAsString,
		|
		|	UNDEFINED AS InfobaseNode,
		|	UNDEFINED AS Description,
		|	UNDEFINED AS ExchangePlanName
		|";
		
		QueryText = StrReplace(QueryText, "&AdditionalPropertiesWithoutDataSourceAsString,", AdditionalPropertiesWithoutDataSourceAsString);
		
	EndIf;
	
	QueryTextResult = "
	|//////////////////////////////////////////////////////// {ConfigurationExchangePlans}
	|SELECT
	|
	|	&AdditionalExchangePlanProperties,
	|
	|	InfobaseNode,
	|	Description,
	|	ExchangePlanName
	|INTO ConfigurationExchangePlans
	|FROM
	|	&QueryText AS NestedQuery
	|;
	|";
	
	If ResultToTemporaryTable <> True Then
		
		QueryTextResult = StrReplace(QueryTextResult, "INTO ConfigurationExchangePlans", "");
		
	EndIf;
	
	WrappedRequestText = StringFunctionsClientServer.SubstituteParametersToString("(%1)", QueryText);
	QueryTextResult = StrReplace(QueryTextResult, "&QueryText", WrappedRequestText);
	
	QueryTextResult = StrReplace(QueryTextResult, "&AdditionalExchangePlanProperties,", AdditionalExchangePlanPropertiesAsString);
	
	Return QueryTextResult;
	
EndFunction

Procedure GetDataExchangesStates(TempTablesManager)
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
		ModuleDataExchangeSaaS.GetDataExchangesStates(TempTablesManager);
	Else
		Query = New Query(
		"SELECT
		|	DataExchangesStates.InfobaseNode AS InfobaseNode,
		|	DataExchangesStates.StartDate AS StartDate,
		|	DataExchangesStates.EndDate AS EndDate,
		|	CASE
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Warning_ExchangeMessageAlreadyAccepted)
		|				OR DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
		|			THEN CASE
		|					WHEN ISNULL(IssuesCount.Count, 0) > 0
		|						THEN 2
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END AS ExchangeExecutionResult
		|INTO DataExchangeStatesImport
		|FROM
		|	InformationRegister.DataExchangesStates AS DataExchangesStates
		|		LEFT JOIN IssuesCount AS IssuesCount
		|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
		|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
		|WHERE
		|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataExchangesStates.InfobaseNode AS InfobaseNode,
		|	DataExchangesStates.StartDate AS StartDate,
		|	DataExchangesStates.EndDate AS EndDate,
		|	CASE
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.CompletedWithWarnings)
		|			THEN 2
		|		WHEN DataExchangesStates.ExchangeExecutionResult = VALUE(Enum.ExchangeExecutionResults.Completed2)
		|			THEN CASE
		|					WHEN ISNULL(IssuesCount.Count, 0) > 0
		|						THEN 2
		|					ELSE 0
		|				END
		|		ELSE 1
		|	END AS ExchangeExecutionResult
		|INTO DataExchangeStatesExport
		|FROM
		|	InformationRegister.DataExchangesStates AS DataExchangesStates
		|		LEFT JOIN IssuesCount AS IssuesCount
		|		ON DataExchangesStates.InfobaseNode = IssuesCount.InfobaseNode
		|			AND DataExchangesStates.ActionOnExchange = IssuesCount.ActionOnExchange
		|WHERE
		|	DataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
		|	SuccessfulDataExchangesStates.EndDate AS EndDate
		|INTO SuccessfulDataExchangeStatesImport
		|FROM
		|	InformationRegister.SuccessfulDataExchangesStates AS SuccessfulDataExchangesStates
		|WHERE
		|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataImport)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SuccessfulDataExchangesStates.InfobaseNode AS InfobaseNode,
		|	SuccessfulDataExchangesStates.EndDate AS EndDate
		|INTO SuccessfulDataExchangeStatesExport
		|FROM
		|	InformationRegister.SuccessfulDataExchangesStates AS SuccessfulDataExchangesStates
		|WHERE
		|	SuccessfulDataExchangesStates.ActionOnExchange = VALUE(Enum.ActionsOnExchange.DataExport)");
		
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	EndIf;
	
EndProcedure

Procedure GetExchangeResultsForMonitor(TempTablesManager)
	
	Query = New Query;
	
	If Common.SeparatedDataUsageAvailable() Then
		
		QueryTextResult = 
		"SELECT
		|	DataExchangeResults.InfobaseNode AS InfobaseNode,
		|	CASE
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.UnpostedDocument), VALUE(Enum.DataExchangeIssuesTypes.BlankAttributes), VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData))
		|			THEN VALUE(Enum.ActionsOnExchange.DataImport)
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.ApplicationAdministrativeError), VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData), VALUE(Enum.DataExchangeIssuesTypes.ConvertedObjectValidationError))
		|			THEN VALUE(Enum.ActionsOnExchange.DataExport)
		|		ELSE UNDEFINED
		|	END AS ActionOnExchange,
		|	COUNT(DISTINCT DataExchangeResults.ObjectWithIssue) AS Count
		|INTO IssuesCount
		|FROM
		|	InformationRegister.DataExchangeResults AS DataExchangeResults
		|WHERE
		|	DataExchangeResults.IsSkipped = FALSE
		|
		|GROUP BY
		|	DataExchangeResults.InfobaseNode,
		|	CASE
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.UnpostedDocument), VALUE(Enum.DataExchangeIssuesTypes.BlankAttributes), VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnGetData))
		|			THEN VALUE(Enum.ActionsOnExchange.DataImport)
		|		WHEN DataExchangeResults.IssueType IN (VALUE(Enum.DataExchangeIssuesTypes.ApplicationAdministrativeError), VALUE(Enum.DataExchangeIssuesTypes.HandlersCodeExecutionErrorOnSendData), VALUE(Enum.DataExchangeIssuesTypes.ConvertedObjectValidationError))
		|			THEN VALUE(Enum.ActionsOnExchange.DataExport)
		|		ELSE UNDEFINED
		|	END";
		
	Else
		
		QueryTextResult = 
		"SELECT
		|	UNDEFINED AS InfobaseNode,
		|	UNDEFINED AS ActionOnExchange,
		|	UNDEFINED AS Count
		|INTO IssuesCount";
		
	EndIf;
	
	Query.Text = QueryTextResult;
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Procedure GetMessagesToMapData(TempTablesManager)
	
	If Common.SeparatedDataUsageAvailable() Then
		If Common.DataSeparationEnabled()
			And Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
			ModuleDataExchangeSaaS = Common.CommonModule("DataExchangeSaaS");
			ModuleDataExchangeSaaS.GetMessagesToMapData(TempTablesManager);
		Else
			Query = New Query(
			"SELECT
			|	CommonInfobasesNodesSettings.InfobaseNode AS InfobaseNode,
			|	CASE
			|		WHEN COUNT(CommonInfobasesNodesSettings.MessageForDataMapping) > 0
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS MessageReceivedForDataMapping,
			|	MAX(DataExchangeMessages.MessageStoredDate) AS LastMessageStoragePlacementDate
			|INTO MessagesForDataMapping
			|FROM
			|	InformationRegister.CommonInfobasesNodesSettings AS CommonInfobasesNodesSettings
			|		INNER JOIN InformationRegister.DataExchangeMessages AS DataExchangeMessages
			|		ON (DataExchangeMessages.MessageID = CommonInfobasesNodesSettings.MessageForDataMapping)
			|
			|GROUP BY
			|	CommonInfobasesNodesSettings.InfobaseNode");
			
			Query.TempTablesManager = TempTablesManager;
			Query.Execute();
		EndIf;
	Else
		Query = New Query(
		"SELECT
		|	NULL AS InfobaseNode,
		|	NULL AS MessageReceivedForDataMapping,
		|	NULL AS LastMessageStoragePlacementDate
		|INTO MessagesForDataMapping");
		
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	EndIf;
	
EndProcedure

Function ExchangePlansWithRulesFromFile()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DataExchangeRules.ExchangePlanName
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.RulesSource = &RulesSource";
	
	Query.SetParameter("RulesSource", Enums.DataExchangeRulesSources.File);
	Result = Query.Execute().Unload();
	
	Return Result.Count();
	
EndFunction

Procedure CheckExternalConnectionAvailability()
	
	If Common.IsLinuxServer() Then
		
		Raise NStr("en = 'Data synchronization via direct server connection is not available on Linux.
			|Use Windows OS to synchronize data via direct connection.';");
			
	EndIf;
	
EndProcedure

// Populates the list of values for available modes of transport for the exchange plan node.
//
Procedure FillChoiceListWithAvailableTransportTypes(InfobaseNode, FormItem, Filter = Undefined) Export
	
	FilterSet = (Filter <> Undefined);
	
	UsedTransports = DataExchangeCached.UsedExchangeMessagesTransports(InfobaseNode);
	
	FormItem.ChoiceList.Clear();
	
	For Each Item In UsedTransports Do
		
		If FilterSet Then
			
			If Filter.Find(Item) <> Undefined Then
				
				FormItem.ChoiceList.Add(Item, String(Item));
				
			EndIf;
			
		Else
			
			FormItem.ChoiceList.Add(Item, String(Item));
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Records the state of data exchange in the data Exchange state information register.
//
// Parameters:
//  ExchangeSettingsStructure - Structure -  a structure with all the necessary data and objects to perform the exchange.
// 
Procedure WriteExchangeFinishToInformationRegister(ExchangeSettingsStructure)
	
	// 
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode",    ExchangeSettingsStructure.InfobaseNode);
	RecordStructure.Insert("ActionOnExchange",         ExchangeSettingsStructure.ActionOnExchange);
	
	RecordStructure.Insert("ExchangeExecutionResult", ExchangeSettingsStructure.ExchangeExecutionResult);
	RecordStructure.Insert("StartDate",                ExchangeSettingsStructure.StartDate);
	RecordStructure.Insert("EndDate",             ExchangeSettingsStructure.EndDate);
	
	InformationRegisters.DataExchangesStates.AddRecord(RecordStructure);
	
EndProcedure

Procedure AddSuccessfulDataExchangeMessageToInformationRegister(ExchangeSettingsStructure)
	
	// 
	RecordStructure = New Structure;
	RecordStructure.Insert("InfobaseNode", ExchangeSettingsStructure.InfobaseNode);
	RecordStructure.Insert("ActionOnExchange",      ExchangeSettingsStructure.ActionOnExchange);
	RecordStructure.Insert("EndDate",          ExchangeSettingsStructure.EndDate);
	
	InformationRegisters.SuccessfulDataExchangesStates.AddRecord(RecordStructure);
	
EndProcedure

Procedure WriteLogEventDataExchangeStart(ExchangeSettingsStructure) Export
	
	MessageString = NStr("en = 'Data exchange started. Node: %1';", Common.DefaultLanguageCode());
	MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, ExchangeSettingsStructure.InfobaseNodeDescription);
	WriteEventLogDataExchange(MessageString, ExchangeSettingsStructure);
	
EndProcedure

Procedure WriteDataReceivingEvent(Val InfobaseNode, Val Comment, Val IsError = False)
	
	Level = ?(IsError, EventLogLevel.Error, EventLogLevel.Information);
	
	EventLogMessageKey = EventLogMessageKey(InfobaseNode, Enums.ActionsOnExchange.DataImport);
	
	WriteLogEvent(EventLogMessageKey, Level,,, Comment);
	
EndProcedure

Procedure NodeSettingsFormOnCreateAtServerHandler(Form, FormAttributeName)
	
	FormAttributes = FormAttributesNames(Form);
	
	For Each FilterSettings In Form[FormAttributeName] Do
		
		Var_Key = FilterSettings.Key;
		
		If FormAttributes.Find(Var_Key) = Undefined Then
			Continue;
		EndIf;
		
		If TypeOf(Form[Var_Key]) = Type("FormDataCollection") Then
			
			Table = New ValueTable;
			
			TabularSectionStructure = Form.Parameters[FormAttributeName][Var_Key];
			
			For Each Item In TabularSectionStructure Do
				
				While Table.Count() < Item.Value.Count() Do
					Table.Add();
				EndDo;
				
				Table.Columns.Add(Item.Key);
				
				Table.LoadColumn(Item.Value, Item.Key);
				
			EndDo;
			
			Form[Var_Key].Load(Table);
			
		Else
			
			Form[Var_Key] = Form.Parameters[FormAttributeName][Var_Key];
			
		EndIf;
		
		Form[FormAttributeName][Var_Key] = Form.Parameters[FormAttributeName][Var_Key];
		
	EndDo;
	
EndProcedure

Function FormAttributesNames(Form)
	
	// 
	Result = New Array;
	
	For Each FormAttribute In Form.GetAttributes() Do
		
		Result.Add(FormAttribute.Name);
		
	EndDo;
	
	Return Result;
EndFunction

// Unpacks the ZIP archive file to the specified directory; Extracts all archive files.
//
// Parameters:
//  FullArchiveFileName  - String -  the file name of the archive that must be decompressed.
//  FilesUnpackPath  - String -  the way in which you need to extract the files.
//  ArchivePassword          - String -  password for unpacking the archive. By default, an empty string.
// 
// Returns:
//  Результат - 
//
Function UnpackZipFile(Val FullArchiveFileName, Val FilesUnpackPath, Val ArchivePassword = "") Export
	
	Result = True;
	
	Archiver = Undefined;
	Try
		Archiver = New ZipFileReader(FullArchiveFileName, ArchivePassword);
		Archiver.ExtractAll(FilesUnpackPath, ZIPRestoreFilePathsMode.DontRestore);
	Except
		ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot extract files from archive ""%1"" to directory ""%2"". Reason:
			|%3';"),
			FullArchiveFileName,
			FilesUnpackPath,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(DataExchangeEventLogEvent(),
			EventLogLevel.Error, , , ErrorInfo);
		
		Result = False;
	EndTry;
	
	If Archiver <> Undefined Then
		Archiver.Close();
	EndIf;
	
	Return Result;
	
EndFunction

// Packs the specified folder into a ZIP file.
//
// Parameters:
//  FullArchiveFileName  - String -  name of the archive file to be Packed in.
//  FilesPackingMask    - String -  name of the file to be archived, or mask.
//			It is not allowed to use letters of national alphabets in the names of files and folders, which 
//			can be converted from UNICODE characters to narrow characters with loss of information. 
//			We recommend using Latin characters in file and folder names. 
//  ArchivePassword          - String -  password for the archive. By default, an empty string.
// 
// Returns:
//  Результат - 
//
Function PackIntoZipFile(Val FullArchiveFileName, Val FilesPackingMask, Val ArchivePassword = "") Export
	
	// 
	Result = True;
	
	Try
		
		Archiver = New ZipFileWriter(FullArchiveFileName, ArchivePassword);
		
	Except
		Archiver = Undefined;
		ReportError(ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Return False;
	EndTry;
	
	Try
		
		Archiver.Add(FilesPackingMask, ZIPStorePathMode.DontStorePath);
		Archiver.Write();
		
	Except
		ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot add files ""%1"" to archive ""%2"". Reason:
			|%3';"),
			FilesPackingMask,
			FullArchiveFileName,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(DataExchangeEventLogEvent(),
			EventLogLevel.Error, , , ErrorInfo);
		
		Result = False;
	EndTry;
	
	Archiver = Undefined;
	
	Return Result;
	
EndFunction

// Returns the number of records in the database table.
//
// Parameters:
//  TableName - String -  full name of the database table. For Example: "Directory.Contractors.Orders".
// 
// Returns:
//  Number - 
//
Function RecordsCountInInfobaseTable(Val TableName) Export
	
	QueryText = "
	|SELECT
	|	COUNT(*) AS Count
	|FROM
	|	#TableName
	|";
	
	QueryText = StrReplace(QueryText, "#TableName", TableName);
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection["Count"];
	
EndFunction

// Returns the number of records in the temporary database table.
//
// Parameters:
//  TableName - String -  table name. For example: "Temporary Table1".
//  TempTablesManager - 
// 
// Returns:
//  Number - 
//
Function TempInfobaseTableRecordCount(Val TableName, TempTablesManager) Export
	
	QueryText = "
	|SELECT
	|	COUNT(*) AS Count
	|FROM
	|	#TableName
	|";
	
	QueryText = StrReplace(QueryText, "#TableName", TableName);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.TempTablesManager = TempTablesManager;
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection["Count"];
	
EndFunction

// Returns the key of the log message.
//
Function EventLogMessageKey(InfobaseNode, ActionOnExchange) Export
	
	ExchangePlanName     = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	MessageKey = NStr("en = 'Data exchange.[ExchangePlanName].[ActionOnExchange]';",
		Common.DefaultLanguageCode());
	
	MessageKey = StrReplace(MessageKey, "[ExchangePlanName]",    ExchangePlanName);
	MessageKey = StrReplace(MessageKey, "[ActionOnExchange]", ActionOnExchange);
	
	Return MessageKey;
	
EndFunction

// Returns an indication that the item is part of a subset of standard items.
// 
// Parameters:
//   StandardAttributes - StandardAttributeDescriptions -  collection of standard Bank details.
//   AttributeName - String -  name of the item to check.
// 
// Returns:
//   Boolean - 
//
Function IsStandardAttribute(StandardAttributes, AttributeName) Export
	
	For Each Attribute In StandardAttributes Do
		
		If Attribute.Name = AttributeName Then
			
			Return True;
			
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

// Generates and returns the key of the data table.
// The table key is used to selectively load data from the exchange message using the specified key.
//
Function DataTableKey(Val SourceType, Val DestinationType, Val IsObjectDeletion) Export
	
	Return SourceType + "#" + DestinationType + "#" + String(IsObjectDeletion);
	
EndFunction

Function MustExecuteHandler(Object, Ref, PropertyName)
	
	NumberAfterProcessing = Object[PropertyName];
	
	NumberBeforeProcessing = Common.ObjectAttributeValue(Ref, PropertyName);
	
	NumberBeforeProcessing = ?(NumberBeforeProcessing = Undefined, 0, NumberBeforeProcessing);
	
	Return NumberBeforeProcessing <> NumberAfterProcessing;
	
EndFunction

Function FillExternalConnectionParameters(TransportSettings)
	
	ConnectionParameters = CommonClientServer.ParametersStructureForExternalConnection();
	
	ConnectionParameters.InfobaseOperatingMode             = TransportSettings.COMInfobaseOperatingMode;
	ConnectionParameters.InfobaseDirectory                   = TransportSettings.COMInfobaseDirectory;
	ConnectionParameters.NameOf1CEnterpriseServer                     = TransportSettings.COM1CEnterpriseServerName;
	ConnectionParameters.NameOfInfobaseOn1CEnterpriseServer = TransportSettings.COM1CEnterpriseServerSideInfobaseName;
	ConnectionParameters.OperatingSystemAuthentication           = TransportSettings.COMOperatingSystemAuthentication;
	ConnectionParameters.UserName                             = TransportSettings.COMUserName;
	ConnectionParameters.UserPassword                          = TransportSettings.COMUserPassword;
	
	Return ConnectionParameters;
EndFunction

Function AddLiteralToFileName(Val FullFileName, Val Literal)
	
	If IsBlankString(FullFileName) Then
		Return "";
	EndIf;
	
	FileNameWithoutExtension = Mid(FullFileName, 1, StrLen(FullFileName) - 4);
	
	Extension = Right(FullFileName, 3);
	
	Result = "[FileNameWithoutExtension]_[Literal].[Extension]";
	
	Result = StrReplace(Result, "[FileNameWithoutExtension]", FileNameWithoutExtension);
	Result = StrReplace(Result, "[Literal]",               Literal);
	Result = StrReplace(Result, "[Extension]",            Extension);
	
	Return Result;
EndFunction

Function PredefinedExchangePlanNodeDescription(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	Return Common.ObjectAttributeValue(DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName), "Description");
EndFunction

Procedure OnSSLDataExportHandler(
		Handlers,
		ExecutionParameters,
		StandardProcessing,
		MessageData,
		SentObjectsCount)
	
	For Each Handler In Handlers Do
		
		If Not StandardProcessing Then
			Break;
		EndIf;
		
		SentObjectsCount = 0;
		
		Handler.OnDataExport(StandardProcessing,
			ExecutionParameters.InfobaseNode,
			ExecutionParameters.ExchangeMessageFileName,
			MessageData,
			ExecutionParameters.TransactionItemsCount,
			ExecutionParameters.EventLogMessageKey,
			SentObjectsCount);
		
	EndDo;
	
EndProcedure

Procedure OnSSLDataImportHandler(
		Handlers,
		ExecutionParameters,
		StandardProcessing,
		MessageData,
		ReceivedObjectsCount)
	
	For Each Handler In Handlers Do
		
		If Not StandardProcessing Then
			Break;
		EndIf;
		
		ReceivedObjectsCount = 0;
		
		Handler.OnDataImport(StandardProcessing,
			ExecutionParameters.InfobaseNode,
			ExecutionParameters.ExchangeMessageFileName,
			MessageData,
			ExecutionParameters.TransactionItemsCount,
			ExecutionParameters.EventLogMessageKey,
			ReceivedObjectsCount);
		
	EndDo;
	
EndProcedure

Procedure WriteExchangeFinishWithError(Val InfobaseNode, 
												Val ActionOnExchange, 
												Val StartDate, 
												Val ErrorMessageString) Export
	
	If TypeOf(ActionOnExchange) = Type("String") Then
		
		ActionOnExchange = Enums.ActionsOnExchange[ActionOnExchange];
		
	EndIf;
	
	ExchangeSettingsStructure = New Structure;
	ExchangeSettingsStructure.Insert("InfobaseNode", InfobaseNode);
	ExchangeSettingsStructure.Insert("ExchangeExecutionResult", Enums.ExchangeExecutionResults.Error);
	ExchangeSettingsStructure.Insert("ActionOnExchange", ActionOnExchange);
	ExchangeSettingsStructure.Insert("ProcessedObjectsCount", 0);
	ExchangeSettingsStructure.Insert("EventLogMessageKey", EventLogMessageKey(InfobaseNode, ActionOnExchange));
	ExchangeSettingsStructure.Insert("StartDate", StartDate);
	ExchangeSettingsStructure.Insert("EndDate", CurrentSessionDate());
	ExchangeSettingsStructure.Insert("IsDIBExchange", DataExchangeCached.IsDistributedInfobaseNode(InfobaseNode));
	
	WriteEventLogDataExchange(ErrorMessageString, ExchangeSettingsStructure, True);
	
	WriteExchangeFinish(ExchangeSettingsStructure);
	
EndProcedure

// Checks the presence of the specified details in the form.
// If at least one of the details is missing, it raises an exception.
//
Procedure CheckMandatoryFormAttributes(Form, Val Attributes)
	
	AbsentAttributes = New Array;
	
	FormAttributes = FormAttributesNames(Form);
	
	For Each Attribute In StrSplit(Attributes, ",") Do
		
		Attribute = TrimAll(Attribute);
		
		If FormAttributes.Find(Attribute) = Undefined Then
			
			AbsentAttributes.Add(Attribute);
			
		EndIf;
		
	EndDo;
	
	If AbsentAttributes.Count() > 0 Then
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Node settings required: %1';"),
			StrConcat(AbsentAttributes, ","));
	EndIf;
	
EndProcedure

Procedure ExternalConnectionUpdateDataExchangeSettings(Val ExchangePlanName, Val NodeCode, Val DefaultNodeValues) Export
	
	SetPrivilegedMode(True);
	
	InfobaseNode = ExchangePlans[ExchangePlanName].FindByCode(NodeCode);
	
	If Not ValueIsFilled(InfobaseNode) Then
		Message = NStr("en = 'Node not found. Exchange plan: %1. Node ID: %2';");
		Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ExchangePlanName, NodeCode);
		Raise Message;
	EndIf;
	
	DataExchangeCreationWizard = ModuleDataExchangeCreationWizard().Create();
	DataExchangeCreationWizard.InfobaseNode = InfobaseNode;
	DataExchangeCreationWizard.ExternalConnectionUpdateDataExchangeSettings(GetFilterSettingsValues(DefaultNodeValues));
	
EndProcedure

Function TableNameFromExchangePlanTabularSectionFirstAttribute(Val ExchangePlanName, Val TabularSectionName)
	
	TabularSection = Metadata.ExchangePlans[ExchangePlanName].TabularSections[TabularSectionName];
	
	For Each Attribute In TabularSection.Attributes Do
		
		Type = Attribute.Type.Types()[0];
		
		If Common.IsReference(Type) Then
			
			Return Metadata.FindByType(Type).FullName();
			
		EndIf;
		
	EndDo;
	
	Return "";
EndFunction

Function AllExchangePlanDataExceptCatalogs(Val ExchangePlanName)
	
	If TypeOf(ExchangePlanName) <> Type("String") Then
		
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlanName);
		
	EndIf;
	
	Result = New Array;
	
	ExchangePlanContent = Metadata.ExchangePlans[ExchangePlanName].Content;
	
	For Each Item In ExchangePlanContent Do
		
		If Not (Common.IsCatalog(Item.Metadata)
			Or Common.IsChartOfCharacteristicTypes(Item.Metadata)) Then
			
			Result.Add(Item.Metadata);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function AccountingParametersSettingsAreSet(Val ExchangePlanName, Val Peer, ErrorMessage)
	
	If TypeOf(Peer) = Type("String") Then
		
		If IsBlankString(Peer) Then
			Return False;
		EndIf;
		
		CorrespondentCode1 = Peer;
		
		Peer = ExchangePlans[ExchangePlanName].FindByCode(Peer);
		
		If Not ValueIsFilled(Peer) Then
			Message = NStr("en = 'Node not found. Exchange plan: %1. Node ID: %2';");
			Message = StringFunctionsClientServer.SubstituteParametersToString(Message, ExchangePlanName, CorrespondentCode1);
			Raise Message;
		EndIf;
		
	EndIf;
	
	Cancel = False;
	If HasExchangePlanManagerAlgorithm("AccountingSettingsCheckHandler", ExchangePlanName) Then
		SetPrivilegedMode(True);
		ExchangePlans[ExchangePlanName].AccountingSettingsCheckHandler(Cancel, Peer, ErrorMessage);
	EndIf;
	
	Return Not Cancel;
EndFunction

Function GetInfobaseParameters(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return ValueToStringInternal(InfoBaseAdmParams(ExchangePlanName, NodeCode, ErrorMessage));
	
EndFunction

Function GetInfobaseParameters_2_0_1_6(Val ExchangePlanName, Val NodeCode, ErrorMessage) Export
	
	Return Common.ValueToXMLString(InfoBaseAdmParams(ExchangePlanName, NodeCode, ErrorMessage));
	
EndFunction

Function GetInfobaseParameters_3_0_2_2(Val ExchangePlanName, Val NodeCode, ErrorMessage, 
	AdditionalParameters = Undefined) Export
		
	IBParameters = InfoBaseAdmParams(ExchangePlanName, NodeCode, ErrorMessage, AdditionalParameters);
	
	Return Common.ValueToXMLString(IBParameters);
	
EndFunction

Function MetadataObjectProperties(Val FullTableName) Export
	
	Result = New Structure("Synonym, Hierarchical");
	
	MetadataObject = Metadata.FindByFullName(FullTableName);
	
	FillPropertyValues(Result, MetadataObject);
	
	Return Result;
EndFunction

Function GetTableObjects(Val FullTableName) Export
	SetPrivilegedMode(True);
	
	MetadataObject = Metadata.FindByFullName(FullTableName);
	
	If Common.IsCatalog(MetadataObject) Then
		
		If MetadataObject.Hierarchical Then
			If MetadataObject.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems Then
				Return HierarchicalCatalogItemsHierarchyFoldersAndItems(FullTableName);
			EndIf;
			
			Return HierarchicalCatalogItemsHierarchyItems(FullTableName);
		EndIf;
		
		Return NonhierarchicalCatalogItems(FullTableName);
		
	ElsIf Common.IsChartOfCharacteristicTypes(MetadataObject) Then
		
		If MetadataObject.Hierarchical Then
			Return HierarchicalCatalogItemsHierarchyFoldersAndItems(FullTableName);
		EndIf;
		
		Return NonhierarchicalCatalogItems(FullTableName);
		
	EndIf;
	
	Return Undefined;
EndFunction

Function HierarchicalCatalogItemsHierarchyFoldersAndItems(Val FullTableName)
	
	QueryTextTemplate2 =
		"SELECT TOP 2000
		|	AliasOfTheMetadataTable.Ref,
		|	AliasOfTheMetadataTable.Presentation,
		|	CASE
		|		WHEN AliasOfTheMetadataTable.IsFolder
		|		AND NOT AliasOfTheMetadataTable.DeletionMark
		|			THEN 0
		|		WHEN AliasOfTheMetadataTable.IsFolder
		|		AND AliasOfTheMetadataTable.DeletionMark
		|			THEN 1
		|		WHEN NOT AliasOfTheMetadataTable.IsFolder
		|		AND NOT AliasOfTheMetadataTable.DeletionMark
		|			THEN 2
		|		WHEN NOT AliasOfTheMetadataTable.IsFolder
		|		AND AliasOfTheMetadataTable.DeletionMark
		|			THEN 3
		|	END AS PictureIndex
		|FROM
		|	&MetadataTableName AS AliasOfTheMetadataTable
		|ORDER BY
		|	AliasOfTheMetadataTable.IsFolder HIERARCHY,
		|	AliasOfTheMetadataTable.Description";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", FullTableName);
	
	Query = New Query(QueryText);		
	Return QueryResultToXMLTree(Query);
	
EndFunction

Function HierarchicalCatalogItemsHierarchyItems(Val FullTableName)
	
	QueryTextTemplate2 =
	"SELECT TOP 2000
	|	AliasOfTheMetadataTable.Ref,
	|	AliasOfTheMetadataTable.Presentation,
	|	CASE
	|		WHEN AliasOfTheMetadataTable.DeletionMark
	|			THEN 3
	|		ELSE 2
	|	END AS PictureIndex
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable
	|ORDER BY
	|	AliasOfTheMetadataTable.Description HIERARCHY";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", FullTableName);
	
	Query = New Query(QueryText);
	Return QueryResultToXMLTree(Query);
	
EndFunction

Function NonhierarchicalCatalogItems(Val FullTableName)
	
	QueryTextTemplate2 = 
	"SELECT TOP 2000
	|	AliasOfTheMetadataTable.Ref AS Ref,
	|	AliasOfTheMetadataTable.Presentation AS Presentation,
	|	CASE
	|		WHEN AliasOfTheMetadataTable.DeletionMark
	|			THEN 3
	|		ELSE 2
	|	END AS PictureIndex
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable
	|
	|ORDER BY
	|	AliasOfTheMetadataTable.Description";
	
	QueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", FullTableName);
	
	Query = New Query(QueryText);
	Return QueryResultToXMLTree(Query);
	
EndFunction

// Parameters:
//   Query - Query -  request for building a tree.
// 
// Returns:
//   ValueTree:
//     * Ref - AnyRef -  object reference.
//     * Presentation - String -  representation of objects.
//     * PictureIndex - Number -  index of the object's icon.
//
Function ItemsTree(Val Query)
	
	Return Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
EndFunction

Function QueryResultToXMLTree(Val Query)
	
	Result = ItemsTree(Query);
	Result.Columns.Add("Id", New TypeDescription("String"));
	
	FillRefIDInTree(Result.Rows);
	
	ColumnRef = Result.Columns.Find("Ref");
	If Not ColumnRef = Undefined Then
		Result.Columns.Delete(ColumnRef);
	EndIf;
	
	Return Common.ValueToXMLString(Result);
	
EndFunction

// Parameters:
//   TreeRows - ValueTreeRowCollection -  rows in the object ID tree.
//
Procedure FillRefIDInTree(TreeRows)
	
	For Each String In TreeRows Do
		String.Id = ValueToStringInternal(String.Ref);
		FillRefIDInTree(String.Rows);
	EndDo;
	
EndProcedure

Function CorrespondentData(Val FullTableName) Export
	
	Result = New Structure("MetadataObjectProperties, CorrespondentInfobaseTable");
	
	Result.MetadataObjectProperties = MetadataObjectProperties(FullTableName);
	Result.CorrespondentInfobaseTable = GetTableObjects(FullTableName);
	
	Return Result;
EndFunction

Function StatisticsInformation(StatisticsInformation, Val EnableObjectDeletion = False) Export
	
	FilterArray = StatisticsInformation.UnloadColumn("DestinationTableName");
	
	FilterString = StrConcat(FilterArray, ",");
	
	Filter = New Structure("FullName", FilterString);
	
	// 
	StatisticsInformationTree = DataExchangeCached.ConfigurationMetadata(Filter).Copy(); //ValueTree
	
	// 
	StatisticsInformationTree.Columns.Add("Key");
	StatisticsInformationTree.Columns.Add("ObjectCountInSource");
	StatisticsInformationTree.Columns.Add("ObjectCountInDestination");
	StatisticsInformationTree.Columns.Add("UnmappedObjectsCount");
	StatisticsInformationTree.Columns.Add("MappedObjectPercentage");
	StatisticsInformationTree.Columns.Add("PictureIndex");
	StatisticsInformationTree.Columns.Add("UsePreview");
	StatisticsInformationTree.Columns.Add("DestinationTableName");
	StatisticsInformationTree.Columns.Add("ObjectTypeString");
	StatisticsInformationTree.Columns.Add("TableFields");
	StatisticsInformationTree.Columns.Add("SearchFields");
	StatisticsInformationTree.Columns.Add("SourceTypeString");
	StatisticsInformationTree.Columns.Add("DestinationTypeString");
	StatisticsInformationTree.Columns.Add("IsObjectDeletion");
	StatisticsInformationTree.Columns.Add("DataImportedSuccessfully");
	
	
	// 
	Indexes = StatisticsInformation.Indexes;
	If Indexes.Count() = 0 Then
		If EnableObjectDeletion Then
			Indexes.Add("IsObjectDeletion");
			Indexes.Add("OneToMany, IsObjectDeletion");
			Indexes.Add("IsClassifier, IsObjectDeletion");
		Else
			Indexes.Add("OneToMany");
			Indexes.Add("IsClassifier");
		EndIf;
	EndIf;
	
	ProcessedRows = New Map;
	
	// 
	Filter = New Structure("OneToMany", False);
	If Not EnableObjectDeletion Then
		Filter.Insert("IsObjectDeletion", False);
	EndIf;
		
	For Each TableRow In StatisticsInformation.FindRows(Filter) Do
		TreeRow = StatisticsInformationTree.Rows.Find(TableRow.DestinationTableName, "FullName", True);
		FillPropertyValues(TreeRow, TableRow);
		
		TreeRow.Synonym = StatisticsTreeRowDataSynonym(TreeRow, TableRow.SourceTypeString);
		
		ProcessedRows[TableRow] = True;
	EndDo;
	
	// 
	Filter = New Structure("OneToMany", True);
	If Not EnableObjectDeletion Then
		Filter.Insert("IsObjectDeletion", False);
	EndIf;
	FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, ProcessedRows);
	
	// 
	Filter = New Structure("IsClassifier", True);
	If Not EnableObjectDeletion Then
		Filter.Insert("IsObjectDeletion", False);
	EndIf;
	FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, ProcessedRows);
	
	// 
	If EnableObjectDeletion Then
		Filter = New Structure("IsObjectDeletion", True);
		FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, ProcessedRows);
	EndIf;
	
	// 
	StatisticsRows = StatisticsInformationTree.Rows;
	GroupPosition = StatisticsRows.Count() - 1;
	While GroupPosition >=0 Do
		Group = StatisticsRows[GroupPosition];
		
		Items = Group.Rows;
		Position = Items.Count() - 1;
		While Position >=0 Do
			Item = Items[Position];
			
			If Item.ObjectCountInDestination = Undefined 
				And Item.ObjectCountInSource = Undefined
				And Item.Rows.Count() = 0 Then
				Items.Delete(Item);
			EndIf;
			
			Position = Position - 1;
		EndDo;
		
		If Items.Count() = 0 Then
			StatisticsRows.Delete(Group);
		EndIf;
		GroupPosition = GroupPosition - 1;
	EndDo;
	
	Return StatisticsInformationTree;
EndFunction

// Parameters:
//   StatisticsInformationTree - ValueTree
//   StatisticsInformation - ValueTable
//   Filter - Structure
//   AlreadyProcessedRows - Map
//
Procedure FillStatisticsTreeOneToMany(StatisticsInformationTree, StatisticsInformation, Filter, AlreadyProcessedRows)
	
	StringsToProcess = StatisticsInformation.FindRows(Filter);
	
	// 
	Position = StringsToProcess.UBound();
	While Position >= 0 Do
		Candidate = StringsToProcess[Position];
		
		If AlreadyProcessedRows[Candidate] <> Undefined Then
			StringsToProcess.Delete(Position);
		Else
			AlreadyProcessedRows[Candidate] = True;
		EndIf;
		
		Position = Position - 1;
	EndDo;
		
	If StringsToProcess.Count() = 0 Then
		Return;
	EndIf;
	
	StatisticsOneToMany = StatisticsInformation.Copy(StringsToProcess);
	StatisticsOneToMany.Indexes.Add("DestinationTableName");
	
	StatisticsOneToManyTemporary = StatisticsOneToMany.Copy(StringsToProcess, "DestinationTableName");
	
	StatisticsOneToManyTemporary.GroupBy("DestinationTableName");
	
	For Each TableRow In StatisticsOneToManyTemporary Do
		Rows       = StatisticsOneToMany.FindRows(New Structure("DestinationTableName", TableRow.DestinationTableName));
		TreeRow = StatisticsInformationTree.Rows.Find(TableRow.DestinationTableName, "FullName", True);
		
		For Each String In Rows Do
			NewTreeRow = TreeRow.Rows.Add();
			FillPropertyValues(NewTreeRow, TreeRow);
			FillPropertyValues(NewTreeRow, String);
			
			If String.IsObjectDeletion Then
				NewTreeRow.Picture = PictureLib.MarkToDelete;
			Else
				NewTreeRow.Synonym = StatisticsTreeRowDataSynonym(NewTreeRow, String.SourceTypeString) ;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Function DeleteClassNameFromObjectName(Val Result)
	
	Result = StrReplace(Result, "DocumentRef.", "");
	Result = StrReplace(Result, "CatalogRef.", "");
	Result = StrReplace(Result, "ChartOfCharacteristicTypesRef.", "");
	Result = StrReplace(Result, "ChartOfAccountsRef.", "");
	Result = StrReplace(Result, "ChartOfCalculationTypesRef.", "");
	Result = StrReplace(Result, "BusinessProcessRef.", "");
	Result = StrReplace(Result, "TaskRef.", "");
	
	Return Result;
EndFunction

Procedure CheckLoadedFromFileExchangeRulesAvailability(ExchangeRulesImportedFromFile, RegistrationRulesImportedFromFile)
	
	QueryText = 
		"SELECT DISTINCT
		|	DataExchangeRules.ExchangePlanName AS ExchangePlanName,
		|	DataExchangeRules.RulesKind AS RulesKind
		|FROM
		|	InformationRegister.DataExchangeRules AS DataExchangeRules
		|WHERE
		|	(DataExchangeRules.RulesSource = VALUE(Enum.DataExchangeRulesSources.File)
		|			OR DataExchangeRules.RulesSource = VALUE(Enum.DataExchangeRulesSources.CustomManager))
		|	AND DataExchangeRules.RulesAreImported";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		ExchangePlansArray1 = New Array;
		
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			If Selection.RulesKind = Enums.DataExchangeRulesTypes.ObjectsConversionRules Then
				
				ExchangeRulesImportedFromFile.Add(Selection.ExchangePlanName);
				
			ElsIf Selection.RulesKind = Enums.DataExchangeRulesTypes.ObjectsRegistrationRules Then
				
				RegistrationRulesImportedFromFile.Add(Selection.ExchangePlanName);
				
			EndIf;
			
			If ExchangePlansArray1.Find(Selection.ExchangePlanName) = Undefined Then
				
				ExchangePlansArray1.Add(Selection.ExchangePlanName);
				
			EndIf;
			
		EndDo;
		
		MessageString = NStr("en = 'The exchange plan ""%1"" uses rules exported from a file.
				|The rules might be incompatible with the new application version.
				|Update the rules to avoid exchange errors.';",
				Common.DefaultLanguageCode());
		MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, StrConcat(ExchangePlansArray1, ","));
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,, MessageString);
		
	EndIf;
	
EndProcedure

// The main function for using an external connection when exchanging.
//
// Parameters: 
//  SettingsStructure_ - 
//
// Returns:
//  Structure:
//    * Join                  - COMObject
//                                  - Undefined - 
//                                    
//    * BriefErrorDetails       - String -  short description of the error;
//    * DetailedErrorDetails     - String -  detailed description of the error;
//    * AddInAttachmentError - Boolean -  COM connection error flag.
//
Function EstablishExternalConnectionWithInfobase(SettingsStructure_) Export
	
	Result = Common.EstablishExternalConnectionWithInfobase(
		FillExternalConnectionParameters(SettingsStructure_));
	
	ExternalConnection = Result.Join;
	If ExternalConnection = Undefined Then
		// 
		Return Result;
	EndIf;
	
	// 
	
	VariantOfBuiltInCorrespondentLanguage = "";
	EmbeddedLanguageOptionsAreDifferent = False;
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian
		And ExternalConnection.Metadata.ScriptVariant <> ExternalConnection.Metadata.ObjectProperties.ScriptVariant.Russian Then
		VariantOfBuiltInCorrespondentLanguage = NStr("en = 'English';");
		EmbeddedLanguageOptionsAreDifferent = True;
	EndIf;
	
	If Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English
		And ExternalConnection.Metadata.ScriptVariant <> ExternalConnection.Metadata.ObjectProperties.ScriptVariant.English Then
		VariantOfBuiltInCorrespondentLanguage = NStr("en = 'Russian';");
		EmbeddedLanguageOptionsAreDifferent = True;
	EndIf;
	
	If EmbeddedLanguageOptionsAreDifferent Then
		
		DetailedErrorDetails = NStr("en = 'The application to connect has a different 1C:Enterprise language option (%1). Connection is unavailable.';");
		DetailedErrorDetails = StrTemplate(DetailedErrorDetails, VariantOfBuiltInCorrespondentLanguage); 
		
		Result.DetailedErrorDetails = DetailedErrorDetails;
		Result.BriefErrorDetails   = DetailedErrorDetails;
		Result.Join = Undefined;
		
		Return Result;
		
	EndIf;
		
	// 
	
	Try
		NoFullAccess = Not ExternalConnection.DataExchangeExternalConnection.RoleAvailableFullAccess();
	Except
		NoFullAccess = True;
	EndTry;
	
	If NoFullAccess Then
		Result.DetailedErrorDetails = NStr("en = 'The user on whose behalf connection to the peer application is established must be assigned the ""System administrator"" and ""Full access"" roles.';");
		Result.BriefErrorDetails   = Result.DetailedErrorDetails;
		Result.Join = Undefined;
	Else
		Try 
			InvalidState = ExternalConnection.InfobaseUpdate.InfobaseUpdateRequired();
		Except
			InvalidState = False
		EndTry;
		
		If InvalidState Then
			Result.DetailedErrorDetails = NStr("en = 'Peer application is updating.';");
			Result.BriefErrorDetails   = Result.DetailedErrorDetails;
			Result.Join = Undefined;
		EndIf;
		
	EndIf;
	
	Return Result;
EndFunction

Function TransportSettingsByExternalConnectionParameters(Parameters)
	
	// 
	TransportSettings = New Structure;
	
	TransportSettings.Insert("COMUserPassword",
		CommonClientServer.StructureProperty(Parameters, "UserPassword"));
	TransportSettings.Insert("COMUserName",
		CommonClientServer.StructureProperty(Parameters, "UserName"));
	TransportSettings.Insert("COMOperatingSystemAuthentication",
		CommonClientServer.StructureProperty(Parameters, "OperatingSystemAuthentication"));
	TransportSettings.Insert("COM1CEnterpriseServerSideInfobaseName",
		CommonClientServer.StructureProperty(Parameters, "NameOfInfobaseOn1CEnterpriseServer"));
	TransportSettings.Insert("COM1CEnterpriseServerName",
		CommonClientServer.StructureProperty(Parameters, "NameOf1CEnterpriseServer"));
	TransportSettings.Insert("COMInfobaseDirectory",
		CommonClientServer.StructureProperty(Parameters, "InfobaseDirectory"));
	TransportSettings.Insert("COMInfobaseOperatingMode",
		CommonClientServer.StructureProperty(Parameters, "InfobaseOperatingMode"));
	
	Return TransportSettings;
	
EndFunction

Procedure DeleteInsignificantCharactersInConnectionSettings(Settings) Export
	
	For Each Setting In Settings Do
		
		If TypeOf(Setting.Value) = Type("String") Then
			
			Settings.Insert(Setting.Key, TrimAll(Setting.Value));
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Displays an error message and sets the Failure parameter to "True".
//
// Parameters:
//  MessageText - String -  message text.
//  Cancel          - Boolean -  sign of failure
//
Procedure ReportError(MessageText, Cancel = False) Export
	
	Cancel = True;
	
	Common.MessageToUser(MessageText);
	
EndProcedure

// Loads rules for data exchange (PRO or PKO) in the information security system.
// 
Procedure ImportDataExchangeRules(Cancel,
										Val ExchangePlanName,
										Val RulesKind,
										Val RulesTemplateName,
										Val CorrespondentRulesTemplateName = "")
	
	RecordStructure = New Structure;
	RecordStructure.Insert("ExchangePlanName",  ExchangePlanName);
	RecordStructure.Insert("RulesKind",       RulesKind);
	
	If Not IsBlankString(CorrespondentRulesTemplateName) Then
	
		RecordStructure.Insert("CorrespondentRulesTemplateName", CorrespondentRulesTemplateName);
		
	EndIf;
	
	RecordStructure.Insert("RulesTemplateName", RulesTemplateName);
	RecordStructure.Insert("RulesSource",  Enums.DataExchangeRulesSources.ConfigurationTemplate);
	
	If RulesKind = Enums.DataExchangeRulesTypes.ObjectsRegistrationRules Then
		
		SelectiveRegistrationParameters = DataExchangeRegistrationServer.NewParametersOfExchangePlanDataSelectiveRegistration(ExchangePlanName);
		RecordStructure.Insert("SelectiveRegistrationParameters", New ValueStorage(SelectiveRegistrationParameters));
		
	EndIf;
	
	// 
	RecordSet = DataExchangeInternal.CreateInformationRegisterRecordSet(RecordStructure, "DataExchangeRules");
	
	// 
	NewRecord = RecordSet.Add();
	
	// 
	FillPropertyValues(NewRecord, RecordStructure);
	
	// 
	InformationRegisters.DataExchangeRules.ImportRules(Cancel, RecordSet[0]);
	
	If Not Cancel Then
		
		RecordSet.Write();
		
	EndIf;
	
EndProcedure

Procedure DownloadDataExchangeRegistrationManager(Cancel, Val ExchangePlanName)
	
	RecordStructure = New Structure;
	RecordStructure.Insert("ExchangePlanName",  ExchangePlanName);
	RecordStructure.Insert("RulesKind",       Enums.DataExchangeRulesTypes.ObjectsRegistrationRules);
	RecordStructure.Insert("RulesSource",  Enums.DataExchangeRulesSources.StandardManager);
	
	SelectiveRegistrationParameters = DataExchangeRegistrationServer.NewParametersOfExchangePlanDataSelectiveRegistration(ExchangePlanName);
	RecordStructure.Insert("SelectiveRegistrationParameters", New ValueStorage(SelectiveRegistrationParameters));
	
	RegistrationManagerName = DataExchangeCached.RegistrationManagerName(ExchangePlanName);
	RecordStructure.Insert("RegistrationManagerName", RegistrationManagerName);
	
	Manager = Common.CommonModule(RegistrationManagerName);
	RecordStructure.Insert("RulesInformation", Manager.RulesInformation());
	
	// 
	RecordSet = DataExchangeInternal.CreateInformationRegisterRecordSet(RecordStructure, "DataExchangeRules");
	
	// 
	NewRecord = RecordSet.Add();
	
	// 
	FillPropertyValues(NewRecord, RecordStructure);
		
	If Not Cancel Then
		
		RecordSet.Write();
		
	EndIf;
	
EndProcedure

Procedure UpdateStandardDataExchangeRuleVersion(ExchangeRulesImportedFromFile, RegistrationRulesImportedFromFile)
	
	Cancel = False;
	
	QueryTextTemplate2 =
	"SELECT
	|	COUNT(AliasOfTheMetadataTable.Ref) AS Count,
	|	""&ExchangePlanName"" AS ExchangePlanName
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable";
	
	QueryText = "";
	For Each ExchangePlanName In DataExchangeCached.SSLExchangePlans() Do
		
		If Not IsBlankString(QueryText) Then
			
			QueryText = QueryText + Chars.LF + "UNION ALL" + Chars.LF;
			
		EndIf;
		
		SubqueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", StringFunctionsClientServer.SubstituteParametersToString("ExchangePlan.%1", ExchangePlanName));
		SubqueryText = StrReplace(SubqueryText, "&ExchangePlanName", ExchangePlanName);
		QueryText = QueryText + SubqueryText;
		
	EndDo;
	
	If IsBlankString(QueryText) Then
		
		Return;
		
	EndIf;
	
	Query = New Query(QueryText);
	Result = Query.Execute().Unload();
	
	RulesUpdateExecuted = False;
	For Each ExchangePlanRecord In Result Do
		
		If ExchangePlanRecord.Count <= 1 
			And Not Common.DataSeparationEnabled() Then // 
			Continue;
		EndIf;
		
		ExchangePlanName = ExchangePlanRecord.ExchangePlanName;
		
		If DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules")
			And DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "CorrespondentExchangeRules") Then
			
			If ExchangeRulesImportedFromFile.Find(ExchangePlanName) = Undefined Then
			
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'Updating data conversion rules. Exchange plan: %1';"), ExchangePlanName);
				WriteLogEvent(DataExchangeEventLogEvent(),
					EventLogLevel.Information,,, MessageText);
				
				ImportDataExchangeRules(Cancel, ExchangePlanName, Enums.DataExchangeRulesTypes.ObjectsConversionRules,
					"ExchangeRules", "CorrespondentExchangeRules");
					
				If Not Cancel Then
					RulesUpdateExecuted = True;
					StandardSubsystemsServer.UpdateApplicationParameter(
						"StandardSubsystems.DataExchange.ConversionRules." + ExchangePlanName, True);
				EndIf;
				
			Else
				
				StandardSubsystemsServer.UpdateApplicationParameter(
					"StandardSubsystems.DataExchange.ConversionRules." + ExchangePlanName, False);
				
			EndIf;
			
		EndIf;
		
		If RegistrationRulesImportedFromFile.Find(ExchangePlanName) <> Undefined Then
				
			StandardSubsystemsServer.UpdateApplicationParameter(
				"StandardSubsystems.DataExchange.RecordRules." + ExchangePlanName, False);
			
		ElsIf Not DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "RecordRules")
			And Not DataExchangeCached.RulesForRegisteringInManager(ExchangePlanName) Then
			
			StandardSubsystemsServer.UpdateApplicationParameter(
				"StandardSubsystems.DataExchange.RecordRules." + ExchangePlanName, False);
			
		Else
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Updating data registration rules. Exchange plan: %1';"), ExchangePlanName);
				
			WriteLogEvent(DataExchangeEventLogEvent(),
				EventLogLevel.Information,,, MessageText);
					
			If DataExchangeCached.RulesForRegisteringInManager(ExchangePlanName) Then
				DownloadDataExchangeRegistrationManager(Cancel, ExchangePlanName);
			Else
				ImportDataExchangeRules(Cancel, ExchangePlanName, 
					Enums.DataExchangeRulesTypes.ObjectsRegistrationRules, "RecordRules");
			EndIf;
			
			If Not Cancel Then
				RulesUpdateExecuted = True;
				StandardSubsystemsServer.UpdateApplicationParameter(
					"StandardSubsystems.DataExchange.RecordRules." + ExchangePlanName, True);
			EndIf;

		EndIf
		
	EndDo;
	
	If Cancel Then
		Raise NStr("en = 'Error updating data exchange rules. See the event log.';");
	EndIf;
	
	If RulesUpdateExecuted Then
		DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	EndIf;
	
EndProcedure

// Gets the index of the image to display in the object mapping statistics table.
//
Function StatisticsTablePictureIndex(Val UnmappedObjectsCount, Val DataImportedSuccessfully) Export
	
	Return ?(UnmappedObjectsCount = 0, ?(DataImportedSuccessfully = True, 2, 0), 1);
	
EndFunction

// Checks that the file size of the exchange message exceeds the allowed size.
//
//  Returns:
//   Истина - 
//
Function ExchangeMessageSizeExceedsAllowed(Val FileName, Val MaxMessageSize) Export
	
	// 
	Result = False;
	
	File = New File(FileName);
	
	If File.Exists() And File.IsFile() Then
		
		If MaxMessageSize <> 0 Then
			
			PackageSize = Round(File.Size() / 1024, 0, RoundMode.Round15as20);
			
			If PackageSize > MaxMessageSize Then
				
				MessageString = NStr("en = 'The outgoing package size (%1 KB) exceeds the limit (%2 KB).';");
				MessageString = StringFunctionsClientServer.SubstituteParametersToString(MessageString, String(PackageSize), String(MaxMessageSize));
				ReportError(MessageString, Result);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function InitialDataExportFlagIsSet(InfobaseNode) Export
	
	SetPrivilegedMode(True);
	
	Return InformationRegisters.CommonInfobasesNodesSettings.InitialDataExportFlagIsSet(InfobaseNode);
	
EndFunction

// Loads an exchange message that contains
// configuration changes before updating the database.
//
Procedure ImportMessageBeforeInfobaseUpdate()
	
	If DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
			"SkipImportDataExchangeMessageBeforeStart") Then
		Return;
	EndIf;
	
	If GetFunctionalOption("UseDataSynchronization") Then
		
		InfobaseNode = MasterNode();
		
		If InfobaseNode <> Undefined Then
			
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", True);
			SetPrivilegedMode(False);
			
			Try
				// 
				UpdateDataExchangeRules();
				
				TransportKind = InformationRegisters.DataExchangeTransportSettings.DefaultExchangeMessagesTransportKind(InfobaseNode);
				
				Cancel = False;
				
				ExchangeParameters = ExchangeParameters();
				ExchangeParameters.ExchangeMessagesTransportKind = TransportKind;
				ExchangeParameters.ExecuteImport1 = True;
				ExchangeParameters.ExecuteExport2 = False;
				ExecuteDataExchangeForInfobaseNode(InfobaseNode, ExchangeParameters, Cancel);
				
				// 
				// 
				// 
				// 
				// 
				// 
				//   
				// 
				//   
				
				If Cancel Or InfobaseUpdate.InfobaseUpdateRequired() Then
					EnableDataExchangeMessageImportRecurrenceBeforeStart();
				EndIf;
				
				If Cancel Then
					Raise NStr("en = 'Receiving data from the master node is completed with errors.';");
				EndIf;
			Except
				SetPrivilegedMode(True);
				SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
				SetPrivilegedMode(False);
				Raise;
			EndTry;
			SetPrivilegedMode(True);
			SetDataExchangeMessageImportModeBeforeStart("ImportPermitted", False);
			SetPrivilegedMode(False);
		EndIf;
		
	EndIf;
	
EndProcedure

// Resets the reload flag if there is a download or update error.
Procedure DisableDataExchangeMessageImportRepeatBeforeStart() Export
	
	SetPrivilegedMode(True);
	
	If Constants.RetryDataExchangeMessageImportBeforeStart.Get() Then
		Constants.RetryDataExchangeMessageImportBeforeStart.Set(False);
	EndIf;
	
EndProcedure

// Loads and unloads an exchange message that
// contains configuration changes that did not require
// updating the database.
//
Procedure RunSyncIfInfobaseNotUpdated(
		OnClientStart, Restart)
	
	If Not LoadDataExchangeMessage() Then
		// 
		// 
		DisableDataExchangeMessageImportRepeatBeforeStart();
		Return;
	EndIf;
		
	If ConfigurationChanged() Then
		// 
		// 
		Return;
	EndIf;
	
	BeginTransaction();
	Try
		ImportMessageBeforeInfobaseUpdate();
		CommitTransaction();
	Except
		If ConfigurationChanged() Then
			If Not DataExchangeInternal.DataExchangeMessageImportModeBeforeStart(
				"MessageReceivedFromCache") Then
				// 
				// 
				// 
				// 
				// 
				CommitTransaction();
				Return;
			Else
				// 
				// 
				// 
				RollbackTransaction();
				SetPrivilegedMode(True);
				Constants.LoadDataExchangeMessage.Set(False);
				ClearDataExchangeMessageFromMasterNode();
				SetPrivilegedMode(False);
				WriteDataReceivingEvent(MasterNode(),
					NStr("en = 'Rollback to the database configuration is detected.
					           |The data synchronization is canceled.';"));
				Return;
			EndIf;
		EndIf;
		// 
		// 
		// 
		// 
		// 
		CommitTransaction();
		EnableDataExchangeMessageImportRecurrenceBeforeStart();
		If OnClientStart Then
			Restart = True;
			Return;
		EndIf;
		Raise;
	EndTry;
	
	ExportMessageAfterInfobaseUpdate();
	
EndProcedure

Function IsSubordinateDIBNode() Export
	
	Return MasterNode() <> Undefined;
	
EndFunction

// Returns an array of version numbers supported by the correspondent interface for the search engine subsystem.
// 
// Parameters:
//   ExternalConnection - объект COM-the connection that is used for working with the correspondent.
//
// Returns:
//   Array of version numbers supported by the correspondent interface.
//
Function InterfaceVersionsThroughExternalConnection(ExternalConnection) Export
	
	Return Common.GetInterfaceVersionsViaExternalConnection(ExternalConnection, "DataExchange");
	
EndFunction

// Creates a temporary directory of exchange messages.
// Records the directory name in the register for its subsequent removal.
//
Function CreateTempExchangeMessagesDirectory(DirectoryID = Undefined) Export
	
	Result = CommonClientServer.GetFullFileName(TempFilesStorageDirectory(), TempExchangeMessagesDirectoryName());
	
	CreateDirectory(Result);
	
	If Not Common.FileInfobase() Then
		
		SetPrivilegedMode(True);
		
		DirectoryID = PutFileInStorage(Result);
		
	EndIf;
	
	Return Result;
EndFunction

Function DataExchangeOption(Val Peer) Export
	
	Result = "Synchronization";
	
	If DataExchangeCached.IsDistributedInfobaseNode(Peer) Then
		Return Result;
	EndIf;
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Peer);
	SettingID = SavedExchangePlanNodeSettingOption(Peer);
	DataMappingSupported = ExchangePlanSettingValue(ExchangePlanName, 
		"DataMappingSupported", SettingID);
	
	If Not DataMappingSupported Then
		Return Result;
	EndIf;
	
	AttributesNames = Common.AttributeNamesByType(Peer, Type("EnumRef.ExchangeObjectExportModes"));
	
	AttributesValues = Common.ObjectAttributesValues(Peer, AttributesNames);
	
	For Each Attribute In AttributesValues Do
			
		If Attribute.Value = Enums.ExchangeObjectExportModes.ManualExport
			Or Attribute.Value = Enums.ExchangeObjectExportModes.NotExport Then
			
			Result = "ReceiveAndSend";
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Parameters:
//   Context - Structure -  structure with values to transfer to the object.
//   Object - DataProcessorObject.InfobasesObjectsMapping -  object-the receiver of the data.
// 
Procedure ImportObjectContext(Val Context, Val Object) Export
	
	For Each Attribute In Object.Metadata().Attributes Do
		
		If Context.Property(Attribute.Name) Then
			
			Object[Attribute.Name] = Context[Attribute.Name];
			
		EndIf;
		
	EndDo;
	
	For Each TabularSection In Object.Metadata().TabularSections Do
		
		If Context.Property(TabularSection.Name) Then
			
			Object[TabularSection.Name].Load(Context[TabularSection.Name]);
			
		EndIf;
		
	EndDo;
	
EndProcedure

// For internal use.
//
// Parameters:
//   Object - CatalogObject, ДокументОбъект и т.п. -  data object.
// 
// Returns:
//   Structure - 
//               
//
Function GetObjectContext(Val Object) Export
	
	Result = New Structure;
	
	ObjectMetadata = Object.Metadata(); // MetadataObject
	
	For Each Attribute In ObjectMetadata.Attributes Do
		
		Result.Insert(Attribute.Name, Object[Attribute.Name]);
		
	EndDo;
	
	For Each TabularSection In ObjectMetadata.TabularSections Do
		
		Result.Insert(TabularSection.Name, Object[TabularSection.Name].Unload());
		
	EndDo;
	
	Return Result;
EndFunction

// Parameters:
//   Table - ValueTable -  object-the receiver of the data.
//   Tree - ValueTreeRowCollection -  data source object.
//
Procedure ExpandValueTree(Table, Tree)
	
	For Each TreeRow In Tree Do
		
		FillPropertyValues(Table.Add(), TreeRow);
		
		If TreeRow.Rows.Count() > 0 Then
			
			ExpandValueTree(Table, TreeRow.Rows);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function DifferenceDaysCount(Val Date1, Val Date2)
	
	Return Int((BegOfDay(Date2) - BegOfDay(Date1)) / 86400);
	
EndFunction

// Parameters:
//   ValueTable - ValueTable -  table of values to convert
//
Function TableIntoStructuresArray(Val ValueTable)
	Result = New Array;
	
	ColumnsNames = "";
	For Each Column In ValueTable.Columns Do
		ColumnsNames = ColumnsNames + "," + Column.Name;
	EndDo;
	ColumnsNames = Mid(ColumnsNames, 2);
	
	For Each String In ValueTable Do
		StringStructure = New Structure(ColumnsNames);
		FillPropertyValues(StringStructure, String);
		Result.Add(StringStructure);
	EndDo;
	
	Return Result;
EndFunction

// Checking for differences between the correspondent version in the rules of the current and another program.
//
Function DifferentCorrespondentVersions(ExchangePlanName, EventLogMessageKey, VersionInCurrentApplication,
	VersionInOtherApplication, MessageText, ExternalConnectionParameters = Undefined) Export
	
	VersionInCurrentApplication = ?(ValueIsFilled(VersionInCurrentApplication), VersionInCurrentApplication, CorrespondentVersionInRules(ExchangePlanName));
	
	If ValueIsFilled(VersionInCurrentApplication) And ValueIsFilled(VersionInOtherApplication)
		And ExchangePlanSettingValue(ExchangePlanName, "WarnAboutExchangeRuleVersionMismatch") Then
		
		VersionInCurrentApplicationWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(VersionInCurrentApplication);
		VersionInOtherApplicationWithoutBuildNumber = CommonClientServer.ConfigurationVersionWithoutBuildNumber(VersionInOtherApplication);
		
		If VersionInCurrentApplicationWithoutBuildNumber <> VersionInOtherApplicationWithoutBuildNumber Then
			
			ExchangePlanSynonym = Metadata.ExchangePlans[ExchangePlanName].Synonym;
			
			MessageTemplate = NStr("en = 'Data synchronization for ""%1"" might cause errors. The application versions specified in the conversion rules do not match. Version in this app: %2. Version in peer app: %3. Ensure that the rules support both versions.';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, ExchangePlanSynonym, VersionInCurrentApplicationWithoutBuildNumber, VersionInOtherApplicationWithoutBuildNumber);
			
			WriteLogEvent(EventLogMessageKey, EventLogLevel.Warning,,, MessageText);
			
			If ExternalConnectionParameters <> Undefined
				And CommonClientServer.CompareVersions("2.2.3.18", ExternalConnectionParameters.SSLVersionByExternalConnection) <= 0
				And ExternalConnectionParameters.ExternalConnection.DataExchangeExternalConnection.WarnAboutExchangeRuleVersionMismatch(ExchangePlanName) Then
				
				ExchangePlanSynonymInOtherApplication = ExternalConnectionParameters.InfobaseNode.Metadata().Synonym;
				ExternalConnectionMessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
					ExchangePlanSynonymInOtherApplication, VersionInOtherApplicationWithoutBuildNumber, VersionInCurrentApplicationWithoutBuildNumber);
				
				ExternalConnectionParameters.ExternalConnection.WriteLogEvent(ExternalConnectionParameters.EventLogMessageKey,
					ExternalConnectionParameters.ExternalConnection.EventLogLevel.Warning,,, ExternalConnectionMessageText);
				
			EndIf;
			
			If SessionParameters.VersionDifferenceErrorOnGetData.CheckVersionDifference Then
				
				CheckStructure = New Structure(SessionParameters.VersionDifferenceErrorOnGetData);
				CheckStructure.HasError = True;
				CheckStructure.ErrorText = MessageText;
				CheckStructure.CheckVersionDifference = False;
				SessionParameters.VersionDifferenceErrorOnGetData = New FixedStructure(CheckStructure);
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return False;
	
EndFunction

Function InitializeVersionDifferenceCheckParameters(CheckVersionDifference) Export
	
	SetPrivilegedMode(True);
	
	CheckStructure = New Structure(SessionParameters.VersionDifferenceErrorOnGetData);
	CheckStructure.CheckVersionDifference = CheckVersionDifference;
	CheckStructure.HasError = False;
	SessionParameters.VersionDifferenceErrorOnGetData = New FixedStructure(CheckStructure);
	
	Return SessionParameters.VersionDifferenceErrorOnGetData;
	
EndFunction

Function VersionDifferenceErrorOnGetData() Export
	
	SetPrivilegedMode(True);
	
	Return SessionParameters.VersionDifferenceErrorOnGetData;
	
EndFunction

Function CorrespondentVersionInRules(ExchangePlanName)
	
	Query = New Query;
	Query.Text = "SELECT
	|	DataExchangeRules.ReadCorrespondentRules,
	|	DataExchangeRules.RulesKind
	|FROM
	|	InformationRegister.DataExchangeRules AS DataExchangeRules
	|WHERE
	|	DataExchangeRules.ExchangePlanName = &ExchangePlanName
	|	AND DataExchangeRules.RulesAreImported = TRUE
	|	AND DataExchangeRules.RulesKind = VALUE(Enum.DataExchangeRulesTypes.ObjectsConversionRules)";
	
	Query.SetParameter("ExchangePlanName", ExchangePlanName);
	
	Result = Query.Execute();
	
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		
		RulesStructure = Selection.ReadCorrespondentRules.Get().Conversion;
		CorrespondentVersion = Undefined;
		RulesStructure.Property("SourceConfigurationVersion", CorrespondentVersion);
		
		Return CorrespondentVersion;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Returns an extended representation of the object.
//
Function ObjectPresentation(ParameterObject) Export
	
	If ParameterObject = Undefined Then
		Return "";
	EndIf;
	ObjectMetadata = ?(TypeOf(ParameterObject) = Type("String"), Metadata.FindByFullName(ParameterObject), ParameterObject);
	
	// 
	Presentation = New Structure("ExtendedObjectPresentation, ObjectPresentation");
	FillPropertyValues(Presentation, ObjectMetadata);
	If Not IsBlankString(Presentation.ExtendedObjectPresentation) Then
		Return Presentation.ExtendedObjectPresentation;
	ElsIf Not IsBlankString(Presentation.ObjectPresentation) Then
		Return Presentation.ObjectPresentation;
	EndIf;
	
	Return ObjectMetadata.Presentation();
EndFunction

// Returns an extended view of the list of objects.
//
Function ObjectsListPresentation(ParameterObject) Export
	
	If ParameterObject = Undefined Then
		Return "";
	EndIf;
	ObjectMetadata = ?(TypeOf(ParameterObject) = Type("String"), Metadata.FindByFullName(ParameterObject), ParameterObject);
	
	// 
	Presentation = New Structure("ExtendedListPresentation, ListPresentation");
	FillPropertyValues(Presentation, ObjectMetadata);
	If Not IsBlankString(Presentation.ExtendedListPresentation) Then
		Return Presentation.ExtendedListPresentation;
	ElsIf Not IsBlankString(Presentation.ListPresentation) Then
		Return Presentation.ListPresentation;
	EndIf;
	
	Return ObjectMetadata.Presentation();
EndFunction

// Returns the upload availability flag for the specified link on the node.
//
//  Parameters:
//      ExchangeNode             - ExchangePlanRef -  node of the exchange plan that is being checked for uploading.
//      Ref                 - Arbitrary     -  the object being checked.
//      AdditionalProperties - Structure        -  additional properties passed through the object.
//
// Returns:
//  Boolean - 
//
Function RefExportAllowed(ExchangeNode, Ref, AdditionalProperties = Undefined) Export
	
	If Ref.IsEmpty() Then
		Return False;
	EndIf;
	
	RegistrationObject = Ref.GetObject();
	If RegistrationObject = Undefined Then
		// 
		Return True;
	EndIf;
	
	If AdditionalProperties <> Undefined Then
		AttributesStructure1 = New Structure("AdditionalProperties");
		FillPropertyValues(AttributesStructure1, RegistrationObject);
		AdditionalObjectProperties = AttributesStructure1.AdditionalProperties;
		
		If TypeOf(AdditionalObjectProperties) = Type("Structure") Then
			For Each KeyValue In AdditionalProperties Do
				AdditionalObjectProperties.Insert(KeyValue.Key, KeyValue.Value);
			EndDo;
		EndIf;
	EndIf;
	
	// 
	Send = DataItemSend.Auto;
	DataExchangeEvents.OnSendDataToRecipient(RegistrationObject, Send, , ExchangeNode);
	Return Send = DataItemSend.Auto;
EndFunction

// Returns the manual upload availability flag for the specified link on the node.
//
//  Parameters:
//      ExchangeNode - ExchangePlanRef -  node of the exchange plan that is being checked for uploading.
//      Ref     - Arbitrary     -   the object being checked.
//
// Returns:
//  Boolean - 
//
Function RefExportFromInteractiveAdditionAllowed(ExchangeNode, Ref) Export
	
	// 
	// 
	SetSafeModeDisabled(True);
	
	AdditionalProperties = New Structure("InteractiveExportAddition", True);
	Return RefExportAllowed(ExchangeNode, Ref, AdditionalProperties);
	
EndFunction

// Wrappers for background procedures for interactively modifying uploads.
//
Procedure InteractiveExportModificationGenerateUserTableDocument(Parameters, ResultAddress) Export
	
	ObjectOfReport        = InteractiveExportChangeObjectBySettings(Parameters.DataProcessorStructure);
	ExecutionResult = ObjectOfReport.GenerateUserSpreadsheetDocument(Parameters.FullMetadataName, Parameters.Presentation, Parameters.SimplifiedMode);
	PutToTempStorage(ExecutionResult, ResultAddress);
	
EndProcedure

Procedure InteractiveExportModificationGenerateValueTree(Parameters, ResultAddress) Export
	
	ObjectOfReport = InteractiveExportChangeObjectBySettings(Parameters.DataProcessorStructure);
	Result = ObjectOfReport.GenerateValueTree();
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

// Parameters:
//   Settings - Structure:
//     * AllDocumentsFilterComposerSettings1 - DataCompositionSettings
// 
Function InteractiveExportChangeObjectBySettings(Val Settings)
	
	ObjectOfReport = DataProcessors.InteractiveExportChange.Create();
	
	FillPropertyValues(ObjectOfReport, Settings, , "AllDocumentsFilterComposer");
	
	// 
	Data = ObjectOfReport.CommonFilterSettingsComposer();
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
	Composer.LoadSettings(Data.Settings);
	
	ObjectOfReport.AllDocumentsFilterComposer = Composer;
	
	FilterItems1 = ObjectOfReport.AllDocumentsFilterComposer.Settings.Filter.Items;
	FilterItems1.Clear();
	ObjectOfReport.AddDataCompositionFilterValues(
		FilterItems1, Settings.AllDocumentsFilterComposerSettings1.Filter.Items);
	
	Return ObjectOfReport;
EndFunction

// Returns a list of roles in the access group profile "Syncing data with other programs".
// 
Function DataSynchronizationWithOtherApplicationsAccessProfileRoles()
	
	RolesArray = New Array;
	RolesArray.Add("DataSynchronizationInProgress");
	RolesArray.Add("RemoteAccessCore");
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		RolesArray.Add("ReadObjectVersionInfo");
		
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.PeriodClosingDates")
		And Metadata.Roles.Find("ReadDataImportRestrictionDates") <> Undefined Then
		
		RolesArray.Add("ReadDataImportRestrictionDates");
		
	EndIf;
	
	Return StrConcat(RolesArray, ", ");
	
EndFunction

// See ToDoListOverridable.OnDetermineToDoListHandlers
Procedure OnFillToDoListUpdateRequired(ToDoList)
	
	ModuleToDoListServer = Common.CommonModule("ToDoListServer");
	If Not AccessRight("Administration", Metadata)
		Or ModuleToDoListServer.UserTaskDisabled("UpdateRequiredDataExchange") Then
		Return;
	EndIf;
	
	UpdateInstallationRequired = UpdateInstallationRequired();
	
	// 
	// 
	Sections = ModuleToDoListServer.SectionsForObject(Metadata.CommonForms.DataSyncSettings.FullName());
	
	For Each Section In Sections Do
		
		IDUpdateRequired = "UpdateRequiredDataExchange" + StrReplace(Section.FullName(), ".", "");
		ToDoItem = ToDoList.Add();
		ToDoItem.Id  = IDUpdateRequired;
		ToDoItem.HasToDoItems       = UpdateInstallationRequired;
		ToDoItem.Important         = True;
		ToDoItem.Presentation  = NStr("en = 'Update application version';");
		If Common.SubsystemExists("StandardSubsystems.ConfigurationUpdate") Then
			ModuleConfigurationUpdate = Common.CommonModule("ConfigurationUpdate");
			FormParameters = New Structure("ShouldExitApp, IsConfigurationUpdateReceived", False, False);
			ToDoItem.Form      = ModuleConfigurationUpdate.InstallUpdatesFormName();
			ToDoItem.FormParameters = FormParameters;
		Else
			ToDoItem.Form      = "CommonForm.AdditionalDetails";
			ToDoItem.FormParameters = New Structure("Title,TemplateName",
				NStr("en = 'Install update';"), "ManualUpdateInstruction");
		EndIf;
		ToDoItem.Owner       = Section;
		
	EndDo;
	
EndProcedure

Function StatisticsTreeRowDataSynonym(TreeRow, SourceTypeString) 
	
	Synonym = TreeRow.Synonym;
	
	Filter = New Structure("FullName, Synonym", TreeRow.FullName, Synonym);
	Existing = TreeRow.Owner().Rows.FindRows(Filter, True);
	Count   = Existing.Count();
	If Count = 0 Or (Count = 1 And Existing[0] = TreeRow) Then
		// 
		Return Synonym;
	EndIf;
	
	Synonym = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("en = '%1 (%2)';"),
		TreeRow.Synonym,
		DeleteClassNameFromObjectName(SourceTypeString));
	
	Return Synonym;
EndFunction

// Returns:
//   ValueTable - :
//     * RegisterTableName - String -  full name of the register table.
//     * RecordSet - InformationRegisterRecordSet
//                    - AccumulationRegisterRecordSet
//                    - и т.п. - 
//     * ForceDelete - Boolean -  indicates whether records are deleted unconditionally.
//
Function DetermineDocumentHasRegisterRecords(DocumentRef)
	
	MetadataOfDocument = DocumentRef.Metadata();
	If MetadataOfDocument.RegisterRecords.Count() = 0 Then
		Result = New ValueTable;
		Result.Columns.Add("RegisterTableName", New TypeDescription("String"));
		Result.Columns.Add("RecordSet");
		Result.Columns.Add("ForceDelete", New TypeDescription("Boolean"));
		
		Return Result;
	EndIf;
	
	QueryText = "";
	// 
	TablesCounter = 0;
	
	QueryTextTemplate2 = 
	"SELECT TOP 1
	|	CAST(""&MetadataTableName"" AS STRING(200)) AS RegisterTableName
	|FROM
	|	&MetadataTableName AS AliasOfTheMetadataTable
	|WHERE
	|	AliasOfTheMetadataTable.Recorder = &Recorder";
	
	For Each Movement In MetadataOfDocument.RegisterRecords Do
		// 
		// 
		// 
		// 
		// 
		// 
		
		If Not IsBlankString(QueryText) Then
			
			QueryText = QueryText + Chars.LF + "UNION ALL" + Chars.LF;
			
		EndIf;
		
		SubqueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", Movement.FullName());
		QueryText = QueryText + SubqueryText;
		
		// 
		// 
		TablesCounter = TablesCounter + 1;
		If TablesCounter = 256 Then
			
			Break;
			
		EndIf;
		
	EndDo;
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", DocumentRef);
	// 
	// 
	// 
	QueryTable = Query.Execute().Unload();
	QueryTable.Columns.Add("RecordSet");
	QueryTable.Columns.Add("ForceDelete", New TypeDescription("Boolean"));
	
	// 
	If TablesCounter = MetadataOfDocument.RegisterRecords.Count() Then
		
		Return QueryTable;
		
	EndIf;
	
	// 	
	QueryText = "";
	For Each Movement In MetadataOfDocument.RegisterRecords Do
		
		If TablesCounter > 0 Then
			
			TablesCounter = TablesCounter - 1;
			Continue;
			
		EndIf;
		
		If Not IsBlankString(QueryText) Then
			
			QueryText = QueryText + Chars.LF + "UNION ALL" + Chars.LF;
			
		EndIf;
		
		SubqueryText = StrReplace(QueryTextTemplate2, "&MetadataTableName", Movement.FullName());
		QueryText = QueryText + SubqueryText;
		
	EndDo;
	
	Query.Text = QueryText;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TableRow = QueryTable.Add();
		FillPropertyValues(TableRow, Selection);
		
	EndDo;
	
	Return QueryTable;
	
EndFunction

// Retrieves the configuration metadata tree with the specified selection by metadata objects.
//
// Parameters:
//   Filter - Structure - 
//						:
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
// Returns:
//   ValueTree - 
//
Function ConfigurationMetadataTree(Filter = Undefined) Export
	
	UseFilter1 = (Filter <> Undefined);
	
	MetadataObjectsCollections = New ValueTable;
	MetadataObjectsCollections.Columns.Add("Name");
	MetadataObjectsCollections.Columns.Add("Synonym");
	MetadataObjectsCollections.Columns.Add("Picture");
	MetadataObjectsCollections.Columns.Add("ObjectPicture");
	
	NewMetadataObjectsCollectionRow("Constants",               NStr("en = 'Constants';"),                 PictureLib.Constant,              PictureLib.Constant,                    MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("Catalogs",             NStr("en = 'Catalogs';"),               PictureLib.Catalog,             PictureLib.Catalog,                   MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("Documents",               NStr("en = 'Documents';"),                 PictureLib.Document,               PictureLib.DocumentObject,               MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("ChartsOfCharacteristicTypes", NStr("en = 'Charts of characteristic types';"), PictureLib.ChartOfCharacteristicTypes, PictureLib.ChartOfCharacteristicTypesObject, MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("ChartsOfAccounts",             NStr("en = 'Charts of accounts';"),              PictureLib.ChartOfAccounts,             PictureLib.ChartOfAccountsObject,             MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("ChartsOfCalculationTypes",       NStr("en = 'Charts of calculation types';"),       PictureLib.ChartOfCalculationTypes,       PictureLib.ChartOfCalculationTypesObject,       MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("InformationRegisters",        NStr("en = 'Information registers';"),         PictureLib.InformationRegister,        PictureLib.InformationRegister,              MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("AccumulationRegisters",      NStr("en = 'Accumulation registers';"),       PictureLib.AccumulationRegister,      PictureLib.AccumulationRegister,            MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("AccountingRegisters",     NStr("en = 'Accounting registers';"),      PictureLib.AccountingRegister,     PictureLib.AccountingRegister,           MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("CalculationRegisters",         NStr("en = 'Calculation registers';"),          PictureLib.CalculationRegister,         PictureLib.CalculationRegister,               MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("BusinessProcesses",          NStr("en = 'Business processes';"),           PictureLib.BusinessProcess,          PictureLib.BusinessProcessObject,          MetadataObjectsCollections);
	NewMetadataObjectsCollectionRow("Tasks",                  NStr("en = 'Tasks';"),                    PictureLib.Task,                 PictureLib.TaskObject,                 MetadataObjectsCollections);
	
	// 
	MetadataTree = New ValueTree;
	MetadataTree.Columns.Add("Name");
	MetadataTree.Columns.Add("FullName");
	MetadataTree.Columns.Add("Synonym");
	MetadataTree.Columns.Add("Picture");
	
	For Each CollectionRow In MetadataObjectsCollections Do
		
		TreeRow = MetadataTree.Rows.Add();
		FillPropertyValues(TreeRow, CollectionRow);
		For Each MetadataObject In Metadata[CollectionRow.Name] Do
			
			If UseFilter1 Then
				
				ObjectMeetsFilterConditions = True;
				For Each FilterElement In Filter Do
					
					Value = ?(Upper(FilterElement.Key) = Upper("FullName"), MetadataObject.FullName(), MetadataObject[FilterElement.Key]);
					If FilterElement.Value.Find(Value) = Undefined Then
						ObjectMeetsFilterConditions = False;
						Break;
					EndIf;
					
				EndDo;
				
				If Not ObjectMeetsFilterConditions Then
					Continue;
				EndIf;
				
			EndIf;
			
			MOTreeRow = TreeRow.Rows.Add();
			MOTreeRow.Name       = MetadataObject.Name;
			MOTreeRow.FullName = MetadataObject.FullName();
			MOTreeRow.Synonym   = MetadataObject.Synonym;
			MOTreeRow.Picture  = CollectionRow.ObjectPicture;
			
		EndDo;
		
	EndDo;
	
	// 
	If UseFilter1 Then
		
		// 
		CollectionItemsCount = MetadataTree.Rows.Count();
		
		For ReverseIndex = 1 To CollectionItemsCount Do
			
			CurrentIndex = CollectionItemsCount - ReverseIndex;
			TreeRow = MetadataTree.Rows[CurrentIndex];
			If TreeRow.Rows.Count() = 0 Then
				MetadataTree.Rows.Delete(CurrentIndex);
			EndIf;
			
		EndDo;
	
	EndIf;
	
	Return MetadataTree;
	
EndFunction

Procedure NewMetadataObjectsCollectionRow(Name, Synonym, Picture, ObjectPicture, Tab)
	
	NewRow = Tab.Add();
	NewRow.Name               = Name;
	NewRow.Synonym           = Synonym;
	NewRow.Picture          = Picture;
	NewRow.ObjectPicture   = ObjectPicture;
	
EndProcedure

Function PredefinedExchangePlanNodeCode(ExchangePlanName) Export
	
	SetPrivilegedMode(True);
	
	ThisNode = DataExchangeCached.GetThisExchangePlanNode(ExchangePlanName);
	
	Return TrimAll(Common.ObjectAttributeValue(ThisNode, "Code"));
	
EndFunction

// Returns an array of all nodes for the specified exchange plan except the predefined node.
//
// Parameters:
//  ExchangePlanName - String - 
// 
// Returns:
//  МассивУзлов - 
//
Function ExchangePlanNodes(ExchangePlanName) Export
	
	Query = New Query(
	"SELECT
	|	ExchangePlan.Ref AS Ref
	|FROM
	|	#ExchangePlanTableName AS ExchangePlan
	|WHERE
	|	NOT ExchangePlan.ThisNode");
	
	Query.Text = StrReplace(Query.Text, "#ExchangePlanTableName", "ExchangePlan." + ExchangePlanName);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

Function TheNameOfTheDirectoryToMapToTheFileInformationSystem() Export
	
	Return StringFunctionsClientServer.ParametersFromString(InfoBaseConnectionString()).File 
		+ GetPathSeparator() + "TempMessageForDataMatching";
	
EndFunction

Function TheFullNameOfTheFileToBeMappedIsFileInformationSystem(FileName) Export
										
	Return CommonClientServer.GetFullFileName(TheNameOfTheDirectoryToMapToTheFileInformationSystem(), FileName);
	
EndFunction

// Stops code execution for a specified time.
// The method is duplicated from the BTS, because p/s can be used without the specified library.
//
// Parameters:
//  Seconds - Number -  waiting time in seconds.
//
Procedure Pause(Seconds) Export
	
	CurrentInfobaseSession1 = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentInfobaseSession1.GetBackgroundJob();
	
	If BackgroundJob = Undefined Then
		
		Parameters = New Array;
		Parameters.Add(Seconds);
		BackgroundJob = BackgroundJobs.Execute("DataExchangeServer.Pause", Parameters);
		
	EndIf;
		
	BackgroundJob.WaitForExecutionCompletion(Seconds);
	
EndProcedure

#EndRegion

#Region InteractiveExportChange_Private

// Initializes the upload extension for the step-by-step exchange wizard.
//
// Parameters:
//     InfobaseNode - ExchangePlanRef                -  link to the node that is being configured.
//     FormStorageAddress    - String
//                            - UUID - 
//     HasNodeScenario       - Boolean                          -  flag for additional configuration.
//
// Returns:
//   Structure - :
//     * InfobaseNode - ExchangePlanRef -  link to the node that is being configured.
//     * ExportOption - Number -  the current option of discharge.
//     * AllDocumentsFilterPeriod - StandardPeriod -  document selection period. The default is the last month.
//     * AllDocumentsComposerAddress - String -  address of the document selection settings linker.
//     * AdditionalRegistration - See AdditionalExportOptionRegistrationDetails
//     * AdditionScenarioParameters - See StandardExportAdditionOptionsDetails
//     * FormStorageAddress - UUID -  unique ID of the form for temporary storage.
//
Function InteractiveExportChange(Val InfobaseNode, Val FormStorageAddress, Val HasNodeScenario = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Result = New Structure;
	Result.Insert("InfobaseNode", InfobaseNode);
	Result.Insert("ExportOption",        0);
	
	Result.Insert("AllDocumentsFilterPeriod", New StandardPeriod);
	Result.AllDocumentsFilterPeriod.Variant = StandardPeriodVariant.LastMonth;
	
	AdditionDataProcessor = DataProcessors.InteractiveExportChange.Create();
	AdditionDataProcessor.InfobaseNode = InfobaseNode;
	AdditionDataProcessor.ExportOption        = 0;
	
	// 
	Data = AdditionDataProcessor.CommonFilterSettingsComposer(FormStorageAddress);
	Result.Insert("AllDocumentsComposerAddress", PutToTempStorage(Data, FormStorageAddress));
	
	Result.Insert("AdditionalRegistration", AdditionalExportOptionRegistrationDetails());

	Result.Insert("AdditionScenarioParameters", StandardExportAdditionOptionsDetails());
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	If HasNodeScenario = Undefined Then
		// 
		HasNodeScenario = False;
	EndIf;
	
	If HasNodeScenario
		And HasExchangePlanManagerAlgorithm("SetUpInteractiveExport", ExchangePlanName) Then
		NodeManagerModule = ExchangePlans[ExchangePlanName];
		NodeManagerModule.SetUpInteractiveExport(InfobaseNode, Result.AdditionScenarioParameters);
	EndIf;
	
	Result.Insert("FormStorageAddress", FormStorageAddress);
	
	Return Result;
	
EndFunction

// Returns:
//   ValueTable - :
//     * FullMetadataName - String - 
//                                      
//                                      
//                                      
//                                      
//     * Filter - DataCompositionFilter -  the selection by default. Selection fields are formed in accordance with the General
//                                       rules for forming layout fields. For example, to specify
//                                       the selection based on the details of the document "Company", you must
//                                       use the field " Link.Company".
//     * Period - StandardPeriod -  the value of the General selection period for the default row metadata.
//     * PeriodSelection - Boolean -  indicates that this line describes a selection with a common period.
//     * Presentation - String -  the view selection.
//     * FilterAsString - String -  the selection value as a string.
//     * Count - String -  the number of items in the selection.
//
Function AdditionalExportOptionRegistrationDetails()
	
	AdditionalRegistration = New ValueTable;
	
	AdditionalRegistration.Columns.Add("FullMetadataName", New TypeDescription("String"));
	AdditionalRegistration.Columns.Add("Filter",               New TypeDescription("DataCompositionFilter"));
	AdditionalRegistration.Columns.Add("Period",              New TypeDescription("StandardPeriod"));
	AdditionalRegistration.Columns.Add("PeriodSelection",        New TypeDescription("Boolean"));
	AdditionalRegistration.Columns.Add("Presentation",       New TypeDescription("String"));
	AdditionalRegistration.Columns.Add("FilterAsString",        New TypeDescription("String"));
	AdditionalRegistration.Columns.Add("Count",          New TypeDescription("String"));
	
	Return AdditionalRegistration;
	
EndFunction

// Returns:
//   Structure - :
//     * Use - Boolean -  indicates whether the option is allowed to be used. By default, True.
//     * Order - Number -  the order in which the option is placed on the assistant form, from top to bottom. By default, 1.
//     * Title - String -  allows you to redefine the name of a typical variant.
//     * Explanation - String -  allows you to redefine the text of the explanation of the option for the user.
//
Function StandardOptionDetailsWithoutAddition()
	
	Result = New Structure;
	Result.Insert("Use", True);
	Result.Insert("Order",       1);
	Result.Insert("Title",     "");
	Result.Insert("Explanation",     NStr("en = 'Send only data selected using the common settings.';"));
	
	Return Result;
	
EndFunction

// Returns:
//   Structure - :
//     * Use - Boolean -  indicates whether the option is allowed to be used. By default, True.
//     * Order - Number -  the order in which the option is placed on the assistant form, from top to bottom. By default, 2.
//     * Title - String -  allows you to redefine the name of a typical variant.
//     * Explanation - String -  allows you to redefine the text of the explanation of the option for the user.
//
Function StandardOptionDetailsAllDocuments()
	
	Result = New Structure;
	Result.Insert("Use", True);
	Result.Insert("Order",       2);
	Result.Insert("Title",     "");
	Result.Insert("Explanation",     NStr("en = 'Also, send all documents that match the filter.';"));
	
	Return Result;
	
EndFunction

// Returns:
//   Structure - :
//     * Use - Boolean -  indicates whether the option is allowed to be used. By default, True.
//     * Order - Number -  the order in which the option is placed on the assistant form, from top to bottom. By default, 3.
//     * Title - String -  allows you to redefine the name of a typical variant.
//     * Explanation - String -  allows you to redefine the text of the explanation of the option for the user.
//
Function StandardOptionDetailsCustomFilter()
	
	Result = New Structure;
	Result.Insert("Use", True);
	Result.Insert("Order",       3);
	Result.Insert("Title",     "");
	Result.Insert("Explanation",     NStr("en = 'Also, send all data that matches the filter.';"));
	
	Return Result;
	
EndFunction

// Structure describing the standard version of the add-on upload "Variantcopyind".
//
// Returns:
//   Structure - :
//     * Use - Boolean -  indicates whether the option is allowed to be used. False by default.
//     * Order - Number -  the order in which the option is placed on the assistant form, from top to bottom. By default, 4.
//     * Title - String -  allows you to redefine the name of a typical variant.
//     * Explanation - String -  allows you to redefine the text of the explanation of the option for the user.
//     * UseFilterPeriod - Boolean -  indicates that a General selection by period is required. False by default.
//     * FilterPeriod1 - StandardPeriod -  the value of the General selection period offered by default.
//     * FilterFormName - String -  name of the form that is called to edit settings.
//     * FormCommandTitle - String -  title for drawing on the form of the command to open the settings form.
//     * Filter - See AdditionalExportOptionRegistrationDetails
//
Function StandardOptionDetailsMore()
	
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Order",       4);
	Result.Insert("Title",     "");
	Result.Insert("Explanation",     NStr("en = 'Also, send all data that matches the filter.';"));
	
	Result.Insert("UseFilterPeriod", False);
	Result.Insert("FilterPeriod1",             New StandardPeriod);
	Result.Insert("FilterFormName",           "");
	Result.Insert("FormCommandTitle",    "");
	Result.Insert("Filter",                    AdditionalExportOptionRegistrationDetails());
	
	Return Result;
	
EndFunction

// Clearing the selection of all documents.
//
// Parameters:
//     ExportAddition - Structure
//                        - FormDataStructure - :
//       * AllDocumentsFilterComposer - DataCompositionSettingsComposer
//       * AllDocumentsComposerAddress - String
//       * FormStorageAddress - String
//
Procedure InteractiveExportChangeClearGeneralFilter(ExportAddition) Export
	
	If IsBlankString(ExportAddition.AllDocumentsComposerAddress) Then
		ExportAddition.AllDocumentsFilterComposer.Settings.Filter.Items.Clear();
	Else
		Data = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress); // DataCompositionSettingsComposer
		Data.Settings.Filter.Items.Clear();
		ExportAddition.AllDocumentsComposerAddress = PutToTempStorage(Data, ExportAddition.FormStorageAddress);
		
		Composer = New DataCompositionSettingsComposer;
		Composer.Initialize(New DataCompositionAvailableSettingsSource(Data.CompositionSchema));
		Composer.LoadSettings(Data.Settings);
		ExportAddition.AllDocumentsFilterComposer = Composer;
	EndIf;
	
EndProcedure

// Clearing detailed selection
//
// Parameters:
//     ExportAddition - Structure
//                        - РеквизитФормыКоллекция - 
//
Procedure InteractiveExportChangeDetailsClearing(ExportAddition) Export
	ExportAddition.AdditionalRegistration.Clear();
EndProcedure

// Defines a description of the General selection. Returns an empty string if the selection is empty.
//
// Parameters:
//     ExportAddition - Structure
//                        - РеквизитФормыКоллекция - 
//
// Returns:
//     String - 
//
Function InteractiveExportChangeGeneralFilterAdditionDetails(Val ExportAddition) Export
	
	ComposerData = GetFromTempStorage(ExportAddition.AllDocumentsComposerAddress);
	
	Source = New DataCompositionAvailableSettingsSource(ComposerData.CompositionSchema);
	Composer = New DataCompositionSettingsComposer;
	Composer.Initialize(Source);
	Composer.LoadSettings(ComposerData.Settings);
	
	Return ExportAdditionFilterPresentation(Undefined, Composer, "");
EndFunction

// Defines a description of the detailed selection. Returns an empty string if the selection is empty.
//
// Parameters:
//     ExportAddition - Structure
//                        - РеквизитФормыКоллекция - 
//
// Returns:
//     String - 
//
Function InteractiveExportChangeDetailedFilterDetails(Val ExportAddition) Export
	Return DetailedExportAdditionPresentation(ExportAddition.AdditionalRegistration, "");
EndFunction

// Analyzes the history of settings-selections saved by the user for the node.
//
// Parameters:
//     ExportAddition - Structure
//                        - РеквизитФормыКоллекция - 
//
// Returns:
//     Список значений, где представление - 
//
Function InteractiveExportChangeSettingsHistory(Val ExportAddition) Export
	AdditionDataProcessor = DataProcessors.InteractiveExportChange.Create();
	
	OptionFilter = InteractiveExportChangeOptionFilter(ExportAddition);
	
	Return AdditionDataProcessor.ReadSettingsListPresentations(ExportAddition.InfobaseNode, OptionFilter);
EndFunction

// Restores the settings in the add-on details of the Upload by the name of the saved setting.
//
// Parameters:
//     ExportAddition     - Structure
//                            - РеквизитФормыКоллекция - 
//     SettingPresentation - String                            -  name of the setting to restore.
//
// Returns:
//     Boolean - 
//
Function InteractiveExportChangeRestoreSettings(ExportAddition, Val SettingPresentation) Export
	
	AdditionDataProcessor = DataProcessors.InteractiveExportChange.Create();
	FillPropertyValues(AdditionDataProcessor, ExportAddition);
	
	OptionFilter = InteractiveExportChangeOptionFilter(ExportAddition);
	
	// 
	Result = AdditionDataProcessor.RestoreCurrentAttributesFromSettings(SettingPresentation, OptionFilter, ExportAddition.FormStorageAddress);
	
	If Result Then
		FillPropertyValues(ExportAddition, AdditionDataProcessor, "ExportOption, AllDocumentsFilterPeriod, AllDocumentsFilterComposer");
		
		// 
		Data = AdditionDataProcessor.CommonFilterSettingsComposer();
		Data.Settings = ExportAddition.AllDocumentsFilterComposer.Settings;
		ExportAddition.AllDocumentsComposerAddress = PutToTempStorage(Data, ExportAddition.FormStorageAddress);
		
		FillValueTable(ExportAddition.AdditionalRegistration, AdditionDataProcessor.AdditionalRegistration);
		
		// 
		If AdditionDataProcessor.AdditionalNodeScenarioRegistration.Count() > 0 Then
			FillPropertyValues(ExportAddition, AdditionDataProcessor, "NodeScenarioFilterPeriod, NodeScenarioFilterPresentation");
			FillValueTable(ExportAddition.AdditionalNodeScenarioRegistration, AdditionDataProcessor.AdditionalNodeScenarioRegistration);
			// 
			InteractiveExportChangeSetNodeScenarioPeriod(ExportAddition);
		EndIf;
		
		// 
		ExportAddition.CurrentSettingsItemPresentation = SettingPresentation;
	EndIf;

	Return Result;
EndFunction

// Fills in the form details according to the settings structure.
//
// Parameters:
//     Form                       - ClientApplicationForm -  a form for setting up props.
//     ExportAdditionSettings - See InteractiveExportChange
//     AdditionAttributeName      - String -  name of the form details to create or fill out.
//
Procedure InteractiveExportChangeAttributeBySettings(Form, Val ExportAdditionSettings, Val AdditionAttributeName="ExportAddition") Export
	
	SetPrivilegedMode(True);
	
	AdditionScenarioParameters = ExportAdditionSettings.AdditionScenarioParameters;
	
	// 
	AdditionAttribute = Undefined;
	AttributesCollection = Form.GetAttributes(); // Array of FormAttribute
	For Each Attribute In AttributesCollection Do
		If Attribute.Name = AdditionAttributeName Then
			AdditionAttribute = Attribute;
			Break;
		EndIf;
	EndDo;
	
	// 
	ItemsToAdd = New Array;
	If AdditionAttribute=Undefined Then
		AdditionAttribute = New FormAttribute(AdditionAttributeName, 
			New TypeDescription("DataProcessorObject.InteractiveExportChange"));
			
		ItemsToAdd.Add(AdditionAttribute);
		Form.ChangeAttributes(ItemsToAdd);
	EndIf;
	
	// 
	TableAttributePath = AdditionAttribute.Name + ".AdditionalRegistration";
	If Form.GetAttributes(TableAttributePath).Count()=0 Then
		ItemsToAdd.Clear();
		Columns = ExportAdditionSettings.AdditionalRegistration.Columns;
		For Each Column In Columns Do
			ItemsToAdd.Add(New FormAttribute(Column.Name, Column.ValueType, TableAttributePath));
		EndDo;
		Form.ChangeAttributes(ItemsToAdd);
	EndIf;
	
	// 
	TableAttributePath = AdditionAttribute.Name + ".AdditionalNodeScenarioRegistration";
	If Form.GetAttributes(TableAttributePath).Count() = 0 Then
		ItemsToAdd.Clear();
		
		Columns = AdditionScenarioParameters.AdditionalOption.Filter.Columns;
		
		For Each Column In Columns Do
			ItemsToAdd.Add(New FormAttribute(Column.Name, Column.ValueType, TableAttributePath));
		EndDo;
		Form.ChangeAttributes(ItemsToAdd);
	EndIf;
	
	// 
	AttributeValue = Form[AdditionAttributeName];
	
	// 
	ValueToFormData(AdditionScenarioParameters.AdditionalOption.Filter,
		AttributeValue.AdditionalNodeScenarioRegistration);
	
	AdditionScenarioParameters.AdditionalOption.Filter = TableIntoStructuresArray(
		AdditionScenarioParameters.AdditionalOption.Filter);
	
	AttributeValue.AdditionScenarioParameters = AdditionScenarioParameters;
	
	AttributeValue.InfobaseNode = ExportAdditionSettings.InfobaseNode;

	AttributeValue.ExportOption                 = ExportAdditionSettings.ExportOption;
	AttributeValue.AllDocumentsFilterPeriod      = ExportAdditionSettings.AllDocumentsFilterPeriod;
	
	Data = GetFromTempStorage(ExportAdditionSettings.AllDocumentsComposerAddress);
	DeleteFromTempStorage(ExportAdditionSettings.AllDocumentsComposerAddress);
	AttributeValue.AllDocumentsComposerAddress = PutToTempStorage(Data, Form.UUID);
	
	AttributeValue.NodeScenarioFilterPeriod = AdditionScenarioParameters.AdditionalOption.FilterPeriod1;
	
	If AdditionScenarioParameters.AdditionalOption.Use Then
		AttributeValue.NodeScenarioFilterPresentation = ExportAdditionPresentationByNodeScenario(AttributeValue);
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

// Returns a description of the upload by settings.
//
// Parameters:
//     ExportAddition - Structure
//                        - FormDataCollection - :
//       * InfobaseNode - ExchangePlanRef -  the site plan of exchange.
//
// Returns:
//     String - 
// 
Function ExportAdditionPresentationByNodeScenario(Val ExportAddition)
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExportAddition.InfobaseNode);
	
	If Not HasExchangePlanManagerAlgorithm("InteractiveExportFilterPresentation", ExchangePlanName) Then
		Return "";
	EndIf;
	ManagerModule = ExchangePlans[ExchangePlanName];
	
	Parameters = New Structure;
	Parameters.Insert("UseFilterPeriod", ExportAddition.AdditionScenarioParameters.AdditionalOption.UseFilterPeriod);
	Parameters.Insert("FilterPeriod1",             ExportAddition.NodeScenarioFilterPeriod);
	Parameters.Insert("Filter",                    ExportAddition.AdditionalNodeScenarioRegistration);
	
	Return ManagerModule.InteractiveExportFilterPresentation(ExportAddition.InfobaseNode, Parameters);
EndFunction

// Returns a description of the period and selection as a string.
//
//  Parameters:
//      Period:                period for describing the selection.
//      Selection:                 selecting the data layout for the description.
//      Empty selection descriptor: the value returned if the selection is empty.
//
//  Returns:
//      String - 
//
Function ExportAdditionFilterPresentation(Val Period, Val Filter, Val EmptyFilterDetails=Undefined) Export
	
	OurFilter = ?(TypeOf(Filter)=Type("DataCompositionSettingsComposer"), Filter.Settings.Filter, Filter);
	
	PeriodAsString = ?(ValueIsFilled(Period), String(Period), "");
	FilterAsString  = String(OurFilter);
	
	If IsBlankString(FilterAsString) Then
		If EmptyFilterDetails=Undefined Then
			FilterAsString = NStr("en = 'All objects';");
		Else
			FilterAsString = EmptyFilterDetails;
		EndIf;
	EndIf;
	
	If Not IsBlankString(PeriodAsString) Then
		FilterAsString =  PeriodAsString + ", " + FilterAsString;
	EndIf;
	
	Return FilterAsString;
EndFunction

// Returns a description of the detailed selection for the "additional Registration"item.
//
//  Parameters:
//      AdditionalRegistration - ValueTable
//                                - Array - 
//      EmptyFilterDetails     - String                  -  the value returned if the selection is empty.
//
Function DetailedExportAdditionPresentation(Val AdditionalRegistration, Val EmptyFilterDetails=Undefined) Export
	
	Text = "";
	For Each String In AdditionalRegistration Do
		Text = Text + Chars.LF + String.Presentation + ": " + ExportAdditionFilterPresentation(String.Period, String.Filter);
	EndDo;
	
	If Not IsBlankString(Text) Then
		Return TrimAll(Text);
		
	ElsIf EmptyFilterDetails=Undefined Then
		Return NStr("en = 'No additional data is selected';");
		
	EndIf;
	
	Return EmptyFilterDetails;
EndFunction

// The identifier of the service object group metadata to All documents.
//
Function ExportAdditionAllDocumentsID() Export
	// 
	Return "AllDocuments";
EndFunction

// ID of the service group of metadata objects "All directories".
//
Function ExportAdditionAllCatalogsID() Export
	// 
	Return "AllCatalogs";
EndFunction

// Sets the total period for all selection sections.
//
// Parameters:
//     ExportAddition - Structure
//                        - FormDataCollection - 
//
Procedure InteractiveExportChangeSetNodeScenarioPeriod(ExportAddition) Export
	For Each String In ExportAddition.AdditionalNodeScenarioRegistration Do
		String.Period = ExportAddition.NodeScenarioFilterPeriod;
	EndDo;
	
	// 
	ExportAddition.NodeScenarioFilterPresentation = ExportAdditionPresentationByNodeScenario(ExportAddition);
EndProcedure

// Returns the selection options used based on the settings data.
//
// Parameters:
//     ExportAddition - Structure
//                        - FormDataCollection - 
//
// Returns:
//     Array of Number - : 
//               
//
Function InteractiveExportChangeOptionFilter(Val ExportAddition) Export
	
	Result = New Array;
	
	DataTest = New Structure("AdditionScenarioParameters");
	FillPropertyValues(DataTest, ExportAddition);
	AdditionScenarioParameters = DataTest.AdditionScenarioParameters;
	If TypeOf(AdditionScenarioParameters)<>Type("Structure") Then
		// 
		Return Undefined;
	EndIf;
	
	If AdditionScenarioParameters.Property("OptionDoNotAdd") 
		And AdditionScenarioParameters.OptionDoNotAdd.Use Then
		Result.Add(0);
	EndIf;
	
	If AdditionScenarioParameters.Property("AllDocumentsOption")
		And AdditionScenarioParameters.AllDocumentsOption.Use Then
		Result.Add(1);
	EndIf;
	
	If AdditionScenarioParameters.Property("ArbitraryFilterOption")
		And AdditionScenarioParameters.ArbitraryFilterOption.Use Then
		Result.Add(2);
	EndIf;
	
	If AdditionScenarioParameters.Property("AdditionalOption")
		And AdditionScenarioParameters.AdditionalOption.Use Then
		Result.Add(3);
	EndIf;
	
	If Result.Count() = 4 Then
		// 
		Return Undefined;
	EndIf;

	Return Result;
EndFunction

#EndRegion

#Region Other_Private

Procedure SetUpLoopFormElements(Form)
	
	If Not Users.IsFullUser() Then
		Return;
	EndIf;
	
	NodeRef1 = Form.Object.Ref;
	Items = Form.Items;
	
	If NodeRef1.IsEmpty() 
		Or Not DataExchangeCached.IsXDTOExchangePlan(NodeRef1) Then		
		
		CommonClientServer.SetFormItemProperty(
			Items,
			"FormCommonCommandObjectsUnregisteredWhileLooping",
			"Visible",
			False);
	
		Return;
		
	EndIf;
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"FormCommonCommandObjectsUnregisteredWhileLooping",
		"LocationInCommandBar",
		ButtonLocationInCommandBar.InAdditionalSubmenu);
	
	If Not DataExchangeLoopControl.IsNodeLooped(NodeRef1) Then
		Return;
	EndIf;
	
	PanelName = "Looping";
	
	Group = Items.Insert(PanelName, Type("FormGroup"), Undefined, Form.Items.FormCommandBar);
	Group.Type 			= FormGroupType.UsualGroup;
	Group.Group 	= ChildFormItemsGroup.AlwaysHorizontal;
	Group.BackColor 	= StyleColors.WarningBackColor;
	Group.ShowTitle = False;
	
	IndentDecoration = Items.Add("Indent" + PanelName, Type("FormDecoration"), Group);
	IndentDecoration.Type = FormDecorationType.Label;
	
	PictureDecoration = Items.Add("Picture" + PanelName, Type("FormDecoration"), Group);
	PictureDecoration.Type 		= FormDecorationType.Picture;
	PictureDecoration.Picture 	= PictureLib.Information;
	PictureDecoration.Height 	= 3;
	PictureDecoration.Width 	= 5;
	PictureDecoration.PictureSize = PictureSize.Proportionally;

	TextTemplate1 = NStr("en = '<br>Synchronization loop is found. For more information, follow the 
			  |<a href=""%1"">link</a>.
			  |<br><br>
			  |<a href=""%2"">Objects not registered upon looping</a>.';");
	WarningText = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, 
		"FormSynchronizationLoop", "FormObjectsUnregisteredWhileLooping" );

	FormattedDoc = New FormattedDocument;
	FormattedDoc.SetHTML("<html>" + WarningText + "</html>", New Structure);
	
	LabelDecoration = Items.Add("Label" + PanelName, Type("FormDecoration"), Group);
	LabelDecoration.Type 						= FormDecorationType.Label;
	LabelDecoration.AutoMaxWidth 	= False;
	LabelDecoration.HorizontalStretch 	= True;
	LabelDecoration.Title 					= FormattedDoc.GetFormattedString();
	LabelDecoration.SetAction("URLProcessing", "Attachable_URLProcessing");
	
EndProcedure

Procedure ClearErrorsListOnExportData(InfobaseNode) Export
	
	If Not ValueIsFilled(InfobaseNode) Then
		Return;
	EndIf;
	
	InformationRegisters.DataExchangeResults.ClearIssuesOnSend(InfobaseNode);
	
EndProcedure

Procedure ClearErrorsListOnDataImport(InfobaseNode) Export
	
	If Not ValueIsFilled(InfobaseNode) Then
		Return;
	EndIf;
	
	InformationRegisters.DataExchangeResults.ClearIssuesOnGet(InfobaseNode);
	
EndProcedure

Function TypesExcludedFromProblemResolutionCheck() Export
	
	Types = New Array;
	Types.Add(Metadata.Catalogs.DataExchangeScenarios);
	Types.Add(Metadata.Catalogs.DataExchangesSessions);
	
	DataExchangeOverridable.WhenFillingInTypesExcludedFromCheckProblemIsFixed(Types);
	
	Return Types;
	
EndFunction

#EndRegion

#EndRegion