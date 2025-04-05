///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// See DataProcessorManager.ExchangeMessageTransportFILE.TransportParameters
Function TransportParameters() Export
	
	LongDesc = NStr("en = 'Для подключения необходимо параметры авторизации на облачном сервисе.'");
	
	Parameters = ExchangeMessagesTransport.StructureOfTransportParameters();
	
	Parameters.Alias = NStr("en = 'Яндекс.Диск'");
	Parameters.TransportID = "YandexDisk";
	Parameters.LongDesc = LongDesc;
	Parameters.Picture = PictureLib.YandexDisk;
	
	Attributes = New Array;
	Attributes.Add("ArchivePasswordExchangeMessages");
	
	Parameters.AttributesForSecureStorage = Attributes;
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionSettingsInXML(ConnectionSettings) Export
	
	Return "";
	
EndFunction

Function ConnectionSettingsFromXML(XMLText) Export
	
	Settings = New Structure;
	Return Settings;
	
EndFunction

Function TransportSettingsINJSON(TransportSettings) Export
		
	JSONTransportSettings = New Structure;
		
	ArchivePasswordExchangeMessages = Common.ReadDataFromSecureStorage(TransportSettings.ArchivePasswordExchangeMessages);
	
	JSONTransportSettings.Insert("CompressOutgoingMessageFile", TransportSettings.CompressOutgoingMessageFile);
	JSONTransportSettings.Insert("ArchivePasswordExchangeMessages", ArchivePasswordExchangeMessages);
	JSONTransportSettings.Insert("TransliterateExchangeMessageFileNames", TransportSettings.Transliteration);
	
	// Яндекс.Диск
	JSONTransportSettings.Insert("AccessToken", TransportSettings.AccessToken);
	JSONTransportSettings.Insert("ClientID", TransportSettings.ClientID);
	JSONTransportSettings.Insert("ClientSecret", TransportSettings.ClientSecret);
	JSONTransportSettings.Insert("ExpiresIn", TransportSettings.ExpiresIn);
	JSONTransportSettings.Insert("RefreshToken", TransportSettings.RefreshToken);
	JSONTransportSettings.Insert("CloudDirectory", TransportSettings.CloudDirectory);
	
	Return JSONTransportSettings;
	
EndFunction

Function TransportSettingsFromJSON(JSONTransportSettings) Export
	
	TransportSettings = New Structure;
	
	TransportSettings.Insert("CompressOutgoingMessageFile", JSONTransportSettings.CompressOutgoingMessageFile);
	TransportSettings.Insert("ArchivePasswordExchangeMessages", JSONTransportSettings.ArchivePasswordExchangeMessages);
	TransportSettings.Insert("Transliteration", JSONTransportSettings.TransliterateExchangeMessageFileNames);
	
	// Яндекс
	TransportSettings.Insert("AccessToken", JSONTransportSettings.AccessToken);
	TransportSettings.Insert("ClientID", JSONTransportSettings.ClientID);
	TransportSettings.Insert("ClientSecret", JSONTransportSettings.ClientSecret);
	TransportSettings.Insert("ExpiresIn", JSONTransportSettings.ExpiresIn);
	TransportSettings.Insert("RefreshToken", JSONTransportSettings.RefreshToken);
	TransportSettings.Insert("CloudDirectory", JSONTransportSettings.CloudDirectory);
		
	Return TransportSettings;
	
EndFunction

Function NameOfFolderWhereSettingsAreSaved(ConnectionSettings) Export
	
	Return "";
	
EndFunction

#EndRegion
	
#EndIf