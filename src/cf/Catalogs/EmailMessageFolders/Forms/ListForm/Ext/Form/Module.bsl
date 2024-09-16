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
	
	If Parameters.Filter.Property("Owner") Then
		
		If Not Interactions.UserIsResponsibleForMaintainingFolders(Parameters.Filter.Owner) Then
			
			ReadOnly = True;
			
		EndIf;
		
	Else
		
		Cancel = True;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Owner", Catalogs.EmailAccounts.EmptyRef(),
		DataCompositionComparisonType.Equal, , False);
EndProcedure

#EndRegion
