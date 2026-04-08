///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var ExchangeMessage Export; // For import, it is the name of the file stored in "TempDirectory". For export, the name of the file to be sent out
Var TempDirectory Export; // A temporary exchange directory.
Var DirectoryID Export;
Var Peer Export;
Var ExchangePlanName Export;
Var CorrespondentExchangePlanName Export;
Var ErrorMessage Export;
Var ErrorMessageEventLog Export;

Var NameTemplatesForReceivingMessage Export;
Var NameOfMessageToSend Export;

#EndRegion

#Region Public

// See DataProcessorObject.ExchangeMessageTransportFILE.SendData
Function SendData(MessageForDataMapping = False) Export
	
	Try
		Result = SendExchangeMessage(MessageForDataMapping);
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.GetData
Function GetData() Export

	Try
		Result = GetExchangeMessage();
	Except
		
		ErrorMessage = NStr("en = 'Errors occurred in the peer infobase during data export:'",
			Common.DefaultLanguageCode())  + Chars.LF;
		ErrorMessageEventLog = ErrorMessage;
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo(), True);
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.Insert("CorrespondentExchangePlanName", CorrespondentExchangePlanName);
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WSWebServiceURL", WebServiceAddress);
	ConnectionParameters.Insert("WSUserName", UserName);
	ConnectionParameters.Insert("WSPassword", Password);
	
	Try
		
		CorrespondentVersions = DataExchangeCached.CorrespondentVersions(ConnectionParameters);
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
				
		Return Result;
		
	EndTry;
		
	InterfaceVersion = DataExchangeWebService.MaximumGeneralVersionOfExchangeInterface(CorrespondentVersions);
	
	If Not StrFind("3.0.1.1, 3.0.2.1, 3.0.2.2", InterfaceVersion)  Then
			
		ErrorMessage = NStr("en = 'The peer infobase does not support version 3.0.1.x of the DataExchange interface.
								|To set up the connection, update the peer infobase configuration or start setting up from it.'");
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
			
		Return Result;
		
	EndIf;
		
	Proxy = Proxy();
	
	If Proxy = Undefined Then
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;

	AdditionalParameters = New Structure;
	If DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName) Then
		AdditionalParameters.Insert("IsXDTOExchangePlan", True);
		AdditionalParameters.Insert("SettingID", ConnectionSettings.SettingID);
	EndIf;
	
	ThisNodeCode = ExchangePlans[ExchangePlanName].ThisNode().Code;
	
	IBParameters = DataExchangeWebService.GetParametersOfInfobase(
		Proxy, CorrespondentExchangePlanName, ThisNodeCode, ErrorMessage, 0, AdditionalParameters);
	
	CorrespondentParameters = XDTOSerializer.ReadXDTO(IBParameters);
	
	If Not CorrespondentParameters.ExchangePlanExists Then
		
		Text = NStr("en = 'Exchange plan ""%1"" is not found in the peer application.
			|Ensure that the following data is correct:
			|- The application type selected in the exchange settings.
			|- The web application address.'");
		
		ErrorMessage = StrTemplate(Text, ExchangePlanName);
		
		Result.ConnectionIsSet = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	Result.CorrespondentParametersReceived = True;
	Result.CorrespondentParameters = CorrespondentParameters;
	Result.CorrespondentExchangePlanName = CorrespondentParameters.ExchangePlanName;
	Result.ConnectionIsSet = True;
	
	Cancel = False;
	ErrorMessage = "";
	
	ConfigurationVersion = Result.CorrespondentParameters.ConfigurationVersion;
	ExchangeMessagesTransport.OnConnectToCorrespondent(Cancel, ExchangePlanName, ConfigurationVersion, ErrorMessage);
	
	If Cancel Then
		
		Result.ConnectionAllowed = False;
		Result.ErrorMessage = ErrorMessage;
		
		Return Result;
		
	EndIf;
	
	ExchangeMessagesTransport.CheckForDuplicateSyncs(ExchangePlanName, CorrespondentParameters, Result);
	
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent 
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
	
	Proxy = Proxy();
	
	If Proxy = Undefined Then
		Return False;
	EndIf;
	
	CorrespondentConnectionSettings = New Structure;
	For Each SettingItem In ConnectionSettings Do
		CorrespondentConnectionSettings.Insert(SettingItem.Key);
	EndDo;
		
	CorrespondentConnectionSettings.WizardRunOption   = "ContinueDataExchangeSetup";
	CorrespondentConnectionSettings.ExchangeSetupOption = ConnectionSettings.ExchangeSetupOption;
	
	CorrespondentConnectionSettings.ExchangePlanName               = ConnectionSettings.CorrespondentExchangePlanName;
	CorrespondentConnectionSettings.CorrespondentExchangePlanName = ConnectionSettings.ExchangePlanName;
	CorrespondentConnectionSettings.ExchangeFormat                 = ConnectionSettings.ExchangeFormat;
	
	CorrespondentConnectionSettings.UsePrefixesForExchangeSettings =
		ConnectionSettings.UsePrefixesForCorrespondentExchangeSettings;
	
	CorrespondentConnectionSettings.UsePrefixesForCorrespondentExchangeSettings =
		ConnectionSettings.UsePrefixesForExchangeSettings;
	
	CorrespondentConnectionSettings.SourceInfobasePrefix = ConnectionSettings.DestinationInfobasePrefix;
	CorrespondentConnectionSettings.DestinationInfobasePrefix = ConnectionSettings.SourceInfobasePrefix;
	
	If DataExchangeCached.IsXDTOExchangePlan(ConnectionSettings.ExchangePlanName) Then
		CorrespondentConnectionSettings.ExchangeFormatVersion = ConnectionSettings.ExchangeFormatVersion;
		
		TableObjects = DataExchangeXDTOServer.SupportedObjectsInFormat(
			ConnectionSettings.ExchangePlanName, "SendReceive", ConnectionSettings.InfobaseNode);
		
		CorrespondentConnectionSettings.SupportedObjectsInFormat = New ValueStorage(TableObjects, New Deflation(9));
	EndIf;
	
	XMLConnectionSettingsString = DataProcessors.ExchangeMessageTransportWS.ConnectionSettingsInXML(ConnectionSettings);
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("ConnectionSettings", CorrespondentConnectionSettings);
	ConnectionParameters.Insert("XMLParametersString",  XMLConnectionSettingsString);
	
	Try
		DataExchangeWebService.CreateExchangeNode(Proxy, ConnectionParameters);
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
		
	EndTry;
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return Common.IsStandaloneWorkplace() Or Not RememberPassword;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.DeleteSynchronizationSettingInCorrespondent
Function DeleteSynchronizationSettingInCorrespondent() Export
	
	Proxy = Proxy();
	
	If Proxy = Undefined Then
		Return False;
	EndIf;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(Peer, "NodeDeletion");

	ExchangeSettingsStructure.EventLogMessageKey = DataExchangeServer.DataExchangeDeletionEventLogEvent();
	ExchangeSettingsStructure.ActionOnExchange = Undefined;
	
	Try
		DataExchangeWebService.DeleteExchangeNode(Proxy, ExchangeSettingsStructure);
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionIsSet() Export
 	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WSDLAddress", WebServiceAddress + "/ws/InterfaceVersion?wsdl");
	ConnectionParameters.Insert("NamespaceURI", "http://www.1c.ru/SaaS/1.0/WS");
	ConnectionParameters.Insert("ServiceName", "InterfaceVersion");
	ConnectionParameters.Insert("UserName", UserName);
	ConnectionParameters.Insert("Password", Password);
	ConnectionParameters.Insert("Timeout", 7);
	
	Try
		
		Proxy = Common.CreateWSProxy(ConnectionParameters);
		Proxy.GetVersions("DataExchange");
		Return True;
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
	
	EndTry;
	
EndFunction

Function SendExchangeMessage(MessageForDataMapping)
	
	Proxy = Proxy("DataExport");
	
	If Proxy = Undefined Then
		Return False;
	EndIf;
	
	Cancel = False;
	
	If Not ValueIsFilled(Peer) Then
		DataExchangeWebService.PutFileInStorageInService(Proxy, ExchangeMessage, 1024);
		Return True;
	EndIf;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		Peer, Enums.ActionsOnExchange.DataExport);
	
	SetupStatus = DataExchangeWebService.SetupStatus(Proxy, ExchangeSettingsStructure,,Cancel,ErrorMessage);
	
	If Cancel Then
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataExport");
		Return False;
	EndIf;
	
	UIDFileID = DataExchangeWebService.PutFileInStorageInService(Proxy, ExchangeMessage, 1024);
	
	FileIDAsString = String(UIDFileID);
	
	If MessageForDataMapping
		And (SetupStatus.DataMappingSupported
		Or Not SetupStatus.DataSynchronizationSetupCompleted) Then
		
		DataExchangeWebService.PutMessageForDataMapping(
			Proxy, ExchangeSettingsStructure, FileIDAsString);
		
	Else
		
		ExchangeParameters = DataExchangeServer.ExchangeParameters();
		
		DataExchangeWebService.RunDataImport(Proxy, ExchangeSettingsStructure, ExchangeParameters, FileIDAsString);
		
		If ExchangeParameters.TimeConsumingOperation Then
			
			DataExchangeWebService.WaitingForTheOperationToComplete(
				ExchangeSettingsStructure, ExchangeParameters, Proxy, Enums.ActionsOnExchange.DataExport);
			
		EndIf;
		
	EndIf;
		
	Return True;
	
EndFunction

Function GetExchangeMessage()
		
	Proxy = Proxy("DataImport");
	
	If Proxy = Undefined Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(Peer) Then
		ExchangeMessage = DataExchangeWebService.GetFileFromStorageInService(Proxy, NameTemplatesForReceivingMessage[0],,1024);
		Return True;
	EndIf;
	
	ExchangeParameters = DataExchangeServer.ExchangeParameters();
	ExchangeParameters.TimeConsumingOperationAllowed= True;
	ExchangeParameters.TheTimeoutOnTheServer = 15;
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		Peer, Enums.ActionsOnExchange.DataImport);
	
	DataExchangeWebService.RunDataExport(Proxy, ExchangeSettingsStructure, ExchangeParameters);
	
	If ExchangeParameters.TimeConsumingOperation Then
		
		DataExchangeWebService.WaitingForTheOperationToComplete(
			ExchangeSettingsStructure, ExchangeParameters, Proxy, Enums.ActionsOnExchange.DataImport);
		
	EndIf;
	
	UIDOfTheMessageFile = New UUID(ExchangeParameters.FileID);
	ExchangeMessage = DataExchangeWebService.GetFileFromStorageInService(
		Proxy, UIDOfTheMessageFile, Peer, 1024);
	
	Return True;
	
EndFunction

Function Proxy(ActionOnExchange = Undefined)
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("WebServiceAddress", WebServiceAddress);
	ConnectionParameters.Insert("UserName", UserName);
	ConnectionParameters.Insert("Password", Password);
	
	Proxy = DataExchangeWebService.WSProxy(ConnectionParameters, ErrorMessageEventLog, ErrorMessage);
	
	If Proxy = Undefined Then
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, ActionOnExchange);
	EndIf;
		
	Return Proxy;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
MessagesOfExchange = Undefined;

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf