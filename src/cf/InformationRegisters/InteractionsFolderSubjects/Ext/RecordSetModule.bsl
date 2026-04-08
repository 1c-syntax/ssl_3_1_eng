///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	OldSet = Common.SetRecordsFromDatabase(ThisObject, Replacing, FieldsForAnalysis());
	
	AdditionalProperties.Insert("OldSet", OldSet);
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Interactions.CalculateReviewedItems(AdditionalProperties) Then
		Return;
	EndIf;
	
	OldSet = AdditionalProperties.OldSet;
	
	If Common.IsRecordSetDeletion(Replacing) Then
		NewSet = Unload(New Array, FieldsForAnalysis());
	Else
		NewSet = Unload(, FieldsForAnalysis());
	EndIf;
	
	OldRecord = RecordStructure(OldSet);
	NewRecord  = RecordStructure(NewSet);
	
	DataForCalculation = New Structure("NewRecord, OldRecord", NewRecord, OldRecord);
	
	If NewRecord.Reviewed <> OldRecord.Reviewed Then
		
		Interactions.CalculateReviewedByFolders(Interactions.TableOfDataForReviewedCalculation(DataForCalculation, "Folder"));
		Interactions.CalculateReviewedBySubjects(Interactions.TableOfDataForReviewedCalculation(DataForCalculation, "SubjectOf"));
		
		Return;
		
	EndIf;
	
	If NewRecord.Folder <> OldRecord.Folder Then
		
		Interactions.CalculateReviewedByFolders(Interactions.TableOfDataForReviewedCalculation(DataForCalculation, "Folder"));
		
		Return;
		
	EndIf;
	
	If NewRecord.SubjectOf <> OldRecord.SubjectOf Then
		
		Interactions.CalculateReviewedBySubjects(Interactions.TableOfDataForReviewedCalculation(DataForCalculation, "SubjectOf"));
		Return;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function FieldsForAnalysis()
	
	RegisterMetadata = Metadata();
	
	FieldsForAnalysis = New Array;
	FieldsForAnalysis.Add(RegisterMetadata.Resources.SubjectOf.Name);
	FieldsForAnalysis.Add(RegisterMetadata.Resources.EmailMessageFolder.Name);
	FieldsForAnalysis.Add(RegisterMetadata.Resources.Reviewed.Name);
	
	Return StrConcat(FieldsForAnalysis, ",");
	
EndFunction

Function RecordStructure(RecordSet)

	RecordStructure = New Structure;
	RecordStructure.Insert("SubjectOf",     Undefined);
	RecordStructure.Insert("Folder",       Catalogs.EmailMessageFolders.EmptyRef());
	RecordStructure.Insert("Reviewed", Undefined);
	
	If RecordSet.Count() = 0 Then
		Return RecordStructure;
	EndIf;
	
	SetRecord = RecordSet[0];
	
	RecordStructure.SubjectOf     = SetRecord.SubjectOf;
	RecordStructure.Folder       = SetRecord.EmailMessageFolder;
	RecordStructure.Reviewed = SetRecord.Reviewed;
	
	Return RecordStructure;
	
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.'");
#EndIf