﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Internal

// This function determines whether measurements should be performed.
//
// Returns:
//  Boolean - 
//
Function RunPerformanceMeasurements() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Return Constants.RunPerformanceMeasurements.Get();
	
EndFunction

#EndRegion
