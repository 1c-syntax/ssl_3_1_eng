﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// Parameters:
//   List - DynamicList
//   FilterValue - Boolean
//
Procedure SetFilterByDeletionMark(List, FilterValue) Export
	CommonClientServer.SetDynamicListFilterItem(List, "DeletionMark", False,,,
		FilterValue);
EndProcedure

#EndRegion