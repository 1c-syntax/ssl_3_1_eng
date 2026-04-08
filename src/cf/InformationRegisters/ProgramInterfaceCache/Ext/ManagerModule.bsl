///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// Retrieves cache version data from the ValueStorage resource of the ProgramInterfaceCache register.
//
// Parameters:
//   Id - String - cache record ID.
//   DataType     - EnumRef.APICacheDataTypes
//   ReceivingParameters - String - parameter array serialized to XML for passing into the cache update procedure.
//   UseObsoleteData - Boolean - a flag that shows whether the procedure must wait for cache
//      update before retrieving data if it is obsolete.
//      True - always use cache data, if any. False - wait
//      for the cache update if data is obsolete.
//   IsDefaultSecureConnection - Boolean, Undefined
//
// Returns:
//   FixedArray, BinaryData
//
Function VersionCacheData(Val Id, Val DataType, Val ReceivingParameters,
			Val UseObsoleteData = True, Val IsDefaultSecureConnection = Undefined) Export
	
	Selection = VersionCacheCurrentData(Id, DataType);
	
	UpdateRequired2 = False;
	IsUpdatedDataRequired = False;
	
	If Selection = Undefined Then
		UpdateRequired2 = True;
		IsUpdatedDataRequired = True;
		
	ElsIf Not InterfaceCacheCurrent(Selection.UpdateDate) Then
		UpdateRequired2 = True;
		IsUpdatedDataRequired = Not UseObsoleteData;
	EndIf;
	
	If Not UpdateRequired2 Then
		Return Selection.Data.Get();
	EndIf;
	
	UpdateInCurrentSession = IsUpdatedDataRequired
		Or Common.FileInfobase()
		Or ExclusiveMode()
		Or Common.DebugMode()
		Or CurrentRunMode() = Undefined
		Or IsDefaultSecureConnection = False;
	
	ParametersOfUpdate = New Structure;
	ParametersOfUpdate.Insert("Id", Id);
	ParametersOfUpdate.Insert("DataType", DataType);
	ParametersOfUpdate.Insert("ReceivingParameters", ReceivingParameters);
	
	If UpdateInCurrentSession Then
		UpdateVersionCacheData(ParametersOfUpdate, Selection);
	Else
		If ReceivingParameters.Count() > 4 And ReceivingParameters[4] <> Undefined Then
			ParametersOfUpdate.ReceivingParameters = New Array(New FixedArray(ReceivingParameters));
			ParametersOfUpdate.ReceivingParameters[4] = Null;
		EndIf;
		ProcedureName = "InformationRegisters.ProgramInterfaceCache.UpdateVersionCacheData";
		JobDescription = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Version cache update. Entry ID: %1. Data type: %2.'"),
			Id, DataType);
		
		JobsFilter = New Structure;
		JobsFilter.Insert("MethodName",    ProcedureName);
		JobsFilter.Insert("Description", JobDescription);
		JobsFilter.Insert("State",    BackgroundJobState.Active);
		
		If BackgroundJobs.GetBackgroundJobs(JobsFilter).Count() = 0 Then
			OperationParametersList = TimeConsumingOperations.BackgroundExecutionParameters(Undefined);
			OperationParametersList.BackgroundJobDescription = JobDescription;
			OperationParametersList.RunInBackground = True;
			OperationParametersList.WaitCompletion = 0;
			
			TimeConsumingOperations.ExecuteInBackground(
				"InformationRegisters.ProgramInterfaceCache.UpdateVersionCacheData",
				ParametersOfUpdate,
				OperationParametersList);
		EndIf;
	EndIf;
	
	Return Selection.Data.Get();
	
EndFunction

// Called from VersionCacheData and UpdateVersionCacheData.
Function VersionCacheCurrentData(Id, DataType)
	
	Query = New Query;
	Query.SetParameter("Id", Id);
	Query.SetParameter("DataType", DataType);
	
	Query.Text =
	"SELECT
	|	CacheTable.UpdateDate AS UpdateDate,
	|	CacheTable.Data AS Data,
	|	CacheTable.DataType AS DataType
	|FROM
	|	InformationRegister.ProgramInterfaceCache AS CacheTable
	|WHERE
	|	CacheTable.Id = &Id
	|	AND CacheTable.DataType = &DataType";
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		Return Selection;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Updates data in the version cache.
//
// Parameters:
//  ParametersOfUpdate - Structure:
//   * Id      - String - Cache record ID.
//   * DataType          - EnumRef.APICacheDataTypes - Type of data to update.
//   * ReceivingParameters - Array - Additional parameters for retrieving data into the cache.
//  StorageAddress        - String - Obsolete.
//                        - Undefined, QueryResultSelection - Return value.
//
Procedure UpdateVersionCacheData(ParametersOfUpdate, StorageAddress) Export
	
	SetPrivilegedMode(True);
	
	Id      = ParametersOfUpdate.Id;
	DataType          = ParametersOfUpdate.DataType;
	ReceivingParameters = ParametersOfUpdate.ReceivingParameters;
	
	If ReceivingParameters.Count() > 4 And ReceivingParameters[4] = Null Then
		ReceivingParameters[4] = CommonClientServer.NewSecureConnection();
	EndIf;
	
	If TypeOf(StorageAddress) = Type("String") Then
		Selection = VersionCacheCurrentData(Id, DataType);
		If Selection <> Undefined
		   And InterfaceCacheCurrent(Selection.UpdateDate) Then
			Return;
		EndIf;
	EndIf;
	
	RecordSet = CreateRecordSet();
	RecordSet.Filter.Id.Set(Id);
	RecordSet.Filter.DataType.Set(DataType);
	
	NewRecord = RecordSet.Add();
	NewRecord.Id = Id;
	NewRecord.DataType = DataType;
	NewRecord.UpdateDate = CurrentUniversalDate();
	
	RecordSet.AdditionalProperties.Insert("ReceivingParameters", ReceivingParameters);
	RecordSet.PrepareDataToRecord(NewRecord.Data);
	
	Block = New DataLock;
	LockItem = Block.Add("InformationRegister.ProgramInterfaceCache");
	LockItem.SetValue("Id", Id);
	LockItem.SetValue("DataType", DataType);
	
	BeginTransaction();
	Try
		Block.Lock();
		
		Selection = VersionCacheCurrentData(Id, DataType);
		
		If Selection = Undefined
		 Or Not InterfaceCacheCurrent(Selection.UpdateDate) Then
			
			RecordSet.Write();
			If TypeOf(StorageAddress) <> Type("String") Then
				StorageAddress = NewRecord;
			EndIf;
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

// Prepares the data for the interface cache.
//
// Parameters:
//  DataType          - EnumRef.APICacheDataTypes - type of data to update.
//  ReceivingParameters - Array - additional options of getting data to the cache.
//  
// Returns:
//  FixedArray, BinaryData
//
Function PrepareVersionCacheData(Val DataType, Val ReceivingParameters) Export
	
	If DataType = Enums.APICacheDataTypes.InterfaceVersions Then
		Data = GetInterfaceVersionsToCache(ReceivingParameters[0], ReceivingParameters[1]);
	ElsIf DataType = Enums.APICacheDataTypes.WebServiceDetails Then
		Data = GetWSDL(ReceivingParameters[0], ReceivingParameters[1], ReceivingParameters[2], ReceivingParameters[3], ReceivingParameters[4]);
	Else
		TextTemplate1 = NStr("en = 'Unknown version cache data type: %1.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, DataType);
		Raise(MessageText);
	EndIf;
	
	Return Data;
	
EndFunction

// Generates a version cache record ID based on a server address and a resource name.
//
// Parameters:
//  Address - String - server address.
//  Name   - String - resource name.
//
// Returns:
//  String - version cache record ID.
//
Function VersionCacheRecordID(Val Address, Val Name) Export
	
	Return Address + "|" + Name;
	
EndFunction

Function InnerWSProxy(Parameters) Export
	
	Protocol = "";
	Position = StrFind(Parameters.WSDLAddress, "://");
	If Position > 0 Then
		Protocol = Lower(Left(Parameters.WSDLAddress, Position - 1));
	EndIf;
		
	SecureConnection = Parameters.SecureConnection;
	IsDefaultSecureConnection = False;
	If (Protocol = "https" Or Protocol = "ftps") And SecureConnection = Undefined Then
		SecureConnection = CommonClientServer.NewSecureConnection();
		IsDefaultSecureConnection = True;
	EndIf;
	
	WSDefinitions = WSDefinitions(Parameters.WSDLAddress, Parameters.UserName, Parameters.Password,, 
		SecureConnection, IsDefaultSecureConnection);
	
	EndpointName = Parameters.EndpointName;
	If IsBlankString(EndpointName) Then
		EndpointName = Parameters.ServiceName + "Soap";
	EndIf;
	
	InternetProxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		InternetProxy = ModuleNetworkDownload.GetProxy(Parameters.WSDLAddress);
	EndIf;
	
	Location = Parameters.Location;
	If IsBlankString(Location) Then
		Location = Parameters.WSDLAddress;
		Position = StrFind(Location, "?");
		If Position > 0 Then
			Location = Left(Location, Position - 1);
		EndIf;
	EndIf;
	
	Proxy = New WSProxy(WSDefinitions, Parameters.NamespaceURI, Parameters.ServiceName, EndpointName,
		InternetProxy, Parameters.Timeout, SecureConnection, Location, Parameters.UseOSAuthentication);
	Proxy.User = Parameters.UserName;
	Proxy.Password       = Parameters.Password;
	
	Return Proxy;
EndFunction

Function InterfaceCacheCurrent(UpdateDate)
	
	If ValueIsFilled(UpdateDate) Then
		Return UpdateDate + 24 * 60 * 60 > CurrentUniversalDate(); // caching no more than for 24 hours.
	EndIf;
	
	Return False;
	
EndFunction

Function WSDefinitions(Val WSDLAddress, Val UserName, Val Password, Val Timeout = 10,
			Val SecureConnection = Undefined, IsDefaultSecureConnection = False)
	
	If Not Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		Try
			InternetProxy = Undefined; // By default.
			Definitions = New WSDefinitions(WSDLAddress, UserName, Password, InternetProxy, Timeout, SecureConnection);
		Except
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Failed to get WS definitions at
				           |%1.
				           |Reason:
				           |%2'"),
				WSDLAddress,
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
			If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
				ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
				DiagnosticsResult = ModuleNetworkDownload.ConnectionDiagnostics(WSDLAddress);
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = '%1
					           |Diagnostics result:
					           |%2'"),
					ErrorText,
					DiagnosticsResult.ErrorDescription);
			EndIf;
			
			Raise ErrorText;
		EndTry;
		Return Definitions;
	EndIf;
	
	ReceivingParameters = New Array;
	ReceivingParameters.Add(WSDLAddress);
	ReceivingParameters.Add(UserName);
	ReceivingParameters.Add(Password);
	ReceivingParameters.Add(Timeout);
	ReceivingParameters.Add(SecureConnection);

	WSDLData = VersionCacheData(
		WSDLAddress,
		Enums.APICacheDataTypes.WebServiceDetails, 
		ReceivingParameters,
		False,
		IsDefaultSecureConnection); // BinaryData
		
	WSDLFileName = GetTempFileName("wsdl");
	WSDLData.Write(WSDLFileName);
	
	InternetProxy = Undefined;
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		InternetProxy = ModuleNetworkDownload.GetProxy(WSDLAddress);
	EndIf;
	
	Try
		Definitions = New WSDefinitions(WSDLFileName, UserName, Password, InternetProxy, Timeout, SecureConnection);
	Except
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Failed to get WS definitions from cache.
			           |Reason:
			           |%1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Raise ErrorText;
	EndTry;
	
	Try
		DeleteFiles(WSDLFileName);
	Except
		WriteLogEvent(NStr("en = 'Getting WSDL'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Definitions;
EndFunction

// Returns:
//  FixedArray
//
Function GetInterfaceVersionsToCache(Val ConnectionParameters, Val InterfaceName)
	
	If Not ConnectionParameters.Property("URL") 
		Or Not ValueIsFilled(ConnectionParameters.URL) Then
		
		Raise(NStr("en = 'The service URL is not set.'"));
	EndIf;
	
	If ConnectionParameters.Property("UserName")
		And ValueIsFilled(ConnectionParameters.UserName) Then
		
		UserName = ConnectionParameters.UserName;
		
		If ConnectionParameters.Property("Password") Then
			UserPassword = ConnectionParameters.Password;
		Else
			UserPassword = Undefined;
		EndIf;
		
	Else
		UserName = Undefined;
		UserPassword = Undefined;
	EndIf;
	
	ServiceAddress = ConnectionParameters.URL + "/ws/InterfaceVersion?wsdl";
	
	IsPackageDeliveryCheckOnErrorEnabled = ConnectionParameters.IsPackageDeliveryCheckOnErrorEnabled;
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = ServiceAddress;
	ConnectionParameters.NamespaceURI = "http://www.1c.ru/SaaS/1.0/WS";
	ConnectionParameters.ServiceName = "InterfaceVersion";
	ConnectionParameters.UserName = UserName;
	ConnectionParameters.Password = UserPassword;
	ConnectionParameters.Timeout = 7;
	ConnectionParameters.IsPackageDeliveryCheckOnErrorEnabled = IsPackageDeliveryCheckOnErrorEnabled;
	
	VersioningProxy = Common.CreateWSProxy(ConnectionParameters);
	
	XDTOArray = VersioningProxy.GetVersions(InterfaceName);
	If XDTOArray = Undefined Then
		Return New FixedArray(New Array);
	Else	
		Serializer = New XDTOSerializer(VersioningProxy.XDTOFactory);
		Return New FixedArray(Serializer.ReadXDTO(XDTOArray));
	EndIf;
	
EndFunction

Function GetWSDL(Val Address, Val UserName, Val Password, Val Timeout, Val SecureConnection = Undefined)
	
	ReceivingParameters = New Structure;
	If Not IsBlankString(UserName) Then
		ReceivingParameters.Insert("User", UserName);
		ReceivingParameters.Insert("Password", Password);
	EndIf;
	ReceivingParameters.Insert("Timeout", Timeout);
	ReceivingParameters.Insert("SecureConnection", SecureConnection);
	
	If Common.SubsystemExists("StandardSubsystems.GetFilesFromInternet") Then
		ModuleNetworkDownload = Common.CommonModule("GetFilesFromInternet");
		FileDetails = ModuleNetworkDownload.DownloadFileAtServer(Address, ReceivingParameters);
	Else
		Raise(NStr("en = 'The ""Network download"" subsystem is unavailable.'"),
			ErrorCategory.ConfigurationError);
	EndIf;
	
	If Not FileDetails.Status Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get web service details file %1 due to:
				|%2'"),
			Address, FileDetails.ErrorMessage), ErrorCategory.NetworkError);
	EndIf;
	
	InternetProxy = ModuleNetworkDownload.GetProxy(Address);
	Try
		Definitions = New WSDefinitions(FileDetails.Path, UserName, Password, InternetProxy, Timeout, SecureConnection);
	Except
		DiagnosticsResult = ModuleNetworkDownload.ConnectionDiagnostics(Address);
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get web service details file %1 due to:
				|%2
				|
				|Diagnostics result:
			    |%3'"),
			Address,
			ErrorProcessing.BriefErrorDescription(ErrorInfo()),
			DiagnosticsResult.ErrorDescription);
			
		ErrorMessage = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = '%1
			           |
			           |Trace parameters:
			           |Secure connection: %2
			           |Timeout: %3'"),
			ErrorText,
			Format(SecureConnection, NStr("en = 'BF=No; BT=Yes'")),
			Format(Timeout, "NG=0"));
			
		WriteLogEvent(NStr("en = 'Getting WSDL'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorMessage);
		Raise(ErrorText, ErrorCategory.NetworkError);
	EndTry;
	
	If Definitions.Services.Count() = 0 Then
		Raise(StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'Cannot get the web service description file.
			           |Reason: the file does not contain web service descriptions.
			           |Probably the file address is incorrect:
			           |%1'"),
			Address),
			ErrorCategory.NetworkError);
	EndIf;
	Definitions = Undefined;
	
	FileData = New BinaryData(FileDetails.Path);
	
	Try
		DeleteFiles(FileDetails.Path);
	Except
		WriteLogEvent(NStr("en = 'Getting WSDL'", Common.DefaultLanguageCode()),
			EventLogLevel.Error, , , ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return FileData;
	
EndFunction

// See StandardSubsystemsServer.WhenDefiningMethodsThatAreAllowedToBeCalledAsArbitraryCode
Procedure WhenDefiningMethodsThatAreAllowedToBeCalledAsArbitraryCode(Methods) Export
	
	Methods.Insert("UpdateVersionCacheData", True);
	
EndProcedure

#EndRegion

#EndIf