///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

Function DisabledCommands(Owner) Export
	
	ListOfDisabledItems = New Map;
	
	If Not Common.SeparatedDataUsageAvailable() Then 
		Return ListOfDisabledItems;
	EndIf;
	
	QueryText =
	"SELECT
	|	PrintCommandsSettings.UUID AS UUID
	|FROM
	|	InformationRegister.PrintCommandsSettings AS PrintCommandsSettings
	|WHERE
	|	PrintCommandsSettings.Owner = &Owner
	|	AND NOT PrintCommandsSettings.Visible";
	
	Query = New Query(QueryText);
	Query.SetParameter("Owner", Owner);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		ListOfDisabledItems.Insert(Selection.UUID, True);
	EndDo;
	
	Return ListOfDisabledItems;
	
EndFunction

#EndRegion

#EndIf
