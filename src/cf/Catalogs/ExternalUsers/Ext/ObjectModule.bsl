///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

// 
Var IsNew, PreviousAuthorizationObject;
Var IBUserProcessingParameters; // 

#EndRegion

// 
//
// 
//
// 
//
// 

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	// 
	UsersInternal.UserObjectBeforeWrite(ThisObject, IBUserProcessingParameters);
	// 
	
	// 
	If Common.FileInfobase() Then
		UsersInternal.LockRegistersBeforeWritingToFileInformationSystem(False);
	EndIf;
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsNew = IsNew();
	
	If Not ValueIsFilled(AuthorizationObject) Then
		ErrorText = NStr("en = 'No authorization object is set for the external user.';");
		Raise ErrorText;
	Else
		ErrorText = "";
		If UsersInternal.AuthorizationObjectIsInUse(
		         AuthorizationObject, Ref, , , ErrorText) Then
			Raise ErrorText;
		EndIf;
	EndIf;
	
	// 
	If IsNew Then
		PreviousAuthorizationObject = Null;
	Else
		PreviousAuthorizationObject = Common.ObjectAttributeValue(
			Ref, "AuthorizationObject");
		
		If ValueIsFilled(PreviousAuthorizationObject)
		   And PreviousAuthorizationObject <> AuthorizationObject Then
			
			ErrorText = NStr("en = 'Cannot change a previously specified authorization object.';");
			Raise ErrorText;
		EndIf;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	// 
	If DataExchange.Load And IBUserProcessingParameters <> Undefined Then
		UsersInternal.EndIBUserProcessing(
			ThisObject, IBUserProcessingParameters);
	EndIf;
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// 
	If AdditionalProperties.Property("NewExternalUserGroup")
	   And ValueIsFilled(AdditionalProperties.NewExternalUserGroup) Then
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.ExternalUsersGroups");
		LockItem.SetValue("Ref", AdditionalProperties.NewExternalUserGroup);
		Block.Lock();
		
		GroupObject1 = AdditionalProperties.NewExternalUserGroup.GetObject(); // CatalogObject.ExternalUsersGroups
		GroupObject1.Content.Add().ExternalUser = Ref;
		GroupObject1.Write();
	EndIf;
	
	// 
	// 
	ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
	UsersInternal.UpdateUserGroupCompositionUsage(Ref, ChangesInComposition);
	UsersInternal.UpdateAllUsersGroupComposition(Ref, ChangesInComposition);
	UsersInternal.UpdateGroupCompositionsByAuthorizationObjectType(Undefined,
		Ref, ChangesInComposition);
	
	UsersInternal.EndIBUserProcessing(ThisObject,
		IBUserProcessingParameters);
	
	UsersInternal.AfterUserGroupsUpdate(ChangesInComposition);
	
	If PreviousAuthorizationObject <> AuthorizationObject
	   And Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		
		AuthorizationObjects = New Array;
		If PreviousAuthorizationObject <> Null Then
			AuthorizationObjects.Add(PreviousAuthorizationObject);
		EndIf;
		AuthorizationObjects.Add(AuthorizationObject);
		ModuleAccessManagementInternal = Common.CommonModule("AccessManagementInternal");
		ModuleAccessManagementInternal.AfterChangeExternalUserAuthorizationObject(AuthorizationObjects);
	EndIf;
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	// 
	UsersInternal.UserObjectBeforeDelete(ThisObject);
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	UsersInternal.UpdateGroupsCompositionBeforeDeleteUserOrGroup(Ref);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	AdditionalProperties.Insert("CopyingValue", CopiedObject.Ref);
	
	IBUserID = Undefined;
	ServiceUserID = Undefined;
	Prepared = False;
	
	Comment = "";
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf