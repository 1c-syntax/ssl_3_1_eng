///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Called from ExchangeMessagesTransport.AllTypesOfTransport.
// Returns all available transport types.
// 
// Parameters:
//  TypesOfTransport - Array of ОбработкаОбъект.ТранспортСообщенийОбмена*
//
Procedure WhenDeterminingTransportTypes(TypesOfTransport) Export

	//
	
EndProcedure

// Called in ExchangeMessagesTransport.AvailableTransportTypes.
// Specifies available transport types for an exchange plan node.
// 
// Parameters:
//  AvailableTransportTypes - Array of ОбработкаОбъект.ТранспортСообщенийОбмена*
//  Peer - ExchangePlanRef - Node whose available transport types are being defined
//  SettingsMode - String - Setting option
//
Procedure WhenDeterminingAvailableTransportTypes(AvailableTransportTypes, Peer, SettingsMode = "") Export

	//
	
EndProcedure

// Called in ExchangeWebServiceOperationData.AssembleFileFromParts, 
// when putting a file to the exchange message storage (DataExchangeMessages information register).
// 
// Parameters:
//  FileName - String
//  FileID - String 
//
Procedure OnPutFileToStorage(FileName, FileID) Export
	
	//
	
EndProcedure

// Called in ExchangeWebServiceOperationData.PrepareFileForReceipt,
// before getting a file from the exchange message storage (DataExchangeMessages information register).
// 
// Parameters:
//  FileID - String
//
Procedure BeforeRetrievingFileFromRepository(FileID) Export

	//
	
EndProcedure

#EndRegion
