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
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "IsFolder", True,
		DataCompositionComparisonType.Equal, , ,
		DataCompositionSettingsItemViewMode.Normal);
		
	// 
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		ModuleObjectsVersioning.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.ObjectsVersioning	
		
EndProcedure

#EndRegion
