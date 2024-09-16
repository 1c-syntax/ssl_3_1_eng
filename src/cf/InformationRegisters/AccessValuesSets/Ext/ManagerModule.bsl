///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// The procedure updates the register cache details based on the result of changing the composition
// of value types and access value groups.
//
Procedure UpdateAuxiliaryRegisterDataByConfigurationChanges1() Export
	
	SetPrivilegedMode(True);
	
	If Constants.LimitAccessAtRecordLevel.Get() Then
		AccessManagementInternal.SetDataFillingForAccessRestriction(True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// The procedure updates the register data when the auxiliary data is fully updated.
//
// Parameters:
//  HasChanges - Boolean -  (return value) - if a record was made,
//                  it is set to True, otherwise it is not changed.
//
Procedure UpdateRegisterData(HasChanges = Undefined) Export
	
	AccessManagementInternal.CheckWhetherTheMetadataIsUpToDate();
	
	DataVolume = 1;
	While DataVolume > 0 Do
		DataVolume = 0;
		AccessManagementInternal.DataFillingForAccessRestriction(DataVolume, True, HasChanges);
	EndDo;
	
	ObjectsTypes = AccessManagementInternalCached.ObjectsTypesInSubscriptionsToEvents(
		"WriteAccessValuesSets");
	
	For Each TypeDetails In ObjectsTypes Do
		Type = TypeDetails.Key;
		
		If Type = Type("String") Then
			Continue;
		EndIf;
		
		Selection = Common.ObjectManagerByFullName(Metadata.FindByType(Type).FullName()).Select();
		
		While Selection.Next() Do
			AccessManagementInternal.UpdateAccessValuesSets(Selection.Ref, HasChanges);
		EndDo;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf
