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

// Returns object details that can be edited
// by processing group changes to details.
//
// Returns:
//  Array of String
//
Function AttributesToEditInBatchProcessing() Export
	
	AttributesToEdit = New Array;
	AttributesToEdit.Add("LongDesc");
	AttributesToEdit.Add("EmployeeResponsible");
	AttributesToEdit.Add("CreationDate");
	
	Return AttributesToEdit;
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ObjectReadingAllowed(Ref)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ObjectUpdateAllowed(Ref)";
	
	Restriction.TextForExternalUsers1 = Restriction.Text;
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	If FormType = "ListForm" Then
		// 
		CurrentRow = CommonClientServer.StructureProperty(Parameters, "CurrentRow");
		// 
		If TypeOf(CurrentRow) = Type("CatalogRef.FilesFolders") And Not CurrentRow.IsEmpty() Then
			StandardProcessing = False;
			Parameters.Delete("CurrentRow");
			Parameters.Insert("Folder", CurrentRow);
			SelectedForm = "Catalog.Files.Form.Files";
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region Internal

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
	Item.PredefinedDataName = "Templates";
	Item.Description = NStr("en = 'File templates';", Common.DefaultLanguageCode());
	
EndProcedure

#EndRegion


#EndIf
