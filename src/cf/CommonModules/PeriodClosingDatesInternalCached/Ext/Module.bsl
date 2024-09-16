///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Returns information about the last test version of the current date, but not changed.
//
// Returns:
//  Structure:
//   * Date - Date -  date and time of the last valid date check.
//
Function LastCheckOfEffectiveClosingDatesVersion() Export
	
	Return New Structure("Date", '00010101');
	
EndFunction

// Returns the header fields of the metadata object.
//
// Parameters:
//  Table - String -  full name of the metadata object.
//
// Returns:
//  FixedStructure:
//    * Key - String -  field name.
//    * Value - Undefined
//
Function HeaderFields(Table) Export
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(StrReplace("SELECT * FROM #Table", "#Table", Table));
	
	HeaderFields = New Structure;
	For Each Column In QuerySchema.QueryBatch[0].Columns Do
		HeaderFields.Insert(Column.Alias);
	EndDo;
	
	Return New FixedStructure(HeaderFields);
	
EndFunction

#EndRegion
