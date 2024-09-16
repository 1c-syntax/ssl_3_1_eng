///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Creates a new parameter structure for loading data from a file into the table part.
//
// Returns:
//   Structure - :
//    * FullTabularSectionName - String   -  the full path to the table part of the document, 
//                                           in the form of "document Name.Kataboliceski".
//    * Title               - String   -  header of the form for uploading data from a file.
//    * DataStructureTemplateName      - String   -  name of the layout with the template for entering data.
//    * AdditionalParameters - Structure -  any additional information that will be passed
//                                           to the data matching procedure.
//    * TemplateColumns - Array of See ImportDataFromFileClientServer.TemplateColumnDetails
//                    - Undefined - 
//
Function DataImportParameters() Export
	
	ImportParameters = New Structure;
	ImportParameters.Insert("FullTabularSectionName", "");
	ImportParameters.Insert("Title", "");
	ImportParameters.Insert("DataStructureTemplateName", "");
	ImportParameters.Insert("AdditionalParameters", New Structure);
	ImportParameters.Insert("TemplateColumns", Undefined);
	
	Return ImportParameters;
	
EndFunction

// Opens the data upload form to fill in the table part.
//
// Parameters: 
//   ImportParameters   - See ImportDataFromFileClient.DataImportParameters.
//   ImportNotification - NotifyDescription  -  notification that will be called to add the loaded data to the
//                                               table part.
//
Procedure ShowImportForm(ImportParameters, ImportNotification) Export
	
	OpenForm("DataProcessor.ImportDataFromFile.Form", ImportParameters, 
		ImportNotification.Module, , , , ImportNotification);
		
EndProcedure


#EndRegion

#Region Internal

// Opens the data upload form to fill in the tabular part of the link mapping in the report Options subsystem.
//
// Parameters: 
//   ImportParameters   - See ImportDataFromFileClient.DataImportParameters.
//   ImportNotification - NotifyDescription  -  notification that will be called to add the loaded data to the
//                                               table part.
//
Procedure ShowRefFillingForm(ImportParameters, ImportNotification) Export
	
	OpenForm("DataProcessor.ImportDataFromFile.Form", ImportParameters,
		ImportNotification.Module,,,, ImportNotification);
		
EndProcedure

#EndRegion

#Region Private

// Opens the file upload dialog.
//
// Parameters:
//  CompletionNotification - NotifyDescription -  called after successfully placing the file.
//  FileName	         - String -  name of the file in the dialog.
//
Procedure FileImportDialog(CompletionNotification , FileName = "") Export
	
	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("en = 'All supported file formats (*.xls; *.xlsx; *.ods; *.mxl; *.csv)|*.xls;*.xlsx;*.ods;*.mxl;*.csv|Excel Workbook 97 (*.xls)|*.xls|Excel Workbook 2007 (*.xlsx)|*.xlsx|OpenDocument Spreadsheet (*.ods)|*.ods|Comma-separated values file(*.csv)|*.csv|Spreadsheet document (*.mxl)|*.mxl';");
	ImportParameters.FormIdentifier = CompletionNotification.Module.UUID;
	
	
	FileSystemClient.ImportFile_(CompletionNotification, ImportParameters, FileName);
	
EndProcedure

#EndRegion
