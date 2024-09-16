///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

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