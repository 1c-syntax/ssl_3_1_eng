///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// 
// 
//
Function UpdateInfobase(ExecuteDeferredHandlers1 = False) Export
	
	StartDate = CurrentSessionDate();
	Result = InfobaseUpdate.UpdateInfobase(ExecuteDeferredHandlers1);
	EndDate = CurrentSessionDate();
	InfobaseUpdateInternal.WriteUpdateExecutionTime(StartDate, EndDate);
	
	Return Result;
	
EndFunction

#EndRegion
