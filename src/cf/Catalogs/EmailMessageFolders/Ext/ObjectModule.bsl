﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	IsOwnerMarkedForDeletion = Common.ObjectAttributeValue(Owner, "DeletionMark");
	
	If IsOwnerMarkedForDeletion = Undefined
		Or IsOwnerMarkedForDeletion Then
		PredefinedFolder = False;
		Return;
	EndIf;

	If Not Interactions.UserIsResponsibleForMaintainingFolders(Owner) Then
		Common.MessageToUser(
			NStr("en = 'The operation is available only to the user responsible for managing the account''s folders.';"),
			Ref,,,Cancel);
	ElsIf PredefinedFolder And (Not Parent.IsEmpty()) Then
		Common.MessageToUser(
			NStr("en = 'Cannot move a predefined folder to another folder.';"),
			Ref,,,Cancel);
	EndIf;
	
	AdditionalProperties.Insert("Parent", Common.ObjectAttributeValue(Ref, "Parent"));
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	PredefinedFolder = False;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("Parent") And Parent <> AdditionalProperties.Parent Then
		If Not AdditionalProperties.Property("ParentChangeProcessed") Then
			Interactions.SetFolderParent(Ref,Parent,True)
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf