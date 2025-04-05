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
	
	LongDesc = NStr("en = 'Connection required peer connection details.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("en = 'Internet (HTTP service)'");
	Parameters.TransportID = "HTTP";
	Parameters.LongDesc = LongDesc;
	Parameters.NameOfAuthenticationForm = "AuthenticationForm";
	Parameters.AttributesForSecureStorage.Add("Password");
	Parameters.DirectConnection = True;
	Parameters.ApplicationOperationMode = 1;
	Parameters.UseProgress = False;
	Parameters.SaveConnectionParametersToFile = False;
	Parameters.Picture = PictureLib.TransportHTTP;
		
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return "";
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Return "";
	
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