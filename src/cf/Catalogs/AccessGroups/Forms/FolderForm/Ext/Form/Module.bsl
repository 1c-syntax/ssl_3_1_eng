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
	
	If Not AccessRight("Update", Metadata.Catalogs.AccessGroups)
	     
	 Or AccessParameters("Update", Metadata.Catalogs.AccessGroups,
	         "Ref").RestrictionByCondition Then
		
		ReadOnly = True;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ReadOnly = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If CurrentObject.Ref = Catalogs.AccessGroups.PersonalAccessGroupsParent(True) Then
		ReadOnly = True;
	EndIf;
	
	// 
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// End StandardSubsystems.AccessManagement

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	PersonalAccessGroupsDescription = Undefined;
	
	PersonalAccessGroupsParent = Catalogs.AccessGroups.PersonalAccessGroupsParent(
		True, PersonalAccessGroupsDescription);
	
	If Object.Ref <> PersonalAccessGroupsParent
	   And Object.Description = PersonalAccessGroupsDescription Then
		
		Common.MessageToUser(
			NStr("en = 'The description is reserved.';"),
			,
			"Object.Description",
			,
			Cancel);
	EndIf;
	
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
