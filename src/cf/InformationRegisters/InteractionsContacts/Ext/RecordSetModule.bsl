﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Interactions.CalculateReviewedItems(AdditionalProperties) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	InteractionsContacts.Contact
	|FROM
	|	InformationRegister.InteractionsContacts AS InteractionsContacts
	|WHERE
	|	InteractionsContacts.Interaction = &Interaction";
	
	Query.SetParameter("Interaction", Filter.Interaction.Value);
	AdditionalProperties.Insert("RecordTable",  Query.Execute().Unload());
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not Interactions.CalculateReviewedItems(AdditionalProperties) Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	OldSet.Contact AS Contact
	|INTO OldSet
	|FROM
	|	&OldSet AS OldSet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InteractionsContacts.Contact AS Contact
	|INTO NewSet
	|FROM
	|	InformationRegister.InteractionsContacts AS InteractionsContacts
	|WHERE
	|	InteractionsContacts.Interaction = &Interaction
	|
	|INDEX BY
	|	Contact
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewSet.Contact AS CalculateBy
	|FROM
	|	NewSet AS NewSet
	|
	|UNION
	|
	|SELECT
	|	OldSet.Contact
	|FROM
	|	OldSet AS OldSet";
	
	Query.SetParameter("OldSet", AdditionalProperties.RecordTable);
	Query.SetParameter("Interaction", Filter.Interaction.Value);
	Interactions.CalculateReviewedByContacts(Query.Execute().Unload());
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf