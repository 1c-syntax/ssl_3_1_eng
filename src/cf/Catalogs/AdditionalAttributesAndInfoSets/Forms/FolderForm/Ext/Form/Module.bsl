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
	
	ReadOnly = True;
	
	SetPropertiesTypes = PropertyManagerInternal.SetPropertiesTypes(Object.Ref);
	UseAddlAttributes = SetPropertiesTypes.AdditionalAttributes;
	UseAddlInfo  = SetPropertiesTypes.AdditionalInfo;
	
	If UseAddlAttributes And UseAddlInfo Then
		Title = Object.Description + " " + NStr("en = '(Group of additional attribute and information record sets)';")
		
	ElsIf UseAddlAttributes Then
		Title = Object.Description + " " + NStr("en = '(Group of additional attribute sets)';")
		
	ElsIf UseAddlInfo Then
		Title = Object.Description + " " + NStr("en = '(Group of additional information records sets)';")
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// 
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// 
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

#EndRegion
