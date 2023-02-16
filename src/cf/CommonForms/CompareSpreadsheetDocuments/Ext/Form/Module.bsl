﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Common.IsMobileClient() Then
		Cancel = True;
		Raise NStr("en = 'The operation is not available in the mobile client. Use the thin client.';");
	EndIf;
	
	SpreadsheetDocumentsToCompare = GetFromTempStorage(Parameters.SpreadsheetDocumentsAddress);
	DeleteFromTempStorage(Parameters.SpreadsheetDocumentsAddress);
	SpreadsheetDocumentLeft = PrepareSpreadsheetDocument(SpreadsheetDocumentsToCompare.Left_1);
	SpreadsheetDocumentRight = PrepareSpreadsheetDocument(SpreadsheetDocumentsToCompare.Right);
	
	Items.LeftSpreadsheetDocumentGroup.Title = Parameters.TitleLeft;
	Items.RightSpreadsheetDocumentGroup.Title = Parameters.TitleRight;
	
	If Not IsBlankString(Parameters.Title) Then
		Title = Parameters.Title;
	EndIf;
	
	CompareAtServer();
	
EndProcedure

#EndRegion

#Region SpreadsheetDocumentLeftFormTableItemEventHandlers

&AtClient
Procedure SpreadsheetDocumentLeftOnActivate(Item)
	
	If DisableOnActivateHandler = True Then
		Return;
	EndIf;
	
	Source = New Structure("Object, Item", SpreadsheetDocumentLeft, Items.SpreadsheetDocumentLeft);
	Receiver = New Structure("Object, Item", SpreadsheetDocumentRight, Items.SpreadsheetDocumentRight);
	
	MatchesSource = New Structure("Rows, Columns2", RowsMapLeft, ColumnsMapLeft);
	MatchesDestination = New Structure("Rows, Columns2", RowsMapRight, ColumnsMapRight);
	
	ProcessAreaActivation(Source, Receiver, MatchesSource, MatchesDestination);
	
EndProcedure

#EndRegion

#Region SpreadsheetDocumentRightFormTableItemEventHandlers

&AtClient
Procedure SpreadsheetDocumentRightOnActivate(Item)
	
	If DisableOnActivateHandler = True Then
		Return;
	EndIf;
		
	Source = New Structure("Object, Item", SpreadsheetDocumentRight, Items.SpreadsheetDocumentRight);
	Receiver = New Structure("Object, Item", SpreadsheetDocumentLeft, Items.SpreadsheetDocumentLeft);
	
	MatchesSource = New Structure("Rows, Columns2", RowsMapRight, ColumnsMapRight);
	MatchesDestination = New Structure("Rows, Columns2", RowsMapLeft, ColumnsMapLeft);
	
	ProcessAreaActivation(Source, Receiver, MatchesSource, MatchesDestination);
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure PreviousChangeLeftCommand(Command)
	
	PreviousChange(Items.SpreadsheetDocumentLeft, SpreadsheetDocumentLeft, CellDifferencesLeft);
	
EndProcedure

&AtClient
Procedure PreviousChangeRightCommand(Command)
	
	PreviousChange(Items.SpreadsheetDocumentRight, SpreadsheetDocumentRight, CellDifferencesRight);
	
EndProcedure

&AtClient
Procedure NextChangeLeftCommand(Command)
	
	NextChange(Items.SpreadsheetDocumentLeft, SpreadsheetDocumentLeft, CellDifferencesLeft);
	
EndProcedure

&AtClient
Procedure NextChangeRightCommand(Command)
	
	NextChange(Items.SpreadsheetDocumentRight, SpreadsheetDocumentRight, CellDifferencesRight);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CompareAtServer()

	DisableOnActivateHandler = True;
			
	RowsMapLeft = New ValueList;
	RowsMapRight = New ValueList;
	
	ColumnsMapLeft = New ValueList;
	ColumnsMapRight = New ValueList;
	
	CellDifferencesLeft.Clear();
	CellDifferencesRight.Clear();
	
	PerformComparison();
	
	DisableOnActivateHandler = False;
	
EndProcedure	

&AtServer
Procedure PerformComparison()
	
	#Region Comparison
	
	// Exporting text from spreadsheet document cells to the value tables.
	LeftDocumentTable = ReadSpreadsheetDocument(SpreadsheetDocumentLeft);
	RightDocumentTable = ReadSpreadsheetDocument(SpreadsheetDocumentRight);
	
	// Comparing the spreadsheet documents by lines and selecting the matching lines.
	Maps1 = GenerateMatches(LeftDocumentTable, RightDocumentTable, True);
	RowsMapLeft = Maps1[0];
	RowsMapRight = Maps1[1];
	
	// 
	Maps1 = GenerateMatches(LeftDocumentTable, RightDocumentTable, False);
	ColumnsMapLeft = Maps1[0];
	ColumnsMapRight = Maps1[1];
	
	LeftDocumentTable = Undefined;
	RightDocumentTable = Undefined;
	
	#EndRegion
	
	#Region DifferencesView
	
	DeletedAreaColorBackground	= StyleColors.DeletedAttributeBackground;
	AddedAreaColorBackground	= StyleColors.AddedAttributeBackground;
	ChangedAreaColorBackground	= StyleColors.ModifiedAttributeValueBackground;
	ChangedAreaColorText	= StyleColors.ModifiedAttributeValueColor;
		
	
	LeftTableHeight = SpreadsheetDocumentLeft.TableHeight;
	LeftTableWidth = SpreadsheetDocumentLeft.TableWidth;
	
	RightTableHeight = SpreadsheetDocumentRight.TableHeight;
	RightTableWidth = SpreadsheetDocumentRight.TableWidth;

	// Lines that were deleted from the left spreadsheet document.
	For LineNumber = 1 To RowsMapLeft.Count()-1 Do
		
		If RowsMapLeft[LineNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentLeft.Area(LineNumber, 1, LineNumber, LeftTableWidth);
			Area.BackColor = DeletedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesLeft.Add();
			NewDifferenceRow.LineNumber = LineNumber;
			NewDifferenceRow.ColumnNumber = 0;
			
		EndIf;
		
	EndDo;
	
	// Columns that were deleted from the left spreadsheet document.
	For ColumnNumber = 1 To ColumnsMapLeft.Count()-1 Do
		
		If ColumnsMapLeft[ColumnNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentLeft.Area(1, ColumnNumber, LeftTableHeight, ColumnNumber);
			Area.BackColor = DeletedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesLeft.Add();
			NewDifferenceRow.LineNumber = 0;
			NewDifferenceRow.ColumnNumber = ColumnNumber;
			
		EndIf;
		
	EndDo;
	
	// Lines that were added to the right spreadsheet document.
	For LineNumber = 1 To RowsMapRight.Count()-1 Do
		
		If RowsMapRight[LineNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentRight.Area(LineNumber, 1, LineNumber, RightTableWidth);
			Area.BackColor = AddedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesRight.Add();
			NewDifferenceRow.LineNumber = LineNumber;
			NewDifferenceRow.ColumnNumber = 0;
			
		EndIf;
		
	EndDo;
	
	// Columns that were added to the right spreadsheet document.
	For ColumnNumber = 1 To ColumnsMapRight.Count()-1 Do
		
		If ColumnsMapRight[ColumnNumber].Value = Undefined Then
			
			Area = SpreadsheetDocumentRight.Area(1, ColumnNumber, RightTableHeight, ColumnNumber);
			Area.BackColor = AddedAreaColorBackground;
			
			NewDifferenceRow = CellDifferencesRight.Add();
			NewDifferenceRow.LineNumber = 0;
			NewDifferenceRow.ColumnNumber = ColumnNumber;
			
		EndIf;
		
	EndDo;
	
	// Cells that were modified.
	For LineNumber1 = 1 To RowsMapLeft.Count()-1 Do
		
		LineNumber2 = RowsMapLeft[LineNumber1].Value;
		If LineNumber2 = Undefined Then
			Continue;
		EndIf;
		
		For ColumnNumber1 = 1 To ColumnsMapLeft.Count()-1 Do
			
			ColumnNumber2 = ColumnsMapLeft[ColumnNumber1].Value;
			If ColumnNumber2 = Undefined Then
				Continue;
			EndIf;
			
			Area1 = SpreadsheetDocumentLeft.Area(LineNumber1, ColumnNumber1, LineNumber1, ColumnNumber1);
			Area2 = SpreadsheetDocumentRight.Area(LineNumber2, ColumnNumber2, LineNumber2, ColumnNumber2);
			
			If Not CompareAreas(Area1, Area2) Then
				
				Area1 = SpreadsheetDocumentLeft.Area(LineNumber1, ColumnNumber1);
				Area2 = SpreadsheetDocumentRight.Area(LineNumber2, ColumnNumber2);
				
				Area1.TextColor = ChangedAreaColorText;
				Area2.TextColor = ChangedAreaColorText;
				
				Area1.BackColor = ChangedAreaColorBackground;
				Area2.BackColor = ChangedAreaColorBackground;
				
				
				NewDifferenceRow = CellDifferencesLeft.Add();
				NewDifferenceRow.LineNumber = LineNumber1;
				NewDifferenceRow.ColumnNumber = ColumnNumber1;
				
				NewDifferenceRow = CellDifferencesRight.Add();
				NewDifferenceRow.LineNumber = LineNumber2;
				NewDifferenceRow.ColumnNumber = ColumnNumber2;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	CellDifferencesLeft.Sort("LineNumber, ColumnNumber");
	CellDifferencesRight.Sort("LineNumber, ColumnNumber");
	
	#EndRegion
	
EndProcedure

&AtServer
Function CompareAreas(Area1, Area2)
	
	If Area1.Text <> Area2.Text Then
		Return False;
	EndIf;
	
	If Area1.Comment.Text <> Area2.Comment.Text Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

&AtServer
Function ReadSpreadsheetDocument(SourceSpreadsheetDocument)
	
	ColumnCount = SourceSpreadsheetDocument.TableWidth;
	
	If ColumnCount = 0 Then
		Return New ValueTable;
	EndIf;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	For ColumnNumber = 1 To ColumnCount Do
		SpreadsheetDocument.Area(1, ColumnNumber, 1, ColumnNumber).Text = "Number_" + Format(ColumnNumber,"NG=0");
	EndDo;
	
	SpreadsheetDocument.Put(SourceSpreadsheetDocument);
	
	Builder = New QueryBuilder;
	
	Builder.DataSource = New DataSourceDescription(SpreadsheetDocument.Area());
	Builder.Execute();
	ValueTableResult = Builder.Result.Unload();
	
	Return ValueTableResult;
	
EndFunction

&AtServer
Function GenerateMatches(LeftTable, RightTable, ByRows)
	
	DataFromLeftTable = GetDataForComparison(LeftTable, ByRows);
	
	DataFromRightTable = GetDataForComparison(RightTable, ByRows);
	
	If ByRows Then
		MatchResultLeft = New ValueList;
		MatchResultLeft.LoadValues(New Array(LeftTable.Count()+1));
		
		MatchResultRight = New ValueList;
		MatchResultRight.LoadValues(New Array(RightTable.Count()+1));		
		
	Else
		MatchResultLeft = New ValueList;
		MatchResultLeft.LoadValues(New Array(LeftTable.Columns.Count()+1));
		
		MatchResultRight = New ValueList;
		MatchResultRight.LoadValues(New Array(RightTable.Columns.Count()+1));
		
	EndIf;
	
	QueryText = "";
	
	QueryText = QueryText + "	SELECT * INTO LeftTable 
								|	FROM &DataFromLeftTable AS DataFromLeftTable;" + Chars.LF;
								
	QueryText = QueryText + "	SELECT * INTO RightTable
								|	FROM &DataFromRightTable AS DataFromRightTable;" + Chars.LF;
		
	QueryText = QueryText + "SELECT
	                              |	LeftTable.Number AS ItemNumberLeft,
	                              |	RightTable.Number AS ItemNumberRight,
	                              |	CASE
	                              |		WHEN RightTable.Number - LeftTable.Number < 0
	                              |			THEN LeftTable.Number - RightTable.Number
	                              |		ELSE RightTable.Number - LeftTable.Number
	                              |	END AS DistanceFromBeginning,
	                              |	CASE
	                              |		WHEN &RowCountRight - RightTable.Number - (&RowCountLeft - LeftTable.Number) < 0
	                              |			THEN &RowCountLeft - LeftTable.Number - (&RowCountRight - RightTable.Number)
	                              |		ELSE &RowCountRight - RightTable.Number - (&RowCountLeft - LeftTable.Number)
	                              |	END AS DistanceFromEnd,
	                              |	SUM(CASE
	                              |			WHEN LeftTable.Value <> """"
	                              |				THEN CASE
	                              |						WHEN LeftTable.Count < RightTable.Count
	                              |							THEN LeftTable.Count
	                              |						ELSE RightTable.Count
	                              |					END
	                              |			ELSE 0
	                              |		END) AS ValueMatchesCount,
	                              |	SUM(CASE
	                              |			WHEN LeftTable.Count < RightTable.Count
	                              |				THEN LeftTable.Count
	                              |			ELSE RightTable.Count
	                              |		END) AS TotalMatchesCount
	                              |INTO DataCollapsed
	                              |FROM
	                              |	LeftTable AS LeftTable
	                              |		INNER JOIN RightTable AS RightTable
	                              |		ON LeftTable.Value = RightTable.Value
	                              |
	                              |GROUP BY
	                              |	LeftTable.Number,
	                              |	RightTable.Number
	                              |;
	                              |
	                              |////////////////////////////////////////////////////////////////////////////////
	                              |SELECT
	                              |	DataCollapsed.ItemNumberLeft AS ItemNumberLeft,
	                              |	DataCollapsed.ItemNumberRight AS ItemNumberRight,
	                              |	DataCollapsed.ValueMatchesCount AS ValueMatchesCount,
	                              |	DataCollapsed.TotalMatchesCount AS TotalMatchesCount,
	                              |	CASE
	                              |		WHEN DataCollapsed.DistanceFromBeginning < DataCollapsed.DistanceFromEnd
	                              |			THEN DataCollapsed.DistanceFromBeginning
	                              |		ELSE DataCollapsed.DistanceFromEnd
	                              |	END AS MinDistance
	                              |INTO DataWithDistances
	                              |FROM
	                              |	DataCollapsed AS DataCollapsed
	                              |;
	                              |
	                              |////////////////////////////////////////////////////////////////////////////////
	                              |SELECT
	                              |	DataWithDistances.ItemNumberLeft AS ItemNumberLeft,
	                              |	DataWithDistances.ItemNumberRight AS ItemNumberRight,
	                              |	DataWithDistances.ValueMatchesCount * ParameterMaxima.TotalMatchesCount * ParameterMaxima.MinDistance + DataWithDistances.TotalMatchesCount * ParameterMaxima.MinDistance + (ParameterMaxima.MinDistance - DataWithDistances.MinDistance) AS Weight
	                              |INTO WeightedMatches
	                              |FROM
	                              |	DataWithDistances AS DataWithDistances,
	                              |	(SELECT
	                              |		MAX(DataWithDistances.TotalMatchesCount) AS TotalMatchesCount,
	                              |		MAX(DataWithDistances.MinDistance) AS MinDistance
	                              |	FROM
	                              |		DataWithDistances AS DataWithDistances) AS ParameterMaxima
	                              |;
	                              |
	                              |////////////////////////////////////////////////////////////////////////////////
	                              |SELECT
	                              |	BestMatch.ItemNumberLeft AS ItemNumberLeft,
	                              |	WeightedMatches.ItemNumberRight AS ItemNumberRight,
								  | WeightedMatches.Weight AS Weight
	                              |INTO Maps1
	                              |FROM
	                              |	(SELECT
	                              |		WeightedMatches.ItemNumberLeft AS ItemNumberLeft,
	                              |		MAX(WeightedMatches.Weight) AS Weight
	                              |	FROM
	                              |		WeightedMatches AS WeightedMatches
	                              |	
	                              |	GROUP BY
	                              |		WeightedMatches.ItemNumberLeft) AS BestMatch
	                              |		LEFT JOIN WeightedMatches AS WeightedMatches
	                              |		ON BestMatch.ItemNumberLeft = WeightedMatches.ItemNumberLeft
	                              |			AND BestMatch.Weight = WeightedMatches.Weight";
	
		Query = New Query(QueryText);
		Query.TempTablesManager = New TempTablesManager;
		Query.SetParameter("DataFromLeftTable", DataFromLeftTable);
		Query.SetParameter("DataFromRightTable", DataFromRightTable);
		Query.SetParameter("RowCountLeft", LeftTable.Count());
		Query.SetParameter("RowCountRight", RightTable.Count());
		Query.Execute();
		
		LevelOfConflicts = 2;
		
		While LevelOfConflicts > 0 Do
			Query.Text = "SELECT
			|	AllConflicts.ItemNumberLeft AS ItemNumberLeft,
			|	AllConflicts.ItemNumberRight AS ItemNumberRight,
			|	SUM(AllConflicts.NumberOfConflicts) AS NumberOfConflicts
			|INTO ConflictsFound
			|FROM
			|	(SELECT
			|		Maps1.ItemNumberLeft AS ItemNumberLeft,
			|		Maps1.ItemNumberRight AS ItemNumberRight,
			|		1 AS NumberOfConflicts
			|	FROM
			|		Maps1 AS Maps1
			|			INNER JOIN Maps1 AS Maps11
			|			ON Maps1.ItemNumberRight < Maps11.ItemNumberRight
			|			AND Maps1.ItemNumberLeft > Maps11.ItemNumberLeft
			|
			|	UNION ALL
			|
			|	SELECT
			|		Maps1.ItemNumberLeft,
			|		Maps1.ItemNumberRight,
			|		1
			|	FROM
			|		Maps1 AS Maps1
			|			INNER JOIN Maps1 AS Maps11
			|			ON Maps1.ItemNumberRight > Maps11.ItemNumberRight
			|			AND Maps1.ItemNumberLeft < Maps11.ItemNumberLeft
			|
			|	UNION ALL
			|
			|	SELECT
			|		Maps1.ItemNumberLeft,
			|		Maps1.ItemNumberRight,
			|		1
			|	FROM
			|		(SELECT
			|			Maps1.ItemNumberRight AS ItemNumberRight,
			|			MAX(Maps1.Weight) AS Weight
			|		FROM
			|			Maps1 AS Maps1
			|		GROUP BY
			|			Maps1.ItemNumberRight
			|		HAVING
			|			COUNT(DISTINCT Maps1.ItemNumberLeft) > 1) AS Duplicates
			|			LEFT JOIN Maps1 AS Maps1
			|			ON Duplicates.ItemNumberRight = Maps1.ItemNumberRight
			|			AND Duplicates.Weight > Maps1.Weight) AS AllConflicts
			|GROUP BY
			|	AllConflicts.ItemNumberLeft,
			|	AllConflicts.ItemNumberRight
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	Maps1.ItemNumberLeft AS ItemNumberLeft,
			|	Maps1.ItemNumberRight AS ItemNumberRight,
			|	Maps1.Weight AS Weight,
			|	ISNULL(ConflictsFound.NumberOfConflicts, 0) AS NumberOfConflicts
			|INTO ComplianceWithConflicts
			|FROM
			|	Maps1 AS Maps1
			|		LEFT JOIN ConflictsFound AS ConflictsFound
			|		ON Maps1.ItemNumberLeft = ConflictsFound.ItemNumberLeft
			|		AND Maps1.ItemNumberRight = ConflictsFound.ItemNumberRight
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP Maps1
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ComplianceWithConflicts.ItemNumberLeft AS ItemNumberLeft,
			|	ComplianceWithConflicts.ItemNumberRight AS ItemNumberRight,
			|	ComplianceWithConflicts.Weight AS Weight,
			|	ComplianceWithConflicts.NumberOfConflicts AS NumberOfConflicts
			|INTO ReplaceableMatches
			|FROM
			|	(SELECT
			|		MAX(ComplianceWithConflicts.NumberOfConflicts) AS NumberOfConflicts
			|	FROM
			|		ComplianceWithConflicts AS ComplianceWithConflicts) AS MaximumNumberOfConflicts
			|		LEFT JOIN ComplianceWithConflicts AS ComplianceWithConflicts
			|		ON MaximumNumberOfConflicts.NumberOfConflicts <> 0
			|		AND ComplianceWithConflicts.NumberOfConflicts = MaximumNumberOfConflicts.NumberOfConflicts
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ComplianceWithConflicts.ItemNumberLeft AS ItemNumberLeft,
			|	ComplianceWithConflicts.ItemNumberRight AS KeyElementNumberRight,
			|	ComplianceWithConflicts.NumberOfConflicts AS NumberOfConflicts,
			|	ReplacementOptions.ItemNumberRight AS ItemNumberRight,
			|	ReplacementOptions.Weight AS Weight
			|INTO MatchingOptionsForReplacement
			|FROM
			|	ReplaceableMatches AS ComplianceWithConflicts
			|		LEFT JOIN WeightedMatches AS ReplacementOptions
			|		ON ComplianceWithConflicts.ItemNumberLeft = ReplacementOptions.ItemNumberLeft
			|		AND ComplianceWithConflicts.Weight > ReplacementOptions.Weight
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MatchingOptionsForReplacement.ItemNumberLeft AS ItemNumberLeft,
			|	MatchingOptionsForReplacement.ItemNumberRight AS ItemNumberRight,
			|	1 AS NumberOfConflicts
			|INTO FoundConflictsOfOptions
			|FROM
			|	MatchingOptionsForReplacement AS MatchingOptionsForReplacement
			|		INNER JOIN ComplianceWithConflicts AS ComplianceWithConflicts
			|		ON MatchingOptionsForReplacement.ItemNumberRight < ComplianceWithConflicts.ItemNumberRight
			|		AND MatchingOptionsForReplacement.ItemNumberLeft > ComplianceWithConflicts.ItemNumberLeft
			|
			|UNION ALL
			|
			|SELECT
			|	MatchingOptionsForReplacement.ItemNumberLeft,
			|	MatchingOptionsForReplacement.ItemNumberRight,
			|	1
			|FROM
			|	MatchingOptionsForReplacement AS MatchingOptionsForReplacement
			|		INNER JOIN ComplianceWithConflicts AS ComplianceWithConflicts
			|		ON MatchingOptionsForReplacement.ItemNumberRight > ComplianceWithConflicts.ItemNumberRight
			|		AND MatchingOptionsForReplacement.ItemNumberLeft < ComplianceWithConflicts.ItemNumberLeft
			|
			|UNION ALL
			|
			|SELECT
			|	ComplianceWithConflicts.ItemNumberLeft,
			|	ComplianceWithConflicts.ItemNumberRight,
			|	1
			|FROM
			|	(SELECT
			|		MatchingOptionsForReplacement.ItemNumberRight AS ItemNumberRight,
			|		MAX(ComplianceWithConflicts.Weight) AS Weight
			|	FROM
			|		MatchingOptionsForReplacement AS MatchingOptionsForReplacement
			|			LEFT JOIN ComplianceWithConflicts AS ComplianceWithConflicts
			|			ON MatchingOptionsForReplacement.ItemNumberRight = ComplianceWithConflicts.ItemNumberRight
			|	GROUP BY
			|		MatchingOptionsForReplacement.ItemNumberRight) AS Duplicates
			|		LEFT JOIN ComplianceWithConflicts AS ComplianceWithConflicts
			|		ON Duplicates.ItemNumberRight = ComplianceWithConflicts.ItemNumberRight
			|		AND Duplicates.Weight > ComplianceWithConflicts.Weight
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MatchingOptionsForReplacement.ItemNumberLeft AS ItemNumberLeft,
			|	MatchingOptionsForReplacement.KeyElementNumberRight AS KeyElementNumberRight,
			|	MatchingOptionsForReplacement.ItemNumberRight AS ItemNumberRight,
			|	MatchingOptionsForReplacement.Weight AS Weight,
			|	ISNULL(SUM(Conflicts1.NumberOfConflicts), 0) AS NumberOfConflicts
			|INTO MatchingOptionsForReplacementsWithConflicts
			|FROM
			|	MatchingOptionsForReplacement AS MatchingOptionsForReplacement
			|		LEFT JOIN FoundConflictsOfOptions AS Conflicts1
			|		ON MatchingOptionsForReplacement.ItemNumberLeft = Conflicts1.ItemNumberLeft
			|		AND MatchingOptionsForReplacement.ItemNumberRight = Conflicts1.ItemNumberRight
			|GROUP BY
			|	MatchingOptionsForReplacement.ItemNumberLeft,
			|	MatchingOptionsForReplacement.KeyElementNumberRight,
			|	MatchingOptionsForReplacement.ItemNumberRight,
			|	MatchingOptionsForReplacement.Weight,
			|	MatchingOptionsForReplacement.NumberOfConflicts
			|HAVING
			|	MatchingOptionsForReplacement.NumberOfConflicts > ISNULL(SUM(Conflicts1.NumberOfConflicts), 0)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	MatchingOptionsForReplacementsWithConflicts.ItemNumberLeft AS ItemNumberLeft,
			|	MAX(MatchingOptionsForReplacementsWithConflicts.Weight) AS Weight
			|INTO MaximumReplacementWeight
			|FROM
			|	MatchingOptionsForReplacementsWithConflicts AS MatchingOptionsForReplacementsWithConflicts
			|GROUP BY
			|	MatchingOptionsForReplacementsWithConflicts.ItemNumberLeft
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ReplaceableMatches.ItemNumberLeft AS ItemNumberLeft,
			|	ReplaceableMatches.ItemNumberRight AS KeyElementNumberRight,
			|	ISNULL(MatchingOptionsForReplacementsWithConflicts.ItemNumberRight, UNDEFINED) AS ItemNumberRight,
			|	MatchingOptionsForReplacementsWithConflicts.Weight AS Weight
			|INTO MatchesToReplace
			|FROM
			|	ReplaceableMatches AS ReplaceableMatches
			|		LEFT JOIN MaximumReplacementWeight AS MaximumReplacementWeight
			|		ON ReplaceableMatches.ItemNumberLeft = MaximumReplacementWeight.ItemNumberLeft
			|		LEFT JOIN MatchingOptionsForReplacementsWithConflicts AS MatchingOptionsForReplacementsWithConflicts
			|		ON MatchingOptionsForReplacementsWithConflicts.Weight = MaximumReplacementWeight.Weight
			|		AND MatchingOptionsForReplacementsWithConflicts.ItemNumberLeft = MaximumReplacementWeight.ItemNumberLeft
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ComplianceWithConflicts.ItemNumberLeft AS ItemNumberLeft,
			|	ISNULL(MatchesToReplace.ItemNumberRight, ComplianceWithConflicts.ItemNumberRight) AS
			|		ItemNumberRight,
			|	ISNULL(MatchesToReplace.Weight, ComplianceWithConflicts.Weight) AS Weight,
			|	ComplianceWithConflicts.NumberOfConflicts AS NumberOfConflicts
			|INTO Maps1
			|FROM
			|	ComplianceWithConflicts AS ComplianceWithConflicts
			|		LEFT JOIN MatchesToReplace AS MatchesToReplace
			|		ON ComplianceWithConflicts.ItemNumberLeft = MatchesToReplace.ItemNumberLeft
			|		AND ComplianceWithConflicts.ItemNumberRight = MatchesToReplace.KeyElementNumberRight
			|WHERE
			|	MatchesToReplace.ItemNumberRight IS NULL
			|	OR MatchesToReplace.ItemNumberRight <> UNDEFINED
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ISNULL(MAX(ComplianceWithConflicts.NumberOfConflicts), 0) AS NumberOfConflicts
			|FROM
			|	ComplianceWithConflicts AS ComplianceWithConflicts";
			
		Selection = Query.Execute().Select();
		Selection.Next();
		LevelOfConflicts = Selection.NumberOfConflicts;
		
		TemporaryTablesToDelete = New Array;
		TemporaryTablesToDelete.Add("MatchesToReplace");
		TemporaryTablesToDelete.Add("MatchingOptionsForReplacementsWithConflicts");
		TemporaryTablesToDelete.Add("MatchingOptionsForReplacement");
		TemporaryTablesToDelete.Add("ComplianceWithConflicts");
		TemporaryTablesToDelete.Add("ReplaceableMatches");
		TemporaryTablesToDelete.Add("ConflictsFound");
		TemporaryTablesToDelete.Add("MaximumReplacementWeight");
		TemporaryTablesToDelete.Add("FoundConflictsOfOptions");
		
		DeleteTemporaryTables(Query, TemporaryTablesToDelete);

	EndDo;
	
	Query.Text = "SELECT
	               |	Maps1.ItemNumberLeft AS ItemNumberLeft,
	               |	Maps1.ItemNumberRight AS ItemNumberRight
	               |FROM
	               |	Maps1 AS Maps1";
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		If MatchResultLeft[Selection.ItemNumberLeft].Value = Undefined
			And MatchResultRight[Selection.ItemNumberRight].Value = Undefined Then
				MatchResultLeft[Selection.ItemNumberLeft].Value = Selection.ItemNumberRight;
				MatchResultRight[Selection.ItemNumberRight].Value = Selection.ItemNumberLeft;
		EndIf;
	EndDo;
	
	Result = New Array;
	Result.Add(MatchResultLeft);
	Result.Add(MatchResultRight);
	
	Return Result;

EndFunction

&AtServer
Function GetDataForComparison(SourceValueTable, ByRows)
	
	MaxRowSize = New StringQualifiers(100);
	
	Result = New ValueTable;
	Result.Columns.Add("Number",		New TypeDescription("Number"));
	Result.Columns.Add("Value",	New TypeDescription("String", , MaxRowSize));
	
	Boundary1 = ?(ByRows, SourceValueTable.Count(),
							SourceValueTable.Columns.Count()) - 1;
		
	Boundary2 = ?(ByRows, SourceValueTable.Columns.Count(),
							SourceValueTable.Count()) - 1;
		
	For Index1 = 0 To Boundary1 Do
		
		For IndexOf2 = 0 To Boundary2 Do
			
			NewRow = Result.Add();
			NewRow.Number = Index1+1;
			NewRow.Value = ?(ByRows, SourceValueTable[Index1][IndexOf2],
												SourceValueTable[IndexOf2][Index1]);
			
		EndDo;
		
	EndDo;

	Result.Columns.Add("Count", New TypeDescription("Number"));
	Result.FillValues(1, "Count");
	
	Result.GroupBy("Number, Value", "Count");
	
	Return Result;
		
EndFunction


&AtClient
Procedure ProcessAreaActivation(SourceSpreadDoc, DestinationSpreadDoc, MatchesSource, MatchesDestination)
	
	DisableOnActivateHandler = True;
	
	CurArea = SourceSpreadDoc.Item.CurrentArea;
	
	If CurArea.AreaType = SpreadsheetDocumentCellAreaType.Table Then
		
		SelectedArea = DestinationSpreadDoc.Area();
		
	Else
	
		If CurArea.Bottom < MatchesSource.Rows.Count() Then
			LineNumber = MatchesSource.Rows[CurArea.Bottom].Value;
		Else
			LineNumber = CurArea.Bottom 
							- MatchesSource.Rows.Count()
								+ MatchesDestination.Rows.Count();
		EndIf;
		
		If CurArea.Left < MatchesSource.Columns2.Count() Then
			ColumnNumber = MatchesSource.Columns2[CurArea.Left].Value;
		Else
			ColumnNumber = CurArea.Left
							- MatchesSource.Columns2.Count()
								+ MatchesDestination.Columns2.Count();
		EndIf;
		
		
		SelectedArea = Undefined;
		
		If CurArea.AreaType = SpreadsheetDocumentCellAreaType.Rectangle Then
					
			If LineNumber <> Undefined And ColumnNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(LineNumber, ColumnNumber);
			EndIf;
					
		ElsIf CurArea.AreaType = SpreadsheetDocumentCellAreaType.Rows Then
			
			If LineNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(LineNumber, 0, LineNumber, 0);
			EndIf;
			
		ElsIf CurArea.AreaType = SpreadsheetDocumentCellAreaType.Columns Then
			
			If ColumnNumber <> Undefined Then
				SelectedArea = DestinationSpreadDoc.Object.Area(0, ColumnNumber, 0, ColumnNumber);
			EndIf;
			
		Else		
			
			Return;
			
		EndIf;
		
	EndIf;
	
	DestinationSpreadDoc.Item.CurrentArea = SelectedArea;
	
	DisableOnActivateHandler = False;
	
EndProcedure

&AtClient
Procedure PreviousChange(FormItem, FormAttribute, DifferenceTable)
	
	Var IndexOf;
	
	CurCell = FormItem.CurrentArea;
	LineNumber = CurCell.Top;
	ColumnNumber = CurCell.Left;
	For Each CurRow In DifferenceTable Do
		If CurRow.LineNumber < LineNumber 
			Or CurRow.LineNumber = LineNumber And CurRow.ColumnNumber < ColumnNumber Then
			IndexOf = DifferenceTable.IndexOf(CurRow);
		ElsIf CurRow.LineNumber >= LineNumber And CurRow.ColumnNumber > ColumnNumber Then
			Break;
		EndIf;
	EndDo;
	
	If IndexOf <> Undefined Then
		DifferenceRow = DifferenceTable[IndexOf];
		LineNumber = DifferenceRow.LineNumber;
		ColumnNumber = DifferenceRow.ColumnNumber;
		FormItem.CurrentArea = FormAttribute.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
	EndIf;
	
	
EndProcedure

&AtClient
Procedure NextChange(FormItem, FormAttribute, DifferenceTable)
	
	Var IndexOf;
	
	CurCell = FormItem.CurrentArea;
	LineNumber = CurCell.Top;
	ColumnNumber = CurCell.Left;
	For Each CurRow In DifferenceTable Do
		If CurRow.LineNumber = LineNumber And CurRow.ColumnNumber > ColumnNumber 
			Or CurRow.LineNumber > LineNumber Then
			IndexOf = DifferenceTable.IndexOf(CurRow);
			Break;
		EndIf;
	EndDo;
	
	If IndexOf <> Undefined Then
		DifferenceRow = DifferenceTable[IndexOf];
		LineNumber = DifferenceRow.LineNumber;
		ColumnNumber = DifferenceRow.ColumnNumber;
		FormItem.CurrentArea = FormAttribute.Area(LineNumber, ColumnNumber, LineNumber, ColumnNumber);
	EndIf;

EndProcedure

&AtServer
Function PrepareSpreadsheetDocument(SpreadsheetDocument)
	
	If TypeOf(SpreadsheetDocument) = Type("SpreadsheetDocument") Then
		Return SpreadsheetDocument;
	EndIf;
	
	BinaryData = GetFromTempStorage(SpreadsheetDocument); // BinaryData - 
	TempFileName = GetTempFileName("mxl");
	BinaryData.Write(TempFileName);
	
	Result = New SpreadsheetDocument;
	Result.Read(TempFileName);
	
	DeleteFiles(TempFileName);
	
	Return Result;

EndFunction

&AtServer
Procedure DeleteTemporaryTables(Query, Tables)
	Query.Text = "DROP " + StrConcat(Tables, "; DROP ");
	Query.Execute();
EndProcedure

#EndRegion