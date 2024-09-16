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
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		FilterElement = Parameters.Filter.Owner;
		Parameters.Filter.Delete("Owner");
	Else
		FilterElement = Users.AuthorizedUser();
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Owner",
		FilterElement,
		DataCompositionComparisonType.Equal);
EndProcedure

#EndRegion
