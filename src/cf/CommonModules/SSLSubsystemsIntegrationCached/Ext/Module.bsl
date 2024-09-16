///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

Function SubscriptionsCTL() Export
	
	Subscriptions = SSLSubsystemsIntegration.SSLEvents();
	If Common.SubsystemExists("CloudTechnology") Then
		ModuleCTLSubsystemsIntegration = Common.CommonModule("CTLSubsystemsIntegration");
		ModuleCTLSubsystemsIntegration.OnDefineEventSubscriptionsSSL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

Function SubscriptionsOSL() Export
	
	Subscriptions = SSLSubsystemsIntegration.SSLEvents();
	If Common.SubsystemExists("OnlineUserSupport") Then
		ModuleOSLSubsystemsIntegration = Common.CommonModule("OSLSubsystemsIntegration");
		ModuleOSLSubsystemsIntegration.OnDefineEventSubscriptionsSSL(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

Function PELSubscriptions() Export
	
	Subscriptions = SSLSubsystemsIntegration.SSLEvents();
	
	If Not Common.SubsystemExists("EquipmentSupport") Then
		Return Subscriptions;
	EndIf;
	
	If Metadata.CommonModules.Find("PELSubsystemsIntegration") = Undefined Then
		Return Subscriptions;
	EndIf;
		
	ModulePELSubsystemsIntegration = Common.CommonModule("PELSubsystemsIntegration");
	ModulePELSubsystemsIntegration.OnDefineEventSubscriptionsSSL(Subscriptions);
	
	Return Subscriptions;
	
EndFunction

Function EDLSubscriptions() Export
	
	Subscriptions = SSLSubsystemsIntegration.SSLEvents();
	
	If Common.SubsystemExists("ElectronicInteraction") Then
		
		If Metadata.CommonModules.Find("EDLSubsystemsIntegration") = Undefined Then
			Return Subscriptions;
		EndIf;
		
		ModuleEDLSubsystemsIntegration = Common.CommonModule("EDLSubsystemsIntegration");
		ModuleEDLSubsystemsIntegration.OnDefineEventSubscriptionsSSL(Subscriptions);
		
	EndIf;
	
	Return Subscriptions;
	
EndFunction


#EndRegion