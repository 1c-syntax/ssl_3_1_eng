﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function SubscriptionsCTL() Export
	
	Subscriptions = SSLSubsystemsIntegrationClient.SSLEvents();
	If CommonClient.SubsystemExists("CloudTechnology.Core") Then
		ModuleCTLSubsystemsIntegrationClient = CommonClient.CommonModule("CTLSubsystemsIntegrationClient");
		ModuleCTLSubsystemsIntegrationClient.WhenDefiningSubscriptionsToBSPEvents(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

Function SubscriptionsOSL() Export
	
	Subscriptions = SSLSubsystemsIntegrationClient.SSLEvents();
	If CommonClient.SubsystemExists("OnlineUserSupport") Then
		ModuleOSLSubsystemsIntegrationClient = CommonClient.CommonModule("OSLSubsystemsIntegrationClient");
		ModuleOSLSubsystemsIntegrationClient.WhenDefiningSubscriptionsToBSPEvents(Subscriptions);
	EndIf;
	
	Return Subscriptions;
	
EndFunction

#EndRegion