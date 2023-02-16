///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventsHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array();
	
	If Not CommentRequired Then
		NotCheckedAttributeArray.Add("CommentNote");
	EndIf;
	
	If (ReplyType <> Enums.TypesOfAnswersToQuestion.String)
		And (ReplyType <> Enums.TypesOfAnswersToQuestion.Number) Then
		NotCheckedAttributeArray.Add("Length");
	EndIf;
	If ReplyType <> Enums.TypesOfAnswersToQuestion.InfobaseValue Then
		NotCheckedAttributeArray.Add("ValueType");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		ClearUnnecessaryAttributes();
		SetCCTType();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// The procedure clears values of unnecessary attributes.
// This situation occurs when the user changes the answer type upon editing.
//
Procedure ClearUnnecessaryAttributes()
	
	If ((ReplyType <> Enums.TypesOfAnswersToQuestion.Number) And (ReplyType <> Enums.TypesOfAnswersToQuestion.String)  And (ReplyType <> Enums.TypesOfAnswersToQuestion.Text))
	   And (Length <> 0)Then
		
		Length = 0;
		
	EndIf;
	
	If (ReplyType <> Enums.TypesOfAnswersToQuestion.Number) Then	
		
		MinValue       = 0;
		MaxValue      = 0;
		ShowAggregatedValuesInReports = False;
		
	EndIf;
	
	If ReplyType = Enums.TypesOfAnswersToQuestion.MultipleOptionsFor Then
		CommentRequired = False;
		CommentNote = "";
	EndIf;

EndProcedure

// Sets a CCT value type depending on the answer type.
Procedure SetCCTType()
	
	TypesOfAnswersToQuestion = Enums.TypesOfAnswersToQuestion;
	
	// Qualifiers.
	KCH = New NumberQualifiers(?(Length = 0,15,Length),Accuracy);
	SQ = New StringQualifiers(Length);
	DQ = New DateQualifiers(DateFractions.Date);
	
	// Type details.
	TypesDetailsNumber  = New TypeDescription("Number",,KCH);
	TypesDetailsString = New TypeDescription("String", , SQ);
	TypesDetailsDate   = New TypeDescription("Date",DQ , , );
	TypesDetailsBoolean = New TypeDescription("Boolean");
	AnswersOptionsTypesDetails     = New TypeDescription("CatalogRef.QuestionnaireAnswersOptions");
	
	If ReplyType = TypesOfAnswersToQuestion.String Then
		
		ValueType = TypesDetailsString;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Text Then
		
		ValueType = TypesDetailsString;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Number Then
		
		ValueType = TypesDetailsNumber;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Date Then
		
		ValueType = TypesDetailsDate;
		
	ElsIf ReplyType = TypesOfAnswersToQuestion.Boolean Then
		
		ValueType = TypesDetailsBoolean;
		
	ElsIf ReplyType =TypesOfAnswersToQuestion.OneVariantOf
		  Or ReplyType = TypesOfAnswersToQuestion.MultipleOptionsFor Then
		
		ValueType = AnswersOptionsTypesDetails;
		
	EndIf;

EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf