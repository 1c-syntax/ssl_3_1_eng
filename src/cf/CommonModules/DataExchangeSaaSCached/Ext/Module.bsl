///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// Returns True if data synchronization is supported in the service model
//
Function DataSynchronizationSupported() Export
	
	Return DataSynchronizationExchangePlans().Count() > 0;
	
EndFunction

// Returns a collection of exchange plans used for syncing.
//
// The exchange plan for organizing data synchronization in the service model must:
// - be connected to the BSP data exchange subsystem,
// - be separated,
// - be a Non-rib exchange plan,
// - to be used for exchange in the service model (planobmain uses the service Model = True).
//
Function DataSynchronizationExchangePlans() Export
	
	Result = New Array;
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If Not ExchangePlan.DistributedInfoBase
			And DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name)
			And DataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlan.Name) Then
			
			Result.Add(ExchangePlan.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

#EndRegion

#Region Private

// Returns a reference to the Wsproxy object of the exchange service version 1.0.6.5.
//
// Returns:
//   WSProxy
//
Function GetExchangeServiceWSProxy() Export
	
	Result = Undefined;
	If Common.SubsystemExists("CloudTechnology") Then
		ModuleSaaSOperationsCTLCached = Common.CommonModule("SaaSOperationsCTLCached");
		ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
		
		TransportSettings = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(
			ModuleSaaSOperationsCTLCached.ServiceManagerEndpoint());
		
		SettingsStructure_ = New Structure;
		SettingsStructure_.Insert("WSWebServiceURL",   TransportSettings.WSWebServiceURL);
		SettingsStructure_.Insert("WSUserName", TransportSettings.WSUserName);
		SettingsStructure_.Insert("WSPassword",          TransportSettings.WSPassword);
		SettingsStructure_.Insert("WSServiceName",      "ManageApplicationExchange_1_0_6_5");
		SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/ManageApplicationExchange_1_0_6_5");
		SettingsStructure_.Insert("WSTimeout", 20);
		
		Result = DataExchangeWebService.GetWSProxyByConnectionParameters(SettingsStructure_);
	EndIf;
	
	If Result = Undefined Then
		Raise NStr("en = 'An error occurred when getting the data exchange web service from the managing application.';");
	EndIf;
	
	Return Result;
EndFunction

// Returns a reference to the Wsproxy object of the correspondent identified by the exchange plan node.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef
//   ErrorMessageString - String -  text of the error message.
//
// Returns:
//   WSProxy
//
Function GetWSProxyOfCorrespondent(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure_ = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure_.Insert("WSServiceName", "RemoteAdministrationOfExchange");
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange");
	SettingsStructure_.Insert("WSTimeout", 20);
	
	Return DataExchangeWebService.GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString);
	
EndFunction

// Returns a reference to The wsproxy object of version 2.0.1.6 of the correspondent identified by the exchange plan node.
//
// Parameters:
//   InfobaseNode - ExchangePlanRef
//   ErrorMessageString - String -  text of the error message.
//
// Returns:
//   WSProxy
//
Function GetWSProxyOfCorrespondent_2_0_1_6(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure_ = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure_.Insert("WSServiceName", "RemoteAdministrationOfExchange_2_0_1_6");
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange_2_0_1_6");
	SettingsStructure_.Insert("WSTimeout", 20);
	
	Return DataExchangeServer.GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString);
EndFunction

// Returns a reference to The wsproxy object of version 2.1.6.1 of the correspondent identified by the exchange plan node.
//
Function GetWSProxyOfCorrespondent_2_1_6_1(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure_ = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure_.Insert("WSServiceName", "RemoteAdministrationOfExchange_2_1_6_1");
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange_2_1_6_1");
	SettingsStructure_.Insert("WSTimeout", 20);
	
	Return DataExchangeServer.GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString);
EndFunction

// Returns a reference to The wsproxy object of version 2.4.5.1 of the correspondent identified by the exchange plan node.
//
Function GetWSProxyOfCorrespondent_2_4_5_1(InfobaseNode, ErrorMessageString = "") Export
	
	SettingsStructure_ = InformationRegisters.DataAreaExchangeTransportSettings.TransportSettingsWS(InfobaseNode);
	SettingsStructure_.Insert("WSServiceName", "RemoteAdministrationOfExchange_2_4_5_1");
	SettingsStructure_.Insert("WSServiceNamespaceURL", "http://www.1c.ru/SaaS/1.0/WS/RemoteAdministrationOfExchange_2_4_5_1");
	SettingsStructure_.Insert("WSTimeout", 20);
	
	Return DataExchangeServer.GetWSProxyByConnectionParameters(SettingsStructure_, ErrorMessageString);
EndFunction

// Returns True if this exchange plan is used for data synchronization in the service model.
//
Function IsDataSynchronizationExchangePlan(Val ExchangePlanName) Export
	
	Return DataSynchronizationExchangePlans().Find(ExchangePlanName) <> Undefined;
	
EndFunction

#EndRegion
