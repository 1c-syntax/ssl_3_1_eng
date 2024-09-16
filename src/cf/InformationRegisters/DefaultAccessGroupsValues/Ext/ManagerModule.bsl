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

// It is connected to the offload of the unloaded data, which is undetectable.When registering the data handlers, the data loads.
//
// Parameters:
//   Container - DataProcessorObject.ExportImportDataContainerManager
//   ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager
//   Serializer - XDTOSerializer
//   Object - ConstantValueManager
//          - CatalogObject
//          - DocumentObject
//          - BusinessProcessObject
//          - TaskObject
//          - ChartOfAccountsObject
//          - ExchangePlanObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfCalculationTypesObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet
//          - SequenceRecordSet
//          - RecalculationRecordSet
//   Artifacts - Array of XDTODataObject
//   Cancel - Boolean
//
Procedure BeforeExportObject(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel) Export
	
	AccessManagementInternal.BeforeExportRecordSet(Container, ObjectExportManager, Serializer, Object, Artifacts, Cancel);
	
EndProcedure

// End CloudTechnology.ExportImportData

#EndRegion

#EndRegion

#Region Private

// Parameters:
//  List - DynamicList
//  FieldName - String
//
Procedure CreateARepresentationOfTheAccessValueType(List, FieldName) Export
	
	AccessValuesTypes = Metadata.DefinedTypes.AccessValue.Type.Types();
	
	For Each Type In AccessValuesTypes Do
		Types = New Array;
		Types.Add(Type);
		TypeDetails = New TypeDescription(Types);
		TypeBlankRef = TypeDetails.AdjustValue(Undefined);
		
		// 
		AppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
		AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		
		AppearanceItem.Appearance.SetParameterValue("Text", String(Type));
		
		FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue  = New DataCompositionField(FieldName);
		FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
		FilterElement.RightValue = TypeBlankRef;
		FilterElement.Use  = True;
		
		FieldItem = AppearanceItem.Fields.Items.Add();
		FieldItem.Field = New DataCompositionField(FieldName);
		FieldItem.Use = True;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
