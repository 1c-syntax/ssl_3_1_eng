///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal
Procedure AddRecord(TypeOfBackup, CreationDate, BackupFileName) Export

	Set = CreateRecordSet();
	Set.Filter.TypeOfBackup.Set(TypeOfBackup);
	Set.Filter.CreationDate.Set(CreationDate);

	Record = Set.Add();
	Record.TypeOfBackup		= TypeOfBackup;
	Record.CreationDate				= CreationDate;
	Record.BackupFileName	= BackupFileName;

	Set.Write();

EndProcedure
#EndRegion

#EndIf