///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function SubjectOfSupportRequest(Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	LengthLimitation = 500;
	MainReason = Left(MainReason, LengthLimitation);
	
	Template = NStr("en = 'Настройка почтового ящика: %1'");
	Result = StringFunctionsClientServer.SubstituteParametersToString(Template, MainReason);
	
	Return Result;
	
EndFunction

Function TextOfSupportRequest(Val Email, Val TechnicalInformation) Export
	
	MainReason = StrReplace(TechnicalInformation, Chars.LF, " ");
	
	Template = NStr("en = 'Проблема при настройке почтового ящика %1: %2.
		|
		|<Опишите возникшую проблему и приложите скриншоты ошибки.>'");
	
	Result = StringFunctionsClientServer.SubstituteParametersToString(
		Template,
		Email,
		MainReason);
	
	Return Result;
	
EndFunction

#EndRegion
