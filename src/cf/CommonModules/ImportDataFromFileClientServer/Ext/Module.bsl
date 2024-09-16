///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Creates a column description structure for the layout of loading data from a file.
//
// Parameters:
//  Name        -String -  column name.
//  Type       - TypeDescription -  the type of the column.
//  Title - String -  column header displayed in the upload form.
//  Width    - Number -  column width.
//  ToolTip - String -  hint displayed in the column header.
// 
// Returns:
//  Structure - :
//    * Name                      - String -  column name.
//    * Title                - String -  column header displayed in the upload form.
//    * Type                      - TypeDescription -  the type of the column.
//    * Width                   - Number  -  column width.
//    * Position                  - Number  - 
//    * ToolTip                - String - 
//    * IsRequiredInfo - Boolean -  true if the column must contain values.
//    * Group                   - String -  name of the column group.
//    * Parent                 - String -  used to link a dynamic column to the details of the table part of the object.
//
Function TemplateColumnDetails(Name, Type, Title = Undefined, Width = 0, ToolTip = "") Export
	
	TemplateColumn = New Structure;
	
	TemplateColumn.Insert("Name",       Name);
	TemplateColumn.Insert("Title", ?(ValueIsFilled(Title), String(Title), Name));
	TemplateColumn.Insert("Type",       Type);
	TemplateColumn.Insert("Position",   0);
	TemplateColumn.Insert("Width",    ?(Width = 0, 30, Width));
	TemplateColumn.Insert("ToolTip", ToolTip);
	TemplateColumn.Insert("IsRequiredInfo", False);
	TemplateColumn.Insert("Group",    "");
	TemplateColumn.Insert("Parent",  Name);
	
	Return TemplateColumn;
	
EndFunction

// Returns the layout column by name.
//
// Parameters:
//  Name				 - String -  column name.
//  ColumnsList	 - Array of See ImportDataFromFileClientServer.TemplateColumnDetails
// 
// Returns:
//   - See TemplateColumnDetails
//   - Undefined - if the column does not exist.
//
Function TemplateColumn(Name, ColumnsList) Export
	For Each Column In ColumnsList Do
		If Column.Name = Name Then
			Return Column;
		EndIf;
	EndDo;
	
	Return Undefined;
EndFunction

// Removes the layout column from the array.
//
// Parameters:
//  Name           - String -  column name.
//  ColumnsList - Array of See ImportDataFromFileClientServer.TemplateColumnDetails
//
Procedure DeleteTemplateColumn(Name, ColumnsList) Export
	
	For IndexOf = 0 To ColumnsList.Count() -1  Do
		If ColumnsList[IndexOf].Name = Name Then
			ColumnsList.Delete(IndexOf);
			Return;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

Function ColumnsHaveGroup(Val ColumnsInformation) Export
	ColumnsGroups = New Map;
	For Each TableColumn2 In ColumnsInformation Do
		ColumnsGroups.Insert(TableColumn2.Group);
	EndDo;
	Return ?(ColumnsGroups.Count() > 1, True, False);
EndFunction

Function MappingTablePrefix() Export
	Return "DataMappingTable";
EndFunction

Function TablePartPrefix() Export
	Return "TS";
EndFunction

Function StatusAmbiguity() Export
	Return UnmappedRowsPrefix() + "Conflict1";
EndFunction

Function StatusUnmapped() Export
	Return UnmappedRowsPrefix() + "NotMapped";
EndFunction

Function StatusMapped() Export
	Return "RowMapped";
EndFunction

Function UnmappedRowsPrefix() Export
	Return "Fix";
EndFunction

#EndRegion
