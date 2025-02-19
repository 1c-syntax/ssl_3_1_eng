///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Allows you to change interface upon embedding.
//
// Parameters:
//  InterfaceSettings5 - Structure:
//   * UseExternalUsers - Boolean - initial value is False
//     if you set to True, period-end closing dates can be set up for external users.
//
Procedure InterfaceSetup(InterfaceSettings5) Export
	
	
	
EndProcedure

// Fills in sections of period-end closing dates used upon their setup.
// If you do not specify any section, then only common period-end closing date setup will be available.
//
// Parameters:
//  Sections - ValueTable:
//   * Name - String - Name used in the data source details
//       in the FillDataSourcesForPeriodClosingCheck procedure.
//
//   * Id - UUID - an item reference ID of chart of characteristic types.
//       To get an ID, execute the platform method in 1C:Enterprise mode:
//       "ChartsOfCharacteristicTypes.PeriodClosingDatesSections.GetRef().UUID()".
//       Do not specify IDs received using any other method
//       as it can violate their uniqueness.
//
//   * Presentation - String - presents a section in the form of period-end closing date setup.
//
//   * ObjectsTypes  - Array - object reference types, by which you can set period-end closing dates,
//       for example, Type("CatalogRef.Companies"), if no type is specified,
//       period-end closing dates are set up only to the precision of a section.
//
Procedure OnFillPeriodClosingDatesSections(Sections) Export
	
	
	
EndProcedure

// Allows you to specify tables and object fields to check period-end closing.
// To add a new source to DataSources  See PeriodClosingDates.AddRow.
//
// Called from the ChangeProhibited procedure of the PeriodEndClosingDates common module
// used in the BeforeWrite event subscription of the object to check for period-end
// closing and canceled restricted object changes.
//
// Parameters:
//  DataSources - ValueTable:
//   * Table     - String - a full name of a metadata object,
//                   for example, Metadata.Documents.PurchaseInvoice.FullName().
//   * DateField    - String - an attribute name of an object or a tabular section,
//                   for example: "Date", "Goods.ShipmentDate".
//   * Section      - String - Name of a period-end closing date section
//                   specified in the OnFillPeriodClosingDatesSections procedure (see above).
//   * ObjectField - String - an attribute name of an object or a tabular section,
//                   for example: "Company", "Goods.Warehouse".
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	
	
EndProcedure

// "Allows overriding the execution of the change restriction check in an arbitrary way.<plch id="1">
//
// If the check is performed during the document write process, the "AdditionalProperties" of<plch id="1">
// the document "Object" includes the "WriteMode" ("DocumentWriteMode") property.<plch id="1">
// If the check is performed on a record set, the "AdditionalProperties" of the record set "Object" contains the "Replacing" property ("Boolean, ReplacementMode).<plch id="1">
// In the case of record replacement, the Filter property is configured to retrieve existing records from the database.
// 
//  
// Parameters:
//  Object       - CatalogObject
//               - DocumentObject
//               - ChartOfCharacteristicTypesObject
//               - ChartOfAccountsObject
//               - ChartOfCalculationTypesObject
//               - BusinessProcessObject
//               - TaskObject
//               - ExchangePlanObject
//               - InformationRegisterRecordSet
//               - AccumulationRegisterRecordSet
//               - AccountingRegisterRecordSet
//               - CalculationRegisterRecordSet - The data item or record set to be checked
//                 (as in the handlers "BeforeWrite" and "OnReadAtServer").
//
//  PeriodClosingCheck    - Boolean - set to False to skip period-end closing check.
//  ImportRestrictionCheckNode - ExchangePlanRef
//                              - Undefined - set to Undefined 
//                                to skip data import restriction check.
//  ObjectVersion               - String - Set "OldVersion" or "NewVersion" to check only the old
//                                object version (in the database) or only the new object version
//                                (in the "Object" parameter).
//                                By default, it is set to "" (both object versions are checked at the same time).
//
Procedure BeforeCheckPeriodClosing(Object,
                                         PeriodClosingCheck,
                                         ImportRestrictionCheckNode,
                                         ObjectVersion) Export
	
	
	
EndProcedure

// Allows overriding the process of retrieving data for checking the date restriction of an old (existing) data version.
// If "DataToCheck" is provided, it will not be automatically loaded from the database based on the "MetadataObject" and "DataID" parameters.
// If the check is conducted on a record set, the "AdditionalProperties" of the record set "DataID" contains the
//
// "Replacing" property (Boolean, SubstitutionMode) with possible values:
// "Replacing", "RefreshEnabled", "Join" and "Delete".
// In the case of record replacement, the "Filter" property is configured to retrieve existing records from the database.
// 
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object of data to be received.
//  DataID - CatalogRef
//                      - DocumentRef
//                      - ChartOfCharacteristicTypesRef
//                      - ChartOfAccountsRef
//                      - ChartOfCalculationTypesRef
//                      - BusinessProcessRef
//                      - TaskRef
//                      - ExchangePlanRef - Reference to the data item.
//                      - Filter - Record set filter in case "Replacing" is set to "True".
//                      - InformationRegisterRecordSet
//                      - AccumulationRegisterRecordSet
//                      - AccountingRegisterRecordSet
//                      - CalculationRegisterRecordSet - Record set in case "Replacing" in not Boolean.
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef - if Undefined, check period-end closing; 
//                                otherwise check data import from the exchange plan node.
//
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate.
//
//  Example:
//  If TypeOf(DataID) = Type("DocumentRef.Order") Then
//  	Data = Common.ObjectAttributesValues(DataID, "Company, WorkEndDate, WorkOrder");
//  	If Data.WorkOrder Then
//  		Check = DataToCheck.Add();
//  		Check.Section = "WorkOrders";
//  		Check.Object = Data.Company;
//  		Check.Date = Data.WorkEndDate;
//  	EndIf;
//  EndIf;
//
Procedure BeforeCheckOldDataVersion(MetadataObject, DataID, ImportRestrictionCheckNode, DataToCheck) Export
	
EndProcedure

// Allows overriding the process of retrieving data for checking the date restriction of a new (future) data version.
// If "DataToCheck" is provided, it will not be automatically extracted from the object or additionally loaded from
// the database based on the "MetadataObject" and "Data" parameters. If the check is performed during the document write process,
//
// the "AdditionalProperties" of the document "Data" includes the "WriteMode" ("DocumentWriteMode") property.
// If the check is conducted on a record set, the "AdditionalProperties" of the record set "Data" contains the
// "Replacing" property (Boolean, SubstitutionMode) with possible values:
// "Add", "Replacing", "RefreshEnabled", "Join".
// In the case of record replacement, the "Filter" property is configured to retrieve existing records from the database.
// 
//
// Parameters:
//  MetadataObject - MetadataObject - a metadata object of data to be received.
//  Data  - CatalogObject
//          - DocumentObject
//          - ChartOfCharacteristicTypesObject
//          - ChartOfAccountsObject
//          - ChartOfCalculationTypesObject
//          - BusinessProcessObject
//          - TaskObject
//          - ExchangePlanObject
//          - InformationRegisterRecordSet
//          - AccumulationRegisterRecordSet
//          - AccountingRegisterRecordSet
//          - CalculationRegisterRecordSet - Data item or record set to be checked.
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef - if Undefined, check period-end closing; 
//                                otherwise check data import from the exchange plan node.
//
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate.
//
//  Example:
//  If TypeOf(Data) = Type("DocumentObject.Order") AND Data.WorkOrder Then
//  	
//  	Check = DataToCheck.Add();
//  	Check.Section = "WorkOrders";
//  	Check.Object = Data.Company;
//  	Check.Date = Data.WorkEndDate;
//  	
//  EndIf;
//
Procedure BeforeCheckNewDataVersion(MetadataObject, Data, ImportRestrictionCheckNode, DataToCheck) Export
	
EndProcedure

#EndRegion
