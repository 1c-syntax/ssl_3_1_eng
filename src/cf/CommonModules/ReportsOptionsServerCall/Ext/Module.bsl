///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Opens an additional report form with the specified option.
//
// Parameters:
//  Link-Reference Link.Additional reportsprocessing-link to the additional report.
//  Option key-String-name of the additional report option.
//
Procedure OnAttachReport(OpeningParameters) Export
	
	ReportsOptions.OnAttachReport(OpeningParameters);
	
EndProcedure

// Gets the sub-account type by its number.
//
// Parameters:
//  Account - ChartOfAccountsRef -  invoice link.
//  ExtDimensionNumber - Number -  sub-contact number.
//
// Returns:
//   TypeDescription - 
//   
//
Function ExtDimensionType(Account, ExtDimensionNumber) Export
	
	If Account = Undefined Then 
		Return Undefined;
	EndIf;
	
	MetadataObject = Account.Metadata();
	
	If Not Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
		Return Undefined;
	EndIf;
	
	Query = New Query(
	"SELECT ALLOWED
	|	ChartOfAccountsExtDimensionTypes.ExtDimensionType.ValueType AS Type
	|FROM
	|	&FullTableName AS ChartOfAccountsExtDimensionTypes
	|WHERE
	|	ChartOfAccountsExtDimensionTypes.Ref = &Ref
	|	AND ChartOfAccountsExtDimensionTypes.LineNumber = &LineNumber");
	
	Query.Text = StrReplace(Query.Text, "&FullTableName", MetadataObject.FullName() + ".ExtDimensionTypes");
	
	Query.SetParameter("Ref", Account);
	Query.SetParameter("LineNumber", ExtDimensionNumber);
	
	Selection = Query.Execute().Select();
	
	If Not Selection.Next() Then
		Return Undefined;
	EndIf;
	
	Return Selection.Type;
	
EndFunction

// Parameters:
//   FilesDetails - Array of Structure:
//     * Location - String
//     * Name - String
//
// Returns:
//   Array of Structure
//
Function UpdateReportOptionsFromFiles(FilesDetails) Export
	
	Return ReportsOptions.UpdateReportOptionsFromFiles(FilesDetails);
	
EndFunction

// Parameters:
//   FileDetails - Structure:
//     * Location - String
//     * Name - String 
//   ReportOptionBase - CatalogRef.ReportsOptions 
//
// Returns:
//   
//
Function UpdateReportOptionFromFile(FileDetails, ReportOptionBase) Export
	
	Return ReportsOptions.UpdateReportOptionFromFile(FileDetails, ReportOptionBase);
	
EndFunction

// Parameters:
//   SelectedUsers - See ReportsOptions.ShareUserSettings.SelectedUsers
//   SettingsDescription - See ReportsOptions.ShareUserSettings.SettingsDetailsTemplate
//
Procedure ShareUserSettings(SelectedUsers, SettingsDescription) Export 
	
	ReportsOptions.ShareUserSettings(SelectedUsers, SettingsDescription);
	
EndProcedure

// Parameters:
//  ReportVariant - See ReportsOptions.IsPredefinedReportOption.ReportVariant
//
// Returns:
//  Boolean
//
Function IsPredefinedReportOption(ReportVariant) Export 
	
	Return ReportsOptions.IsPredefinedReportOption(ReportVariant);
	
EndFunction

#EndRegion
