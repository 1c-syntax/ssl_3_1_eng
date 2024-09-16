///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Table of recipient types in terms of storage and user representation of these types.
//
// Returns: 
//   ValueTable - :
//       * MetadataObjectID - CatalogRef.MetadataObjectIDs -  a link that is stored
//                                                                                              in the database.
//       * RecipientsType  - TypeDescription -  the type that limits the values of the recipient and excluded lists.
//       * Presentation   - String -  the representation of a type for users.
//       * MainCIKind   - CatalogRef.ContactInformationKinds -  contact information type: e-mail, by
//                                                                       default.
//       * CIGroup        - CatalogRef.ContactInformationKinds -  group of the contact information type.
//       * ChoiceFormPath - String -  path to the selection form.
//
Function RecipientsTypesTable() Export
	
	TypesTable = New ValueTable;
	TypesTable.Columns.Add("MetadataObjectID", New TypeDescription("CatalogRef.MetadataObjectIDs"));
	TypesTable.Columns.Add("RecipientsType", New TypeDescription("TypeDescription"));
	TypesTable.Columns.Add("Presentation", New TypeDescription("String"));
	TypesTable.Columns.Add("MainCIKind", New TypeDescription("CatalogRef.ContactInformationKinds"));
	TypesTable.Columns.Add("CIGroup", New TypeDescription("CatalogRef.ContactInformationKinds"));
	TypesTable.Columns.Add("ChoiceFormPath", New TypeDescription("String"));
	TypesTable.Columns.Add("MainType", New TypeDescription("TypeDescription"));
	
	TypesTable.Indexes.Add("MetadataObjectID");
	TypesTable.Indexes.Add("RecipientsType");
	
	AvailableTypes = Metadata.Catalogs.ReportMailings.TabularSections.Recipients.Attributes.Recipient.Type.Types();
	
	// 
	TypesSettings = New Structure;
	TypesSettings.Insert("MainType",       Type("CatalogRef.Users"));
	TypesSettings.Insert("AdditionalType", Type("CatalogRef.UserGroups"));
	ReportMailing.AddItemToRecipientsTypesTable(TypesTable, AvailableTypes, TypesSettings);
	
	// 
	ReportMailingOverridable.OverrideRecipientsTypesTable(TypesTable, AvailableTypes);
	
	// 
	BlankArray = New Array;
	For Each UnusedType In AvailableTypes Do
		ReportMailing.AddItemToRecipientsTypesTable(TypesTable, BlankArray, New Structure("MainType", UnusedType));
	EndDo;
	
	Return TypesTable;
EndFunction

// Excluded reports are used as an exclusion filter when selecting reports.
Function ReportsToExclude() Export
	
	MetadataArray = New Array;
	
	SSLSubsystemsIntegration.WhenDefiningExcludedReports(MetadataArray);
	ReportMailingOverridable.DetermineReportsToExclude(MetadataArray);
	
	Result = New Array;
	For Each ReportMetadata In MetadataArray Do
		Result.Add(Common.MetadataObjectID(ReportMetadata));
	EndDo;
	
	ReportsToExclude = New FixedArray(Result);
	
	Return ReportsToExclude;
	
EndFunction

Function FilesAndEmailTextParameters() Export

	ReportDistributionParameters = New Structure;
	
	ReportDistributionParameters.Insert("Recipient", NStr("en = 'Recipient';"));
	ReportDistributionParameters.Insert("ExecutionDate", NStr("en = 'Fulfillment date';"));
	ReportDistributionParameters.Insert("Author", NStr("en = 'Author';"));
	ReportDistributionParameters.Insert("MailingDescription", NStr("en = 'Distribution description';"));
	ReportDistributionParameters.Insert("GeneratedReports", NStr("en = 'Generated reports';"));
	ReportDistributionParameters.Insert("SystemTitle", NStr("en = 'Application title';"));
	ReportDistributionParameters.Insert("DeliveryMethod", NStr("en = 'Delivery method';"));
	ReportDistributionParameters.Insert("ReportFormat", NStr("en = 'Report format';"));
	ReportDistributionParameters.Insert("Period", NStr("en = 'Period';"));
	ReportDistributionParameters.Insert("MailingDate", NStr("en = 'Send date';"));
	ReportDistributionParameters.Insert("ReportDescription1", NStr("en = 'Report name';"));
	
	Return ReportDistributionParameters;

EndFunction

#EndRegion
