///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Not MobileStandaloneServer Then

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
	
	Return Catalogs.MetadataObjectIDs.AttributesToEditInBatchProcessing();
	
EndFunction

// End StandardSubsystems.BatchEditObjects

// 

// Returns the directory details that form the natural key for the directory elements.
//
// Returns:
//  Array of String - 
//
Function NaturalKeyFields() Export
	
	Return Catalogs.MetadataObjectIDs.NaturalKeyFields();
	
EndFunction

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	Catalogs.MetadataObjectIDs.PresentationFieldsGetProcessing(Fields,
		StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	Catalogs.MetadataObjectIDs.PresentationGetProcessing(Data,
		Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Function DataTablesFullNames() Export
	
	Tables = New Array;
	
	If Not ValueIsFilled(SessionParameters.AttachedExtensions) Then
		Return Tables;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|WHERE
	|	IDsVersions.ExtensionsVersion = &ExtensionsVersion
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IDsVersions.FullObjectName AS FullObjectName
	|FROM
	|	InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|WHERE
	|	IDsVersions.ExtensionsVersion = &ExtensionsVersion
	|	AND IDsVersions.Id.NoData = FALSE";
	
	QueryResults = Query.ExecuteBatch();
	
	If QueryResults[0].IsEmpty() Then
		Catalogs.MetadataObjectIDs.IsDataUpdated(True, True);
		QueryResults = Query.ExecuteBatch();
	EndIf;
	
	Return QueryResults[1].Unload().UnloadColumn("FullObjectName");
	
EndFunction

#EndRegion

#Region Private

// This procedure updates the configuration metadata reference data.
//
// Parameters:
//  HasChanges  - Boolean -  the return value. This parameter returns
//                   the value True if a record was made, otherwise it does not change.
//
//  HasDeletedItems  - Boolean -  the return value. This parameter returns
//                   the value True if at least one element of the directory has been marked
//                   for deletion, otherwise it does not change.
//
//  IsCheckOnly - Boolean -  do not make any changes, but only check the
//                   check boxes there are Changes, there are Deleted.
//
Procedure UpdateCatalogData(HasChanges = False, HasDeletedItems = False, IsCheckOnly = False) Export
	
	Catalogs.MetadataObjectIDs.RunDataUpdate(HasChanges,
		HasDeletedItems, IsCheckOnly, , , True);
	
EndProcedure

// Returns True if the metadata object that corresponds
// to the extension object ID exists in the directory and
// is not marked for deletion, but is not in the extension metadata cache.
//
// Parameters:
//  Id - CatalogRef.ExtensionObjectIDs -  ID
//                    of the extension metadata object.
//
// Returns:
//  Boolean - 
//
Function ExtensionObjectDisabled(Id) Export
	
	StandardSubsystemsCached.MetadataObjectIDsUsageCheck(True, True);
	
	Query = New Query;
	Query.SetParameter("Ref", Id);
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	Catalog.ExtensionObjectIDs AS IDs
	|WHERE
	|	IDs.Ref = &Ref
	|	AND NOT IDs.DeletionMark
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|				WHERE
	|					IDsVersions.Id = IDs.Ref
	|					AND IDsVersions.ExtensionsVersion = &ExtensionsVersion)";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// For internal use only.
Function CurrentVersionExtensionObjectIDsFilled() Export
	
	Query = New Query;
	Query.SetParameter("ExtensionsVersion", SessionParameters.ExtensionsVersion);
	Query.Text =
	"SELECT TOP 1
	|	TRUE AS TrueValue
	|FROM
	|	InformationRegister.ExtensionVersionObjectIDs AS IDsVersions
	|WHERE
	|	IDsVersions.ExtensionsVersion = &ExtensionsVersion";
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#EndIf

#EndIf
