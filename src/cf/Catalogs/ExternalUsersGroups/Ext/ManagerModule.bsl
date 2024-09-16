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

// Returns the details of an object that is not recommended to edit
// by processing a batch update of account details.
//
// Returns:
//  Array of String
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("AuthorizationObjectsType");
	NotAttributesToEdit.Add("AllAuthorizationObjects");
	
	Return NotAttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.TextForExternalUsers1 =
	"AllowReadUpdate
	|WHERE
	|	Ref = VALUE(Catalog.ExternalUsersGroups.AllExternalUsers)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// See also updating the information base undefined.customizingmachine infillingelements
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Item = Items.Add();
	Item.PredefinedDataName = "AllExternalUsers";
	Item.Description = NStr("en = 'All external users';", Common.DefaultLanguageCode());
	
	BlankRefs = UsersInternalCached.BlankRefsOfAuthorizationObjectTypes();
	For Each EmptyRef In BlankRefs Do
		AssignmentTable = TabularSections.Purpose; // ValueTable
		NewRow = AssignmentTable.Add();
		NewRow.UsersType = EmptyRef;
	EndDo;
	Item.Purpose = TabularSections.Purpose;
	
EndProcedure

// 
// 
//
// Returns:
//  String - 
//
Function AllExternalUsersGroupID() Export
	
	Return "dce2cab1-46b8-45b8-844b-d10b62597e14";
	
EndFunction

#EndRegion


#EndIf
