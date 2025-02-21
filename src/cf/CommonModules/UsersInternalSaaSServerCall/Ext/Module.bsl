﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

// See UsersInternalSaaS.GetUserFormProcessing
Procedure GetUserFormProcessing(Source, FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing) Export
	
	UsersInternalSaaS.GetUserFormProcessing(
		Source,
		FormType,
		Parameters,
		SelectedForm,
		AdditionalInformation,
		StandardProcessing);
	
EndProcedure

Procedure WriteTheErrorToTheLog(ErrorText) Export
	
	WriteLogEvent(
		NStr("en = 'Runtime error';", Common.DefaultLanguageCode()),
		EventLogLevel.Error,,, ErrorText);
	
EndProcedure

#EndRegion