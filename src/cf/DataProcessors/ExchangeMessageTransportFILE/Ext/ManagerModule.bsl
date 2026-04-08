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


// Transport parameters. Returns the transport parameters
// 
// Returns:
//  Structure - See ExchangeMessagesTransport.StructureOfTransportParameters 
//
Function TransportParameters() Export
	
	LongDesc = NStr("en = 'Connection requires a local or network directory.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("en = 'Local or network directory'");
	Parameters.TransportID = "FILE";
	Parameters.LongDesc = LongDesc;
	Parameters.AttributesForSecureStorage.Add("ArchivePasswordExchangeMessages");
	Parameters.Picture = PictureLib.Folder;
		
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsInXML_1_2(ConnectionSettings);
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return ExchangeMessagesTransport.ConnectionSettingsFromXML_1_2(XMLText, "FILE");
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
	
	JSONTransportSettings = New Structure;
		
	ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
	JSONTransportSettings.Insert("DataExchangeDirectory", TransportSettings.DataExchangeDirectory);
	JSONTransportSettings.Insert("CompressOutgoingMessageFile", TransportSettings.CompressOutgoingMessageFile);
	JSONTransportSettings.Insert("ArchivePasswordExchangeMessages", ArchivePasswordExchangeMessages);
	JSONTransportSettings.Insert("TransliterateExchangeMessageFileNames", TransportSettings.Transliteration);
		
	Return JSONTransportSettings;
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
	
	TransportSettings = New Structure;
	
	TransportSettings.Insert("DataExchangeDirectory", JSONTransportSettings.DataExchangeDirectory);
	TransportSettings.Insert("CompressOutgoingMessageFile", JSONTransportSettings.CompressOutgoingMessageFile);
	TransportSettings.Insert("ArchivePasswordExchangeMessages", JSONTransportSettings.ArchivePasswordExchangeMessages);
	TransportSettings.Insert("Transliteration", JSONTransportSettings.TransliterateExchangeMessageFileNames);
	
	Return TransportSettings;
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return ConnectionSettings.TransportSettings.DataExchangeDirectory;
	
EndFunction

#EndRegion
	
#EndIf