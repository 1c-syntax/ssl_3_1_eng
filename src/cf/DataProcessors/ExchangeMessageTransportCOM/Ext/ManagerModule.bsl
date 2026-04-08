///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// See DataProcessorManager.ExchangeMessageTransportFILE.TransportParameters
Function TransportParameters() Export
	
	LongDesc = NStr("en = 'This option is recommended if both applications are located
		|on the same computer or in the local network (in the same office).'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("en = 'Direct COM connection'");
	Parameters.TransportID = "COM";
	Parameters.LongDesc = LongDesc;
	Parameters.NameOfAuthenticationForm = "AuthenticationForm";
	Parameters.AttributesForSecureStorage.Add("UserPassword");
	Parameters.DirectConnection = True;
	Parameters.ApplicationOperationMode = 0;
	Parameters.UseProgress = False;
	Parameters.SaveConnectionParametersToFile = False;
	Parameters.Picture = PictureLib.TransportCOM;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsInXML_1_2(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsFromXML_1_2(XMLText, "COM");
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
	
	Return "";
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
	
	Return "";
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf