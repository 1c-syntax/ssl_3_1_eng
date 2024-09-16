///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns a description of the columns in the table part or table of values.
//
// Parameters:
//  Table - ValueTable -  Descriptiontablecarticle with columns.
//          - FormDataCollection - 
//          - String - 
//              
//  Columns - String -  a comma-separated list of extracted columns. For example: "Number, Product, Quantity".
// 
// Returns:
//   Array of See ImportDataFromFileClientServer.TemplateColumnDetails.
//
Function GenerateColumnDetails(Table, Columns = Undefined) Export
	
	DontExtractAllColumns = False;
	If Columns <> Undefined Then
		ColumnsListForExtraction = StrSplit(Columns, ",", False);
		DontExtractAllColumns = True;
	EndIf;
	
	ColumnsList = New Array;
	If TypeOf(Table) = Type("FormDataCollection") Then
		TableCopy = Table;
		InternalTable = TableCopy.Unload();
		InternalTable.Columns.Delete("SourceLineNumber");
		InternalTable.Columns.Delete("LineNumber");
	Else
		InternalTable= Table;
	EndIf;
	
	Position = 1;
	If TypeOf(InternalTable) = Type("ValueTable") Then
		For Each Column In InternalTable.Columns Do
			If DontExtractAllColumns And ColumnsListForExtraction.Find(Column.Name) = Undefined Then
				Continue;
			EndIf;
			ToolTip = "";
			For Each ColumnType In Column.ValueType.Types() Do
				MetadataObject = Metadata.FindByType(ColumnType);
				
				If MetadataObject <> Undefined Then
					ToolTip = ToolTip + MetadataObject.Comment + Chars.LF;
					
					If Common.IsEnum(MetadataObject) Then
						ToolTipSet = New Array;
						ToolTipSet.Add(NStr("en = 'Available options:';"));
						For Each EnumOption In MetadataObject.EnumValues Do
							ToolTipSet.Add(EnumOption.Presentation());
						EndDo;
						ToolTip = StrConcat(ToolTipSet, Chars.LF);
					EndIf;
					
				EndIf;
			EndDo;
			
			NewColumn = ImportDataFromFileClientServer.TemplateColumnDetails(Column.Name, Column.ValueType, Column.Title, Column.Width, ToolTip);
			NewColumn.Position = Position;
			ColumnsList.Add(NewColumn);
			
			Position = Position + 1;
		
		EndDo;
	ElsIf TypeOf(InternalTable) = Type("String") Then
		Object = Common.MetadataObjectByFullName(InternalTable); // MetadataObjectCatalog, MetadataObjectDocument 
		For Each Column In Object.Attributes Do
			If DontExtractAllColumns And ColumnsListForExtraction.Find(Column.Name) = Undefined Then
				Continue;
			EndIf;
			
			NewColumn = ImportDataFromFileClientServer.TemplateColumnDetails(Column.Name, Column.Type, Column.Presentation());
			NewColumn.ToolTip = Column.Tooltip;
			NewColumn.Width    = 30;
			NewColumn.Position   = Position;
			ColumnsList.Add(NewColumn);
			
			Position = Position + 1;
		EndDo;
	EndIf;
	
	Return ColumnsList;
EndFunction

// Settings for loading new and existing items.
// 
// Returns:
//  Structure: 
//    * CreateNewItems - Boolean
//    * UpdateExistingItems - Boolean
//
Function DataLoadingSettings() Export
	
	ImportParameters = New Structure();
	ImportParameters.Insert("CreateNewItems", False);
	ImportParameters.Insert("UpdateExistingItems", False);
	Return ImportParameters;
	
EndFunction

// Adds service columns to the loaded data table.
// The list of table columns is dynamic and is formed based on the layout of the loaded data.
// The return value describes only the service columns that are always present.
// 
// Parameters:
//  DataToImport - ValueTable
//  MappingObjectTypeDetails - TypeDescription -    description of the mapping object type.
//  ColumnHeaderOfTheMappingObject - String -  the column header of the mapping object.
// 
// Returns:
//  ValueTable:
//       * MappedObject         - CatalogRef -  a reference to the mapped object.
//       * RowMappingResult - String       -  download status, possible options: Created, Updated, Skipped.
//       * ErrorDescription               - String       -  decryption of the data loading error.
//       * Id                - Number        -  unique line number
//       * ConflictsList       - ValueList -a list of ambiguities that occurred when loading data.
//
Function DescriptionOfTheUploadedDataForReferenceBooks(DataToImport, MappingObjectTypeDetails, ColumnHeaderOfTheMappingObject) Export
		
	DataToImport.Columns.Add("Id", New TypeDescription("Number"), NStr("en = '#';"));
	DataToImport.Columns.Add("MappingObject", MappingObjectTypeDetails, ColumnHeaderOfTheMappingObject);
	DataToImport.Columns.Add("RowMappingResult", New TypeDescription("String"), NStr("en = 'Result';"));
	DataToImport.Columns.Add("ErrorDescription", New TypeDescription("String"), NStr("en = 'Reason';"));
	DataToImport.Columns.Add("ConflictsList", New TypeDescription("ValueList"), "ConflictsList");
	
	Return DataToImport;
	
EndFunction

// Create a table with a list of ambiguities for which there are several suitable data variants in the IB.
// 
// Returns:
//  ValueTable:
//     * Column       - String -  name of the column where the ambiguity was detected;
//     * Id - Number  -  ID of the string where the ambiguity was detected.
//
Function ANewListOfAmbiguities() Export
	
	ConflictsList = New ValueTable;
	ConflictsList.Columns.Add("Id");
	ConflictsList.Columns.Add("Column");
	
	Return ConflictsList;
EndFunction

// 
// 
// 
// 
// Parameters:
//  ResultAddress - String -  address in temporary storage 
// 
// Returns:
//  ValueTable:
//     * MappedObject - CatalogRef -  a reference to the mapped object. Filled in inside the procedure.
//
Function MappingTable(ResultAddress) Export
	
	MappingTable = GetFromTempStorage(ResultAddress);
	Return MappingTable;
	
EndFunction

// 
// 
// 
//
// Parameters:
//  ObjectReference - AnyRef - 
//  TableRow - ValueTableRow of See ImportDataFromFile.DescriptionOfTheUploadedDataForReferenceBooks
//
Procedure WritePropertiesOfObject(ObjectReference, TableRow) Export
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManagerInternal = Common.CommonModule("PropertyManagerInternal");
		ModulePropertyManagerInternal.ImportPropertiesValuesfromFile(ObjectReference, TableRow);
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

Procedure AddStatisticalInformation(OperationName, Value = 1, Comment = "") Export
	
	If Common.SubsystemExists("StandardSubsystems.MonitoringCenter") Then
		ModuleMonitoringCenter = Common.CommonModule("MonitoringCenter");
		OperationName = "ImportDataFromFile." + OperationName;
		ModuleMonitoringCenter.WriteBusinessStatisticsOperation(OperationName, Value, Comment);
	EndIf;
	
EndProcedure

// Provides all required information about the procedure for loading data from a file.
//
// Returns:
//  Structure:
//    * Title - String -  a view in the list of loading options and in the window title.
//    * ColumnDataType - Map of KeyAndValue:
//        ** Key - String -  the name of the table column.
//        ** Value - TypeDescription -  description of the column data type.
//    * DataStructureTemplateName - String -  the name of the layout with the data structure (optional
//                                    parameter, the default value is "File Data upload").
//    * RequiredTemplateColumns - Array of String -  contains a list of required fields to fill in.
//    * TitleMappingColumns - String -  representation of the mapping column in the header
//                                                    of the data mapping table(optional parameter, the
//                                                    default value is formed - " Reference: < synonym of reference>").
//    * FullObjectName - String -  the full name of the object, as in the metadata. For example, a Reference book.Partners.
//    * ObjectPresentation - String -  representation of an object in a data mapping table. For example, "Client".
//    * ImportType - String -  data loading options (service).
//
Function ImportFromFileParameters(MappingObjectName) Export
	
	ObjectMetadata = Common.MetadataObjectByFullName(MappingObjectName);
	
	RequiredTemplateColumns = New Array;
	For Each Attribute In ObjectMetadata.Attributes Do
		If Attribute.FillChecking=FillChecking.ShowError Then
			RequiredTemplateColumns.Add(Attribute.Name);
		EndIf;
	EndDo;
		
	DefaultParameters = New Structure;
	DefaultParameters.Insert("Title", ObjectMetadata.Presentation());
	DefaultParameters.Insert("RequiredColumns2", RequiredTemplateColumns);
	DefaultParameters.Insert("ColumnDataType", New Map);
	DefaultParameters.Insert("ImportType", "");
	DefaultParameters.Insert("FullObjectName", MappingObjectName);
	DefaultParameters.Insert("ObjectPresentation", ObjectMetadata.Presentation());
	
	Return DefaultParameters;
	
EndFunction

Function PresentationOfTextYesForBoolean() Export
	Return NStr("en = 'Yes';");
EndFunction

#EndRegion
