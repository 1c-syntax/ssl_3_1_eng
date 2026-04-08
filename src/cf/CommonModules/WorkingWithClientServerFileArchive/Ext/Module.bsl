///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Checks whether storage volumes are used for the specified storage option.
//
// Parameters:
//  VerifiableWayToStoreFiles - String - Refer to Constant.FilesStorageMethod.
//
// Returns:
//  Boolean
//
Function StorageMethodUsesVolumes(VerifiableWayToStoreFiles) Export

	Return VerifiableWayToStoreFiles <> "InInfobase";

EndFunction

#EndRegion

#Region Private

// Toggles the visibility of controls PathGroup and BinaryDataStorageName on FileStorageVolumes catalog item form.
//
// Parameters:
//  Form							- ClientApplicationForm - Form the controls belong to.
//  VisibilityParametersOfAttributes	- Structure - See WorkingWithClientServerFileArchive.VisibilityParametersOfAttributesDependOnFileStorageMethod
//
Procedure UpdateVisibilityOfAttributesOfFileStorageVolume(Form, VisibilityParametersOfAttributes) Export

	Form.Items.PathGroup.Visible					= VisibilityParametersOfAttributes.VisibilityPathGroup;
	Form.Items.NameOfBinaryDataStore.Visible = VisibilityParametersOfAttributes.VisibilityNameOfBinaryDataStore;

EndProcedure

// Returns a collection of parameters that define the visibility of attributes on the item form of the FileStorageVolumes catalog.
//
// Returns:
//  Structure
//
Function VisibilityParametersOfAttributesDependOnFileStorageMethod() Export

	Result = New Structure;
	Result.Insert("VisibilityPathGroup"				, False);
	Result.Insert("VisibilityNameOfBinaryDataStore", False);

	Return Result;

EndFunction

#EndRegion