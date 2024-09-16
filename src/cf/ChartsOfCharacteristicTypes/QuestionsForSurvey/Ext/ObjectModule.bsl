///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

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

// The procedure clears the values of unnecessary details,
// This situation occurs when the user changes the response type during editing.
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
		ShouldShowRangeSlider = False;
		RangeSliderStep = 0;
		
	EndIf;
	
	If ReplyType = Enums.TypesOfAnswersToQuestion.MultipleOptionsFor Then
		CommentRequired = False;
		CommentNote = "";
	EndIf;
	
	If Not ShouldShowHintForNumericalQuestions Then
		NumericalQuestionHintsRange.Clear();
	EndIf;
	
EndProcedure

// Sets the type of the PVC value depending on the response type.
Procedure SetCCTType()
	
	If ReplyType = Enums.TypesOfAnswersToQuestion.String Or ReplyType = Enums.TypesOfAnswersToQuestion.Text Then
		ValueType = New TypeDescription("String", , New StringQualifiers(Length));
	ElsIf ReplyType = Enums.TypesOfAnswersToQuestion.Number Then
		ValueType = New TypeDescription("Number",, New NumberQualifiers(?(Length = 0, 15, Length), Accuracy));
	ElsIf ReplyType = Enums.TypesOfAnswersToQuestion.Date Then
		ValueType = New TypeDescription("Date", New DateQualifiers(DateFractions.Date));
	ElsIf ReplyType = Enums.TypesOfAnswersToQuestion.Boolean Then
		ValueType = New TypeDescription("Boolean");
	ElsIf ReplyType = Enums.TypesOfAnswersToQuestion.OneVariantOf
		  Or ReplyType = Enums.TypesOfAnswersToQuestion.MultipleOptionsFor Then
		ValueType =  New TypeDescription("CatalogRef.QuestionnaireAnswersOptions");
	EndIf;

EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf