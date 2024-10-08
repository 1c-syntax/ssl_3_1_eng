﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ErrorMessageStringField; // String - 

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// 

// Performs actions when creating a new data exchange:
// - creates or updates nodes of the current exchange plan
// - loads conversion rules with data from the layout of the current exchange plan (if not rib)
// - loads data registration rules from the layout of the current exchange plan
// - loads the settings of the message exchange transport
// - sets the value of the prefix constant of the information database (if not specified)
// - registers all data on the current node of the exchange plan, taking into account the rules for registering objects.
//
// Parameters:
//  Cancel - Boolean -  failure flag; raised if errors occur during the procedure.
// 
Procedure ExecuteActionsToSetNewDataExchange(Cancel,
	NodeFiltersSetting,
	DefaultNodeValues,
	RecordDataForExport = True,
	UseTransportSettings = True)
	
	ThisNodeCode = ?(UsePrefixesForExchangeSettings,
					GetThisBaseNodeCode(SourceInfobasePrefix),
					GetThisBaseNodeCode(SourceInfobaseID));
	If WizardRunOption = "ContinueDataExchangeSetup" Then
		NewNodeCode = SecondInfobaseNewNodeCode;
	ElsIf UsePrefixesForExchangeSettings Then
		NewNodeCode = DataExchangeServer.ExchangePlanNodeCodeString(DestinationInfobasePrefix);
	Else
		NewNodeCode = DestinationInfobaseID;
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		// 
		CreateUpdateExchangePlanNodes(NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode);
		
		If UseTransportSettings Then
			
			// 
			UpdateExchangeMessagesTransportSettings();
			
		EndIf;
		
		// 
		If UsePrefixesForExchangeSettings
			And Not SourceInfobasePrefixIsSet Then
			
			UpdateInfobasePrefixConstantValue();
			
		EndIf;
		
		If IsDistributedInfobaseSetup
			And WizardRunOption = "ContinueDataExchangeSetup" Then
			
			Constants.SubordinateDIBNodeSetupCompleted.Set(True);
			Constants.UseDataSynchronization.Set(True);
			Constants.NotUseSeparationByDataAreas.Set(True);
			
			// 
			DataExchangeServer.UpdateDataExchangeRules();
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		InformAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
	// 
	DataExchangeInternal.CheckObjectsRegistrationMechanismCache();
	
	Try
		
		If RecordDataForExport
			And Not IsDistributedInfobaseSetup Then
			
			// 
			RecordChangesForExchange(Cancel);
			
		EndIf;
		
	Except
		InformAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Performs actions when creating a new data exchange over an external connection.
//
Procedure ExternalConnectionSetUpNewDataExchange(Cancel, 
									CorrespondentInfobaseNodeFilterSetup, 
									DefaultValuesForCorrespondentInfobaseNode, 
									InfobasePrefixSet, 
									InfobasePrefix) Export
	
	DataExchangeServer.CheckDataExchangeUsage();
	
	NodeFiltersSetting    = GetFilterSettingsValues(ValueFromStringInternal(CorrespondentInfobaseNodeFilterSetup));
	DefaultNodeValues = GetFilterSettingsValues(ValueFromStringInternal(DefaultValuesForCorrespondentInfobaseNode));
	
	ErrorMessageStringField = Undefined;
	WizardRunOption = "ContinueDataExchangeSetup";
	
	ThisNodeCode = GetThisBaseNodeCode(SourceInfobasePrefix);
	NewNodeCode = SecondInfobaseNewNodeCode;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		// 
		CreateUpdateExchangePlanNodes(NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode);
		
		// 
		UpdateCOMExchangeMessagesTransportSettings();
		
		// 
		If Not InfobasePrefixSet Then
			
			ValueBeforeUpdate = GetFunctionalOption("InfobasePrefix");
			
			If ValueBeforeUpdate <> InfobasePrefix Then
				
				DataExchangeServer.SetInfobasePrefix(TrimAll(InfobasePrefix));
				
			EndIf;
			
		EndIf;
		
		If Cancel Then
			Raise(NStr("en = 'Error creating data synchronization settings.';"));
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		InformAboutError(ErrorInfo(), Cancel);
	EndTry;
	
EndProcedure

// Performs actions when creating a new data exchange over an external connection.
//
Procedure ExternalConnectionSetUpNewDataExchange_2_0_1_6(Cancel, 
									CorrespondentInfobaseNodeFilterSetup, 
									DefaultValuesForCorrespondentInfobaseNode, 
									InfobasePrefixSet, 
									InfobasePrefix) Export
	
	NodeFiltersSetting    = GetFilterSettingsValues(Common.ValueFromXMLString(CorrespondentInfobaseNodeFilterSetup));
	DefaultNodeValues = GetFilterSettingsValues(Common.ValueFromXMLString(DefaultValuesForCorrespondentInfobaseNode));
	
	ErrorMessageStringField = Undefined;
	WizardRunOption = "ContinueDataExchangeSetup";
	
	ThisNodeCode = GetThisBaseNodeCode(SourceInfobasePrefix);
	NewNodeCode = SecondInfobaseNewNodeCode;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		
		DataExchangeServer.CheckDataExchangeUsage();
		
		// 
		CreateUpdateExchangePlanNodes(NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode);
		
		// 
		UpdateCOMExchangeMessagesTransportSettings();
		
		// 
		If Not InfobasePrefixSet Then
			
			ValueBeforeUpdate = GetFunctionalOption("InfobasePrefix");
			
			If ValueBeforeUpdate <> InfobasePrefix Then
				
				DataExchangeServer.SetInfobasePrefix(TrimAll(InfobasePrefix));
				
			EndIf;
			
		EndIf;
		
		If Cancel Then
			Raise(NStr("en = 'Error creating data synchronization settings.';"));
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		InformAboutError(ErrorInfo(), Cancel);
	EndTry;
	
EndProcedure

// Performs registration of changes on the site plan of exchange.
//
Procedure ExternalConnectionRecordChangesForExchange() Export
	
	// 
	RecordChangesForExchange(False);
	
EndProcedure

// Reads the exchange assistant settings from an XML string.
//
Procedure ExternalConnectionImportWizardParameters(Cancel, XMLLine) Export
	
	ImportWizardParameters(Cancel, XMLLine);
	
EndProcedure

// Updates the settings of the data exchange node over an external connection and sets the default values.
//
Procedure ExternalConnectionUpdateDataExchangeSettings(DefaultNodeValues) Export
	
	BeginTransaction();
	Try
		Block = New DataLock;
	    LockItem = Block.Add(Common.TableNameByRef(InfobaseNode));
	    LockItem.SetValue("Ref", InfobaseNode);
	    Block.Lock();
		
		// 
		LockDataForEdit(InfobaseNode);
		InfobaseNodeObject = InfobaseNode.GetObject();
		
		// 
		DataExchangeEvents.SetDefaultNodeValues(InfobaseNodeObject, DefaultNodeValues);
		
		InfobaseNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
		InfobaseNodeObject.Write();
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Performs actions when creating a new data exchange via a web service.
// For a detailed description, see the procedure to perform the actions to configure the Data exchange.
//
Procedure SetUpNewDataExchangeWebService(Cancel, NodeFiltersSetting, DefaultNodeValues) Export
	
	NodeFiltersSetting    = GetFilterSettingsValues(NodeFiltersSetting);
	DefaultNodeValues = GetFilterSettingsValues(DefaultNodeValues);
	If UsePrefixesForExchangeSettings Then
		SourceInfobasePrefixIsSet = ValueIsFilled(GetFunctionalOption("InfobasePrefix"));
	EndIf;

	// 
	If DataExchangeServer.HasExchangePlanManagerAlgorithm("OnGetSenderData",ExchangePlanName) Then
		Try
			ExchangePlans[ExchangePlanName].OnGetSenderData(NodeFiltersSetting, False);
		Except
			InformAboutError(ErrorInfo(), Cancel);
			Return;
		EndTry;
	EndIf;
	// 
	
	ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.WSPassiveMode;
	
	ExecuteActionsToSetNewDataExchange(Cancel,
													NodeFiltersSetting,
													DefaultNodeValues,
													False,
													True);
	
	If Cancel Then
		DeleteDataExchangeSettings();
	EndIf;
	
EndProcedure

Procedure DeleteDataExchangeSettings()
	
	ManagerExchangePlan = ExchangePlans[ExchangePlanName];
	Node_ToDelete = ManagerExchangePlan.FindByCode(SecondInfobaseNewNodeCode);
	
	If Not Node_ToDelete.IsEmpty() Then
		DataExchangeServer.DeleteSynchronizationSetting(Node_ToDelete);
	EndIf;
	
	
EndProcedure

// Uploads the assistant parameters to temporary storage to continue configuring the exchange in the second database.
//
// Parameters:
//  Cancel - Boolean -  failure flag; raised if errors occur during the procedure.
//  TempStorageAddress - String -  when the xml file with settings is successfully uploaded
//                                      , the address of the temporary storage
//                                      where the file data will be available on the server and on the client is written to this variable.
// 
Procedure ExportWizardParametersToTempStorage(Cancel, TempStorageAddress) Export
	
	SetPrivilegedMode(True);
	
	// 
	TempFileName = GetTempFileName("xml");
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	Try
		ModuleSetupWizard.ConnectionSettingsInXML(ThisObject, TempFileName);
	Except
		InformAboutError(ErrorInfo(), Cancel);
		FileSystem.DeleteTempFile(TempFileName);
		Return;
	EndTry;
	
	TempStorageAddress = PutToTempStorage(New BinaryData(TempFileName));
	
	FileSystem.DeleteTempFile(TempFileName);
	
EndProcedure

// Initializes the exchange node settings.
//
Procedure Initialize(Node) Export
	
	InfobaseNode = Node;
	InfobaseNodeParameters = Common.ObjectAttributesValues(Node, "Code, Description");
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	ThisInfobaseDescription = String(ExchangePlans[ExchangePlanName].ThisNode());
	SecondInfobaseDescription = InfobaseNodeParameters.Description;
	
	DestinationInfobasePrefix = InfobaseNodeParameters.Code;
	
	TransportSettings = InformationRegisters.DataExchangeTransportSettings.TransportSettings(Node);
	
	FillPropertyValues(ThisObject, TransportSettings);
	
	ExchangeMessagesTransportKind = TransportSettings.DefaultExchangeMessagesTransportKind;
	
	UseTransportParametersCOM = False;
	UseTransportParametersEMAIL = False;
	UseTransportParametersFILE = False;
	UseTransportParametersFTP = False;
	
	If ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FILE Then
		
		UseTransportParametersFILE = True;
		
	ElsIf ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.FTP Then
		
		UseTransportParametersFTP = True;
		
	ElsIf ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.EMAIL Then
		
		UseTransportParametersEMAIL = True;
		
	ElsIf ExchangeMessagesTransportKind = Enums.ExchangeMessagesTransportTypes.COM Then
		
		UseTransportParametersCOM = True;
		
	EndIf;
	
	UsePrefixesForExchangeSettings = Not (DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName)
		And DataExchangeXDTOServer.VersionWithDataExchangeIDSupported(ExchangePlans[ExchangePlanName].EmptyRef()));
		
	If UsePrefixesForExchangeSettings Then
		If Common.DataSeparationEnabled() Then
			SourceInfobasePrefix = DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
		Else
			SourceInfobasePrefix = GetFunctionalOption("InfobasePrefix");
		EndIf;
		SourceInfobasePrefixIsSet = ValueIsFilled(SourceInfobasePrefix);
	Else
		PredefinedNodeCode = DataExchangeServer.PredefinedExchangePlanNodeCode(ExchangePlanName);
		SourceInfobaseID = PredefinedNodeCode;
		DestinationInfobasePrefixSpecified = False;
		SourceInfobasePrefixIsSet = True;
	EndIf;
	
	If Not SourceInfobasePrefixIsSet
		And UsePrefixesForExchangeSettings Then
		DataExchangeOverridable.OnDetermineDefaultInfobasePrefix(SourceInfobasePrefix);
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

// Error message when exchanging data.
//
// Returns:
//  String - 
//
Function ErrorMessageString() Export
	
	If TypeOf(ErrorMessageStringField) <> Type("String") Then
		
		ErrorMessageStringField = "";
		
	EndIf;
	
	Return ErrorMessageStringField;
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// 

Procedure CreateUpdateExchangePlanNodes(NodeFiltersSetting, DefaultNodeValues, ThisNodeCode, NewNodeCode)
	
	ManagerExchangePlan = ExchangePlans[ExchangePlanName]; // ExchangePlanManager
	
	// 
	
	// 
	ThisNode = ManagerExchangePlan.ThisNode();
	
	ThisNodeCodeInDatabase = Common.ObjectAttributeValue(ThisNode, "Code");
	IsDIBExchangePlan  = DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName);
	
	If IsBlankString(Common.ObjectAttributeValue(ThisNode, "Code"))
		Or (IsDIBExchangePlan And ThisNodeCodeInDatabase <> ThisNodeCode)
		Or (UsePrefixesForExchangeSettings And ThisNodeCodeInDatabase <> ThisNodeCode) Then
		
		BeginTransaction();
		Try
		    Block = New DataLock;
		    LockItem = Block.Add(Common.TableNameByRef(ThisNode));
		    LockItem.SetValue("Ref", ThisNode);
		    Block.Lock();
		    
		    ThisNodeObject = ThisNode.GetObject();
			ThisNodeObject.Code = ThisNodeCode;
			ThisNodeObject.Description = ThisInfobaseDescription;
			ThisNodeObject.AdditionalProperties.Insert("GettingExchangeMessage");
			ThisNodeObject.Write();

		    CommitTransaction();
		Except
		    RollbackTransaction();
			Raise;
		EndTry;
		
	EndIf;
	
	// 
	CreateNewNode = False;
	If IsDistributedInfobaseSetup
		And WizardRunOption = "ContinueDataExchangeSetup" Then
		
		MasterNode = DataExchangeServer.MasterNode();
		
		If MasterNode = Undefined Then
			
			Raise NStr("en = 'The master node is not defined.
							|Probably this infobase is not a subordinate DIB node.';");
		EndIf;
		
		NewNode = MasterNode.GetObject();
		
	Else
		
		// 
		NewNode = ManagerExchangePlan.FindByCode(NewNodeCode);
		CreateNewNode = NewNode.IsEmpty();
		If CreateNewNode Then
			NewNode = ManagerExchangePlan.CreateNode();
			NewNode.Code = NewNodeCode;
		Else
			Raise NStr("en = 'The first infobase prefix is not unique.
				|A data synchronization for an infobase (application) with this prefix already exists.';");
		EndIf;
		
		NewNode.Description = SecondInfobaseDescription;
		
		If Common.HasObjectAttribute("SettingsMode", Metadata.ExchangePlans[ExchangePlanName]) Then
			NewNode.SettingsMode = ExchangeSetupOption;
		EndIf;
		
	EndIf;
	
	// 
	DataExchangeEvents.SetNodeFilterValues(NewNode, NodeFiltersSetting);
	
	// 
	DataExchangeEvents.SetDefaultNodeValues(NewNode, DefaultNodeValues);
	
	// 
	NewNode.SentNo = 0;
	NewNode.ReceivedNo     = 0;
	
	If Common.DataSeparationEnabled()
		And Common.SeparatedDataUsageAvailable()
		And DataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlanName) Then
		
		NewNode.RegisterChanges = True;
		
	EndIf;
	
	If ValueIsFilled(RefToNew) Then
		NewNode.SetNewObjectRef(RefToNew);
	EndIf;
	
	NewNode.DataExchange.Load = True;
	NewNode.Write();
	
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		
		DatabaseObjectsTable = DataExchangeXDTOServer.SupportedObjectsInFormat(ExchangePlanName,
			"SendReceive", NewNode.Ref);
		CorrespondentObjectsTable = DatabaseObjectsTable.CopyColumns();
		
		For Each BaseObjectsRow In DatabaseObjectsTable Do
			CorrespondentObjectsRow = CorrespondentObjectsTable.Add();
			FillPropertyValues(CorrespondentObjectsRow, BaseObjectsRow, "Version, Object");
			CorrespondentObjectsRow.Send  = BaseObjectsRow.Receive;
			CorrespondentObjectsRow.Receive = BaseObjectsRow.Send;
		EndDo;
		
		XDTOSettingManager = Common.CommonModule("InformationRegisters.XDTODataExchangeSettings");
		XDTOSettingManager.UpdateSettings2(
			NewNode.Ref, "SupportedObjects", DatabaseObjectsTable);
		XDTOSettingManager.UpdateCorrespondentSettings(
			NewNode.Ref, "SupportedObjects", CorrespondentObjectsTable);
		
		RecordStructure = New Structure;
		RecordStructure.Insert("InfobaseNode",       NewNode.Ref);
		RecordStructure.Insert("CorrespondentExchangePlanName", CorrespondentExchangePlanName);
		
		DataExchangeInternal.UpdateInformationRegisterRecord(RecordStructure, "XDTODataExchangeSettings");
	EndIf;
	
	// 
	InformationRegisters.CommonInfobasesNodesSettings.UpdatePrefixes(
		NewNode.Ref,
		?(UsePrefixesForExchangeSettings, SourceInfobasePrefix, ""),
		DestinationInfobasePrefix);
		
	If Not DataExchangeServer.SynchronizationSetupCompleted(NewNode.Ref) Then
		DataExchangeServer.CompleteDataSynchronizationSetup(NewNode.Ref);
	EndIf;
	
	InfobaseNode = NewNode.Ref;
	
	If CreateNewNode
		And Not Common.DataSeparationEnabled() Then
		DataExchangeServer.UpdateDataExchangeRules();
	EndIf;
	If ThisNodeCode <> ThisNodeCodeInDatabase 
		And (UsePrefixesForExchangeSettings
			Or UsePrefixesForCorrespondentExchangeSettings) Then
		// 
		StructureTemporaryCode = New Structure("Peer, NodeCode", InfobaseNode, ThisNodeCode);
		DataExchangeInternal.AddRecordToInformationRegister(StructureTemporaryCode, "PredefinedNodesAliases");
	EndIf;

EndProcedure

Procedure UpdateExchangeMessagesTransportSettings()
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Peer",                           InfobaseNode);
	RecordStructure.Insert("DefaultExchangeMessagesTransportKind", ExchangeMessagesTransportKind);
	
	RecordStructure.Insert("WSUseLargeVolumeDataTransfer", True);
	
	SupplementStructureWithAttributeValue(RecordStructure, "EMAILMaxMessageSize");
	SupplementStructureWithAttributeValue(RecordStructure, "EMAILCompressOutgoingMessageFile");
	SupplementStructureWithAttributeValue(RecordStructure, "EMAILAccount");
	SupplementStructureWithAttributeValue(RecordStructure, "EMAILTransliterateExchangeMessageFileNames");
	SupplementStructureWithAttributeValue(RecordStructure, "FILEDataExchangeDirectory");
	SupplementStructureWithAttributeValue(RecordStructure, "FILECompressOutgoingMessageFile");
	SupplementStructureWithAttributeValue(RecordStructure, "FILETransliterateExchangeMessageFileNames");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPCompressOutgoingMessageFile");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionMaxMessageSize");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPassword");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPassiveConnection");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionUser");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPort");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPConnectionPath");
	SupplementStructureWithAttributeValue(RecordStructure, "FTPTransliterateExchangeMessageFileNames");
	SupplementStructureWithAttributeValue(RecordStructure, "WSWebServiceURL");
	SupplementStructureWithAttributeValue(RecordStructure, "WSUserName");
	SupplementStructureWithAttributeValue(RecordStructure, "WSPassword");
	SupplementStructureWithAttributeValue(RecordStructure, "WSRememberPassword");
	SupplementStructureWithAttributeValue(RecordStructure, "ArchivePasswordExchangeMessages");
	
	// 
	InformationRegisters.DataExchangeTransportSettings.AddRecord(RecordStructure);
	
EndProcedure

Procedure UpdateCOMExchangeMessagesTransportSettings()
	
	RecordStructure = New Structure;
	RecordStructure.Insert("Peer",                           InfobaseNode);
	RecordStructure.Insert("DefaultExchangeMessagesTransportKind", Enums.ExchangeMessagesTransportTypes.COM);
	
	SupplementStructureWithAttributeValue(RecordStructure, "COMOperatingSystemAuthentication");
	SupplementStructureWithAttributeValue(RecordStructure, "COMInfobaseOperatingMode");
	SupplementStructureWithAttributeValue(RecordStructure, "COM1CEnterpriseServerSideInfobaseName");
	SupplementStructureWithAttributeValue(RecordStructure, "COMUserName");
	SupplementStructureWithAttributeValue(RecordStructure, "COM1CEnterpriseServerName");
	SupplementStructureWithAttributeValue(RecordStructure, "COMInfobaseDirectory");
	SupplementStructureWithAttributeValue(RecordStructure, "COMUserPassword");
	
	// 
	InformationRegisters.DataExchangeTransportSettings.AddRecord(RecordStructure);
	
EndProcedure

Procedure SupplementStructureWithAttributeValue(RecordStructure, AttributeName)
	
	RecordStructure.Insert(AttributeName, ThisObject[AttributeName]);
	
EndProcedure

Procedure UpdateInfobasePrefixConstantValue()
	ValueBeforeUpdate = GetFunctionalOption("InfobasePrefix");
	
	If IsBlankString(ValueBeforeUpdate)
		And ValueBeforeUpdate <> SourceInfobasePrefix Then
		
		DataExchangeServer.SetInfobasePrefix(TrimAll(SourceInfobasePrefix));
		
	EndIf;
	
EndProcedure

Procedure RecordChangesForExchange(Cancel)
	
	Try
		DataExchangeServer.RegisterDataForInitialExport(InfobaseNode);
	Except
		InformAboutError(ErrorInfo(), Cancel);
		Return;
	EndTry;
	
EndProcedure

Function GetThisBaseNodeCode(Val InfobasePrefixSpecifiedByUser)
	
	If WizardRunOption = "ContinueDataExchangeSetup" Then
		
		If ValueIsFilled(PredefinedNodeCode) Then
			Return PredefinedNodeCode;
		Else
			Return TrimAll(InfobasePrefixSpecifiedByUser);
		EndIf;
		
	EndIf;
	If UsePrefixesForExchangeSettings Then
		If ValueIsFilled(SourceInfobasePrefix) Then
			Result = SourceInfobasePrefix;
		Else
			If IsBlankString(Result) Then
				Result = InfobasePrefixSpecifiedByUser;
			
				If IsBlankString(Result) Then
					
					Return "000";
					
				EndIf;
			EndIf;
		EndIf;
		Return DataExchangeServer.ExchangePlanNodeCodeString(Result);
	Else
		If ValueIsFilled(SourceInfobaseID) Then 
			Return SourceInfobaseID;
		Else
			Return "";
		EndIf;
	EndIf;
EndFunction

// Reads the exchange assistant settings from an XML string.
//
Procedure ImportWizardParameters(Cancel, XMLLine) Export
	
	// 
	If Common.DataSeparationEnabled()
		And Not DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlanName) Then
		ErrorMessageStringField = NStr("en = 'Data synchronization with this application is not available in SaaS mode.';");
		DataExchangeServer.ReportError(ErrorMessageString(), Cancel);
		Return;
	EndIf;
	
	If IsBlankString(WizardRunOption) Then
		WizardRunOption = "ContinueDataExchangeSetup";
	EndIf;
	
	ModuleSetupWizard = DataExchangeServer.ModuleDataExchangeCreationWizard();
	Try
		ModuleSetupWizard.FillConnectionSettingsFromXMLString(ThisObject, XMLLine);
	Except
		InformAboutError(ErrorInfo(), Cancel);
	EndTry;
	
EndProcedure

Procedure InformAboutError(ErrorInfo, Cancel)
	
	ErrorMessageStringField = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	DataExchangeServer.ReportError(ErrorProcessing.BriefErrorDescription(ErrorInfo), Cancel);
	
	WriteLogEvent(DataExchangeServer.DataExchangeCreationEventLogEvent(), EventLogLevel.Error,,, ErrorMessageString());
	
EndProcedure

Function GetFilterSettingsValues(ExternalConnectionSettingsStructure)
	
	Return DataExchangeServer.GetFilterSettingsValues(ExternalConnectionSettingsStructure);
	
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf