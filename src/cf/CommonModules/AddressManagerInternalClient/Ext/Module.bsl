///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

Function SubjectOfSupportRequest() Export
	
	Return NStr("en = 'Issue when filling address'");
	
EndFunction

Function TextOfSupportRequest(Val Address, Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	Template = NStr("en = 'Issue when filling address %1: %2.
		|
		|<Describe the issue and attach screenshots>'");
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(Template, Address, MainReason);
	
	Return Result;
	
EndFunction

#EndRegion
