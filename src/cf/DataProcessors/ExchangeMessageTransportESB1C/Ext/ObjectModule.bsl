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
		Result = SendMessage();
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
		
		Result = GetMessage();
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject, "DataImport");
		
		Result = False;
		
	EndTry;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.CorrespondentParameters
Function CorrespondentParameters(ConnectionSettings) Export
	
	Result = ExchangeMessagesTransport.StructureOfResultOfObtainingParametersOfCorrespondent();
	Result.ConnectionIsSet = True;
	Result.ConnectionAllowed = True;
	
	Return Result;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.BeforeExportData
Function BeforeExportData(MessageForDataMapping = False) Export
	
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.SaveSettingsInCorrespondent
Function SaveSettingsInCorrespondent(ConnectionSettings) Export
		
	Return True;
	
EndFunction

// See DataProcessorObject.ExchangeMessageTransportFILE.AuthenticationRequired
Function AuthenticationRequired() Export
	
	Return False;
	
EndFunction

#EndRegion

#Region Private

Function ConnectionIsSet() Export
	
	Try
		
		If IntegrationServices[IntegrationService].GetActive() Then
			Return True;
		Else
			ErrorMessage = NStr("en = 'Integration service is inactive.'",
				Common.DefaultLanguageCode());
			Return False;
		EndIf;
		
	Except
		
		ExchangeMessagesTransport.ErrorInformationInMessages(ThisObject, ErrorInfo());
		ExchangeMessagesTransport.WriteMessageToRegistrationLog(ThisObject);
		
		Return False;
	
	EndTry;
	
EndFunction

Function SendMessage()
	
	Stream = FileStreams.Open(ExchangeMessage, FileOpenMode.Open, FileAccess.Read);
	
	Message = IntegrationServices[IntegrationService].CreateMessage();
	Message.RecipientCode = RecipientCode;
	
	Body = Message.GetBodyAsStream();
	Stream.CopyTo(Body);
	Body.Flush();
	Body.Close();
	Stream.Close();
	
	IntegrationServices[IntegrationService][SendingChannel].SendMessage(Message);
	
	IntegrationServices.ExecuteProcessing();
	
	Return True;
	
EndFunction

Function GetMessage()
	
	FileNameInRepository = DataProcessors.ExchangeMessageTransportESB1C.FileName(RecipientCode);
	ExchangeMessage = DataExchangeServer.GetFileFromStorage(FileNameInRepository,,False);
	
	Return True;
	
EndFunction

#EndRegion

#Region Initialize

TempDirectory = Undefined;
ExchangeMessage = Undefined;

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf