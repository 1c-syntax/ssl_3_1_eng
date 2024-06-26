﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Internal

// Checks whether performance measurement is required.
//
// Returns:
//  Boolean - True if measurements must be made, False otherwise.
//
Function RunPerformanceMeasurements() Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Return Constants.RunPerformanceMeasurements.Get();
	
EndFunction

#EndRegion
