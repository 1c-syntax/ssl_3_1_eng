﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Private

// 
// 
//
// 
// 
//
// 
// 
//
// Parameters:
//  EventsForEventLog - See EventLog.WriteEventsToEventLog
//
Procedure WriteEventsToEventLog(EventsForEventLog) Export
	
	EventLog.WriteEventsToEventLog(EventsForEventLog);
	
EndProcedure

#EndRegion
