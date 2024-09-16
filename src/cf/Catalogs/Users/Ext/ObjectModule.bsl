///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#If Not MobileStandaloneServer Then

#Region Variables

// 
Var IsNew;
Var IBUserProcessingParameters; // 

#EndRegion

// 
//
// 
//
// 
//   
//      
//      
//      
//      
//      
//      
//
//   
//                            
//                            
//                            
//                          
//                            
//                            
//                            
//                            
//
//   
//                                  
//                                        
//
//   
//   
//      
//      
// 
//   
//      
//      
//      
//
//      
//      
//      
//      
//
//   
//   
//
//   
//   
//      
 //         
//      
//          
//   
//
//   
//
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
	
	If AdditionalProperties.Property("NewUserGroup")
		And ValueIsFilled(AdditionalProperties.NewUserGroup) Then
		
		Block = New DataLock;
		LockItem = Block.Add("Catalog.UserGroups");
		LockItem.SetValue("Ref", AdditionalProperties.NewUserGroup);
		Block.Lock();
		
		GroupObject1 = AdditionalProperties.NewUserGroup.GetObject(); // CatalogObject.UserGroups
		GroupObject1.Content.Add().User = Ref;
		GroupObject1.Write();
	EndIf;
	
	// 
	ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
	UsersInternal.UpdateUserGroupCompositionUsage(Ref, ChangesInComposition);
	UsersInternal.UpdateAllUsersGroupComposition(Ref, ChangesInComposition);
	
	UsersInternal.EndIBUserProcessing(ThisObject,
		IBUserProcessingParameters);
	
	UsersInternal.AfterUserGroupsUpdate(ChangesInComposition);
	
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
	
	Properties = New Structure("ContactInformation");
	FillPropertyValues(Properties, ThisObject);
	If Properties.ContactInformation <> Undefined Then
		Properties.ContactInformation.Clear();
	EndIf;
	
	Comment = "";
	
EndProcedure

#EndRegion

#EndIf

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf