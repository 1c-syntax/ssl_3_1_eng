///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function SubscriptionsCTL() Export
	
	Subscriptions = SSLSubsystemsIntegrationClient.SSLEvents();
	If CommonClient.SubsystemExists("CloudTechnology.Core") Then
		ModuleCTLSubsystemsIntegrationClient = CommonClient.CommonModule("CTLSubsystemsIntegrationClient");
		ModuleCTLSubsystemsIntegrationClient.OnDefineEventSubscriptionsSSL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

Function SubscriptionsOSL() Export
	
	Subscriptions = SSLSubsystemsIntegrationClient.SSLEvents();
	If CommonClient.SubsystemExists("OnlineUserSupport") Then
		ModuleOSLSubsystemsIntegrationClient = CommonClient.CommonModule("OSLSubsystemsIntegrationClient");
		ModuleOSLSubsystemsIntegrationClient.OnDefineEventSubscriptionsSSL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

Function EDLSubscriptions() Export
	
	Subscriptions = SSLSubsystemsIntegrationClient.SSLEvents();
		
	If CommonClient.SubsystemExists("ElectronicInteraction") Then
		If Not StandardSubsystemsClient.ClientRunParameters().HasModuleEDLSubsystemsIntegrationClient Then
			Return Subscriptions;
		EndIf;
		ModuleEDLSubsystemsIntegrationClient = CommonClient.CommonModule("EDLSubsystemsIntegrationClient");
		ModuleEDLSubsystemsIntegrationClient.OnDefineEventSubscriptionsSSL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

#EndRegion