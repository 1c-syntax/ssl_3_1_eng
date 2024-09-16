///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	QueryText = 
	"SELECT
	|	CatalogMetadataObjectIDs.Ref AS Ref,
	|	CatalogMetadataObjectIDs.DeletionMark AS DeletionMark,
	|	CatalogMetadataObjectIDs.Parent AS Parent,
	|	CatalogMetadataObjectIDs.Description AS Description,
	|	CatalogMetadataObjectIDs.CollectionOrder AS CollectionOrder,
	|	CatalogMetadataObjectIDs.Name AS Name,
	|	CatalogMetadataObjectIDs.Synonym AS Synonym,
	|	CatalogMetadataObjectIDs.FullName AS FullName,
	|	CatalogMetadataObjectIDs.FullSynonym AS FullSynonym,
	|	CatalogMetadataObjectIDs.NoData AS NoData,
	|	CatalogMetadataObjectIDs.EmptyRefValue AS EmptyRefValue,
	|	CatalogMetadataObjectIDs.MetadataObjectKey AS MetadataObjectKey,
	|	CatalogMetadataObjectIDs.NewRef AS NewRef,
	|	CatalogMetadataObjectIDs.Predefined AS Predefined,
	|	CatalogMetadataObjectIDs.PredefinedDataName AS PredefinedDataName
	|FROM
	|	Catalog.MetadataObjectIDs AS CatalogMetadataObjectIDs
	|WHERE
	|	CatalogMetadataObjectIDs.FullName <> &MainMetadataObject
	|	OR &AllNames";
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "Catalog.MetadataObjectIDs";
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.IDsList, ListProperties);
	IDsList.Parameters.SetParameterValue("MainMetadataObject", Parameters.MainMetadataObject);
	IDsList.Parameters.SetParameterValue("AllNames", Not ValueIsFilled(Parameters.MainMetadataObject));
	
EndProcedure

#EndRegion