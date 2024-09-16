///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Allows you to change how the interface works when embedded.
//
// Parameters:
//  InterfaceSettings5 - Structure:
//   * UseExternalUsers - Boolean -  the initial value is False
//     . if set to True, then the ban dates can be configured for external users.
//
Procedure InterfaceSetup(InterfaceSettings5) Export
	
	
	
EndProcedure

// Fills in the sections of the ban dates for changes that are used when setting the ban dates.
// If you don't specify any sections, then only the General ban date setting will be available.
//
// Parameters:
//  Sections - ValueTable:
//   * Name - String -  the name used in the description of data sources in
//       the procedure fill in the data source for checking the change Request.
//
//   * Id - UUID - 
//       :
//       
//       
//       
//
//   * Presentation - String -  represents a section in the ban date settings form.
//
//   * ObjectsTypes  - Array -  types of object links that can be used to set the ban dates,
//       such as the Type ("reference Link.Companies"); if no type is specified,
//       the dates of the ban will only be adjusted to the exact section.
//
Procedure OnFillPeriodClosingDatesSections(Sections) Export
	
	
	
EndProcedure

// 
//  See PeriodClosingDates.AddRow.
//
// 
// 
// 
//
// Parameters:
//  DataSources - ValueTable:
//   * Table     - String -  the full name of the metadata object,
//                   such as Metadata.Documents.Prikhodnayanakladnaya.Full name().
//   * DateField    - String -  name of the object's or table part's details,
//                   for example: "Date", " Products.Upload date".
//   * Section      - String - 
//                   
//   * ObjectField - String -  name of the item's or table part's details,
//                   for example: "Company", " Products.Warehouse".
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	
	
EndProcedure

// Allows you to override the validation to be performed, but not changed in an arbitrary manner.
//
// If the check is performed while the document is being recorded, the Additional properties of the document Object
// property has the record Mode property.
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
//               - CalculationRegisterRecordSet -  
//                 
//
//  PeriodClosingCheck    - Boolean -  set to False to skip the data modification ban check.
//  ImportRestrictionCheckNode - ExchangePlanRef
//                              - Undefined -  
//                                
//  ObjectVersion               - String -  set" new version "or" New version " to
//                                check only the old version (in the database) 
//                                or only the new version of the object (in the Object parameter).
//                                By default, it contains the value "" - both versions of the object are checked at once.
//
Procedure BeforeCheckPeriodClosing(Object,
                                         PeriodClosingCheck,
                                         ImportRestrictionCheckNode,
                                         ObjectVersion) Export
	
	
	
EndProcedure

// Allows you to redefine getting data to check the date when the old (existing) version of data was banned.
//
// Parameters:
//  MetadataObject - MetadataObject -  metadata object for the received data.
//  DataID - CatalogRef
//                      - DocumentRef
//                      - ChartOfCharacteristicTypesRef
//                      - ChartOfAccountsRef
//                      - ChartOfCalculationTypesRef
//                      - BusinessProcessRef
//                      - TaskRef
//                      - ExchangePlanRef
//                      - Filter - 
//                                
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef -  
//                                
//
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate.
//
//  Example:
//  If The Tag Type(Data ID) = Type ("Document Link.Order") Then
//  	Data = General Purpose.Object Requisitvalues(Data ID, " Company, Work Completion Dateorder");
//  	If The Data.Custom Order Then
//  		Verification = Data For Verification.Add();
//  		Check.Section = " Custom Orders";
//  		Check.Object = Data.Company;
//  		Check.Date = Data.Dataconvert;
//  	Conicelli;
//  Conicelli;
//
Procedure BeforeCheckOldDataVersion(MetadataObject, DataID, ImportRestrictionCheckNode, DataToCheck) Export
	
EndProcedure

// Allows you to redefine getting data to check the date when a new (future) version of data was banned.
//
// Parameters:
//  MetadataObject - MetadataObject -  metadata object for the received data.
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
//          - CalculationRegisterRecordSet - 
//
//  ImportRestrictionCheckNode - Undefined
//                              - ExchangePlanRef -  
//                                
//
//  DataToCheck - See PeriodClosingDates.DataToCheckTemplate.
//
//  Example:
//  If The Patch Type(Data) = Type ("Document Object.Order") And Data.Custom Order Then
//  	
//  	Verification = Data For Verification.Add();
//  	Check.Section = " Custom Orders";
//  	Check.Object = Data.Company;
//  	Check.Date = Data.Dataconvert;
//  	
//  Conicelli;
//
Procedure BeforeCheckNewDataVersion(MetadataObject, Data, ImportRestrictionCheckNode, DataToCheck) Export
	
EndProcedure

#EndRegion
