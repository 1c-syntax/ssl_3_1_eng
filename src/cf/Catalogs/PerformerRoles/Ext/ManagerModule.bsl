﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	Result = New Array;
	
	Result.Add("BriefPresentation");
	Result.Add("Comment");
	Result.Add("ExternalRole");
	Result.Add("ExchangeNode");
	
	Return Result
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	StandardProcessing = False;
	
	If Users.IsExternalUserSession() Then
		CurrentUser = ExternalUsers.CurrentExternalUser();
		AttributeValue = Common.ObjectAttributeValue(CurrentUser, "AuthorizationObject");
		AuthorizationObject = ?(AttributeValue <> Undefined,
							  Catalogs[AttributeValue.Metadata().Name].EmptyRef(),
							  Catalogs.Users.EmptyRef());
	Else
		AuthorizationObject =   Catalogs.Users.EmptyRef();
	EndIf;
	
	TextFragmentsSearchForAdditionalLangs = New Array;
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		
		If ModuleNationalLanguageSupportServer.FirstAdditionalLanguageUsed() Then
			TextFragmentsSearchForAdditionalLangs.Add(
				"PerformerRoles.DescriptionLanguage1 LIKE &SearchString ESCAPE ""~""");
		EndIf;
		
		If ModuleNationalLanguageSupportServer.SecondAdditionalLanguageUsed() Then
			TextFragmentsSearchForAdditionalLangs.Add(
				"PerformerRoles.DescriptionLanguage2 LIKE &SearchString ESCAPE ""~""");
		EndIf;
		
	EndIf;
	
	QueryText = "SELECT ALLOWED TOP 20
		|	PerformerRoles.Ref AS Ref
		|FROM
		|	Catalog.PerformerRoles.Purpose AS ExecutorRolesAssignment
		|		LEFT JOIN Catalog.PerformerRoles AS PerformerRoles
		|		ON ExecutorRolesAssignment.Ref = PerformerRoles.Ref
		|WHERE
		|	ExecutorRolesAssignment.UsersType = &Type
		|	AND (PerformerRoles.Description LIKE &SearchString ESCAPE ""~"" 
		|			OR &SearchForAdditionalLanguages
		|			OR PerformerRoles.Code LIKE &SearchString ESCAPE ""~"")
		|	AND NOT PerformerRoles.Ref IS NULL";
	
	If TextFragmentsSearchForAdditionalLangs.Count() > 0 Then
		QueryText = StrReplace(QueryText, "&SearchForAdditionalLanguages", StrConcat(TextFragmentsSearchForAdditionalLangs, " OR "));
	Else
		QueryText = StrReplace(QueryText, "&SearchForAdditionalLanguages", "FALSE");
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Type",          AuthorizationObject);
	Query.SetParameter("SearchString", "%" + Common.GenerateSearchQueryString(Parameters.SearchString) + "%");
	QueryResult = Query.Execute().Select();
	
	ChoiceData = New ValueList;
	While QueryResult.Next() Do
		ChoiceData.Add(QueryResult.Ref, QueryResult.Ref);
	EndDo;
	
EndProcedure

#EndIf

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClientServer = Common.CommonModule("NationalLanguageSupportClientServer");
		ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	EndIf;
#Else
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClientServer = CommonClient.CommonModule("NationalLanguageSupportClientServer");
		ModuleNationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	EndIf;
#EndIf
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClientServer = Common.CommonModule("NationalLanguageSupportClientServer");
		ModuleNationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	EndIf;
	#Else
	If CommonClient.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportClientServer = CommonClient.CommonModule("NationalLanguageSupportClientServer");
		ModuleNationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	EndIf;
#EndIf
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// See also updating the information base undefined.customizingmachine infillingelements
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = True;
	
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
	Item.PredefinedDataName = "EmployeeResponsibleForTasksManagement";
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
			"en = 'Task control manager';", LanguagesCodes); // 
	Else
		Item.Description = NStr("en = 'Task control manager';", Common.DefaultLanguageCode());
	EndIf;
	
	Item.UsedWithoutAddressingObjects = True;
	Item.UsedByAddressingObjects  = True;
	Item.ExternalRole                      = False;
	Item.Code                              = "000000001";
	Item.BriefPresentation             = NStr("en = '000000001';", Common.DefaultLanguageCode());
	Item.MainAddressingObjectTypes = ChartsOfCharacteristicTypes.TaskAddressingObjects.AllAddressingObjects;
	
	Purpose = TabularSections.Purpose.Copy(); // ValueTable
	TSItem = Purpose.Add();
	TSItem.UsersType = Catalogs.Users.EmptyRef();
	Item.Purpose = Purpose;
	
	BusinessProcessesAndTasksOverridable.OnInitiallyFillPerformersRoles(LanguagesCodes, Items, TabularSections);
	
EndProcedure

// See also updating the information base undefined.customizingmachine infillingelements
//
// Parameters:
//  Object                  - CatalogObject.PerformerRoles -  the object to fill in.
//  Data                  - ValueTableRow -  data for filling in the object.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable -  the data filled in in the procedure for the initial filling of the elements.
//
Procedure OnInitialItemFilling(Object, Data, AdditionalParameters) Export
	
	BusinessProcessesAndTasksOverridable.AtInitialPerformerRoleFilling(Object, Data, AdditionalParameters);
	
EndProcedure

#EndRegion

#Region Private

// Registers for processing in the update handler
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	InfobaseUpdate.RegisterPredefinedItemsToUpdate(Parameters, Metadata.Catalogs.PerformerRoles);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	PopulationSettings = InfobaseUpdate.PopulationSettings();
	InfobaseUpdate.FillItemsWithInitialData(Parameters, Metadata.Catalogs.PerformerRoles, PopulationSettings);
	
EndProcedure

#EndRegion

#EndIf
