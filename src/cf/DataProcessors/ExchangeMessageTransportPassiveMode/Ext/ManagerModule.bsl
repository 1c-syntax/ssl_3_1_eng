///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// See DataProcessorManager.ExchangeMessageTransportFILE.TransportParameters
Function TransportParameters() Export
	
	LongDesc = NStr("en = 'With the current connection settings, this application sends and receives data only upon request from the peer application.';");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("en = 'Passive mode';");
	Parameters.TransportID = "PassiveMode";
	Parameters.LongDesc = LongDesc;
	Parameters.StartDataExchangeFromCorrespondent = False;
	Parameters.UseProgress = False;
	Parameters.ApplicationOperationMode = 1;
	Parameters.DirectConnection = False;
	Parameters.PassiveMode = True;
	Parameters.Picture = PictureLib.TransportPassiveMode;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return DataExchangeXDTOServer.ConnectionSettingsInExchangeMessage(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return DataExchangeXDTOServer.ExchangeMessageInConnectionSettings(XMLText);
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
	
	Return New Structure;
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export

	Return New Structure;
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf