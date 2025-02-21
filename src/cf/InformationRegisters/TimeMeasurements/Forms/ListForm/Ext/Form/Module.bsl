﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	CurrentSessionDate = CurrentSessionDate();
	TimeZoneAdjustment = CurrentSessionDate - ToUniversalTime(CurrentSessionDate);
	List.Parameters.SetParameterValue("TimeZoneAdjustment", TimeZoneAdjustment);
	FieldArray = New Array;
	FieldArray.Add("MeasurementStartDateLocal");
	List.SetRestrictionsForUseInGroup(FieldArray);
	List.SetRestrictionsForUseInFilter(FieldArray);
	List.SetRestrictionsForUseInOrder(FieldArray);
EndProcedure

#EndRegion