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

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If IsFolder Or Not ValueIsFilled(Parent) Then
		For Each AdditionalAttribute In AdditionalAttributes Do
			If AdditionalAttribute.PredefinedSetName <> PredefinedSetName Then
				AdditionalAttribute.PredefinedSetName = PredefinedSetName;
			EndIf;
		EndDo;
		
		For Each AdditionalInfoItem In AdditionalInfo Do
			If AdditionalInfoItem.PredefinedSetName <> PredefinedSetName Then
				AdditionalInfoItem.PredefinedSetName = PredefinedSetName;
			EndIf;
		EndDo;
	EndIf;
	
	If Not IsFolder Then
		// Deleting duplicates and empty rows.
		SelectedProperties = New Map;
		PropertiesToDelete = New Array;
		
		// Additional attributes.
		For Each AdditionalAttribute In AdditionalAttributes Do
			
			If AdditionalAttribute.Property.IsEmpty()
			 Or SelectedProperties.Get(AdditionalAttribute.Property) <> Undefined Then
				
				PropertiesToDelete.Add(AdditionalAttribute);
			Else
				SelectedProperties.Insert(AdditionalAttribute.Property, True);
			EndIf;
		EndDo;
		
		For Each PropertyToDelete In PropertiesToDelete Do
			AdditionalAttributes.Delete(PropertyToDelete);
		EndDo;
		
		SelectedProperties.Clear();
		PropertiesToDelete.Clear();
		
		// Additional information records.
		For Each AdditionalInfoItem In AdditionalInfo Do
			
			If AdditionalInfoItem.Property.IsEmpty()
			 Or SelectedProperties.Get(AdditionalInfoItem.Property) <> Undefined Then
				
				PropertiesToDelete.Add(AdditionalInfoItem);
			Else
				SelectedProperties.Insert(AdditionalInfoItem.Property, True);
			EndIf;
		EndDo;
		
		For Each PropertyToDelete In PropertiesToDelete Do
			AdditionalInfo.Delete(PropertyToDelete);
		EndDo;
		
		// Calculating the number of properties not marked for deletion.
		AttributesCount = Format(AdditionalAttributes.FindRows(
			New Structure("DeletionMark", False)).Count(), "NG=");
		
		InfoCount   = Format(AdditionalInfo.FindRows(
			New Structure("DeletionMark", False)).Count(), "NG=");
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
		// Updating the composition of the top group for use when configuring
		// the composition of dynamic list fields and its settings (selections,...).
		If ValueIsFilled(Parent) Then
			PropertyManagerInternal.CheckRefreshGroupPropertiesContent(Parent);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure OnReadPresentationsAtServer() Export
	
	If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
		ModuleNativeLanguagesSupportServer = Common.CommonModule("NationalLanguageSupportServer");
		ModuleNativeLanguagesSupportServer.OnReadPresentationsAtServer(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf