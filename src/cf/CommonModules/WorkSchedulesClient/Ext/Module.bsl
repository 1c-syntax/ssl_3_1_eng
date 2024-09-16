///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// The procedure shifts the newly edited row in the collection 
// so that the rows in the collection remain ordered.
//
// Parameters:
//  RowsCollection - Array
//                 - FormDataCollection
//                 - ValueTable
//  OrderField -  
//		
//  CurrentRow - 
//
Procedure RestoreCollectionRowOrderAfterEditing(RowsCollection, OrderField, CurrentRow) Export
	
	If RowsCollection.Count() < 2 Then
		Return;
	EndIf;
	
	If TypeOf(CurrentRow[OrderField]) <> Type("Date") 
		And Not ValueIsFilled(CurrentRow[OrderField]) Then
		Return;
	EndIf;
	
	SourceIndex = RowsCollection.IndexOf(CurrentRow);
	IndexResult = SourceIndex;
	
	// 
	Direction = 0;
	If SourceIndex = 0 Then
		// Down
		Direction = 1;
	EndIf;
	If SourceIndex = RowsCollection.Count() - 1 Then
		// Up
		Direction = -1;
	EndIf;
	
	If Direction = 0 Then
		If RowsCollection[SourceIndex][OrderField] > RowsCollection[IndexResult + 1][OrderField] Then
			// Down
			Direction = 1;
		EndIf;
		If RowsCollection[SourceIndex][OrderField] < RowsCollection[IndexResult - 1][OrderField] Then
			// Up
			Direction = -1;
		EndIf;
	EndIf;
	
	If Direction = 0 Then
		Return;
	EndIf;
	
	If Direction = 1 Then
		// 
		While IndexResult < RowsCollection.Count() - 1 
			And RowsCollection[SourceIndex][OrderField] > RowsCollection[IndexResult + 1][OrderField] Do
			IndexResult = IndexResult + 1;
		EndDo;
	Else
		// 
		While IndexResult > 0 
			And RowsCollection[SourceIndex][OrderField] < RowsCollection[IndexResult - 1][OrderField] Do
			IndexResult = IndexResult - 1;
		EndDo;
	EndIf;
	
	RowsCollection.Move(SourceIndex, IndexResult - SourceIndex);
	
EndProcedure

// Re-creates a fixed match by inserting the specified value into it.
//
Procedure InsertIntoFixedMap(FixedMap, Var_Key, Value) Export
	
	Map = New Map(FixedMap);
	Map.Insert(Var_Key, Value);
	FixedMap = New FixedMap(Map);
	
EndProcedure

// Removes the value for the specified key from the fixed match.
//
Procedure DeleteFromFixedMap(FixedMap, Var_Key) Export
	
	Map = New Map(FixedMap);
	Map.Delete(Var_Key);
	FixedMap = New FixedMap(Map);
	
EndProcedure

#EndRegion
