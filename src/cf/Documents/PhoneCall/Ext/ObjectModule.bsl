///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// 

// The procedure generates rows in the list of participants.
//
// Parameters:
//  Contacts  - Array -  an array containing interaction participants.
//
Procedure FillContacts(Contacts) Export
	
	If Not Interactions.ContactsFilled(Contacts) Then
		Return;
	EndIf;
	
	// 
	Parameter = Contacts[0];
	If TypeOf(Parameter) = Type("Structure") Then
		SubscriberContact       = Parameter.Contact;
		HowToContactSubscriber  = Parameter.Address;
		SubscriberPresentation = Parameter.Presentation;
	Else
		SubscriberContact = Parameter;
	EndIf;
	
	Interactions.FinishFillingContactsFields(SubscriberContact, SubscriberPresentation, 
		HowToContactSubscriber, Enums.ContactInformationTypes.Phone);
	
EndProcedure

// End StandardSubsystems.Interactions

// 

// Parameters:
//   Table - See AccessManagement.AccessValuesSetsTable
//
Procedure FillAccessValuesSets(Table) Export
	
	InteractionsEvents.FillAccessValuesSets(ThisObject, Table);
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	Interactions.FillDefaultAttributes(ThisObject, FillingData);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	EmployeeResponsible    = Users.CurrentUser();
	Author            = Users.CurrentUser();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	Interactions.OnWriteDocument(ThisObject);
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf