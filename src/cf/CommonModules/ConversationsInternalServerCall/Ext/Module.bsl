///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

Function Connected2() Export
	
	Return ConversationsInternal.Connected2();
	
EndFunction

Procedure Unlock() Export 
	
	ConversationsInternal.Unlock();
	
EndProcedure

#EndRegion

#Region Private

Function AttachExternalDataProcessor(AddressInTempStorage) Export
	
	// ACC:552-выкл подключение выполняется при наличии права интерактивного открытия внешних отчетов и обработок.
	// ACC:556-выкл
	// ACC:553-выкл
	VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
	Return ExternalDataProcessors.Connect(AddressInTempStorage, , False);
	// ACC:553-вкл
	// ACC:556-вкл
	// ACC:552-вкл
	
EndFunction

Function ConnectExternalReport(AddressInTempStorage) Export
	
	// ACC:552-выкл подключение выполняется при наличии права интерактивного открытия внешних отчетов и обработок.
	// ACC:556-выкл
	// ACC:553-выкл
	VerifyAccessRights("InteractiveOpenExtDataProcessors", Metadata);
	Return ExternalReports.Connect(AddressInTempStorage, , False);
	// ACC:553-вкл
	// ACC:556-вкл
	// ACC:552-вкл
	
EndFunction

Function ItIsPossibleToOpenExternalReportsAndTreatments() Export

	Return AccessRight("InteractiveOpenExtDataProcessors", Metadata);

EndFunction

#EndRegion