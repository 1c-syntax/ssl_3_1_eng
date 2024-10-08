﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

// 
// 
//
// Returns:
//  String - 
//
Function AllUsersGroupID()
	
	Return "515b9805-054f-424e-816e-87afebdac3b6";
	
EndFunction

// Parameters:
//  GroupName - String - 
//
// Returns:
//  CatalogRef.UserGroups
//  
//
Function StandardUsersGroup(GroupName) Export
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	
	If GroupName = "AllExternalUsers" Then
		GroupID = Catalogs.ExternalUsersGroups.AllExternalUsersGroupID();
		FullCatalogName = "Catalog.ExternalUsersGroups";
		CatalogManager = Catalogs.ExternalUsersGroups;
		GroupDescription = NStr("en = 'All external users';", Common.DefaultLanguageCode());
		
	ElsIf GroupName = "AllUsers" Then
		GroupID = AllUsersGroupID();
		FullCatalogName = "Catalog.UserGroups";
		CatalogManager = Catalogs.UserGroups;
		GroupDescription = NStr("en = 'All users';", Common.DefaultLanguageCode());
	Else
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'The standard group has unknown name ""%1"".';"), GroupName);
		Raise ErrorText;
	EndIf;
	
	Query = New Query;
	Query.SetParameter("PredefinedDataName", GroupName);
	Query.Text =
	"SELECT
	|	UserGroups.Ref AS Ref
	|FROM
	|	&Table AS UserGroups
	|WHERE
	|	UserGroups.PredefinedDataName = &PredefinedDataName
	|
	|ORDER BY
	|	Ref";
	Query.Text = StrReplace(Query.Text, "&Table", FullCatalogName);
	
	Selection = Query.Execute().Select();
	If Selection.Count() = 1 And Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Query.Text =
	"SELECT
	|	UserGroups.Ref AS Ref,
	|	UserGroups.Description AS Description
	|FROM
	|	&Table AS UserGroups
	|WHERE
	|	UserGroups.PredefinedDataName = &PredefinedDataName
	|
	|ORDER BY
	|	Ref";
	Query.Text = StrReplace(Query.Text, "&Table", FullCatalogName);
	
	Block = New DataLock;
	Block.Add(FullCatalogName);
	
	BeginTransaction();
	Try
		Block.Lock();
		Selection = Query.Execute().Select();
		
		RefToNew = CatalogManager.GetRef(
			New UUID(GroupID));
		
		If Selection.Count() = 1 And Selection.Next() Then
			GroupObject = Selection.Ref.GetObject();
			
		ElsIf Selection.Count() > 1 Then
			GroupObject = GroupFromPredefinedItemDuplicates(Selection, GroupDescription, RefToNew);
		Else
			GroupObject = RefToNew.GetObject();
			If GroupObject = Undefined Then
				GroupByDescription = GroupByDescription(GroupDescription, FullCatalogName);
				If ValueIsFilled(GroupByDescription) Then
					GroupObject = GroupByDescription.GetObject();
				EndIf;
			EndIf;
			If GroupObject = Undefined Then
				GroupObject = CatalogManager.CreateItem();
				GroupObject.SetNewObjectRef(RefToNew);
			EndIf;
		EndIf;
		If GroupObject.PredefinedDataName <> GroupName Then
			GroupObject.PredefinedDataName = GroupName;
		EndIf;
		If GroupObject.Description <> GroupDescription Then
			GroupObject.Description = GroupDescription;
		EndIf;
		If ValueIsFilled(GroupObject.Content) Then
			GroupObject.Content.Clear();
		EndIf;
		If ValueIsFilled(GroupObject.Comment) Then
			GroupObject.Comment = "";
		EndIf;
		If GroupObject.Modified() Then
			InfobaseUpdate.WriteObject(GroupObject);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	Return GroupObject.Ref;
	
EndFunction

// 
Function GroupFromPredefinedItemDuplicates(Selection, GroupDescription, RefToNew)
	
	GroupInOrder = Undefined;
	GroupByRefToNew = Undefined;
	GroupByDescription = Undefined;
	
	ObjectsToUnlink = New Map;
	
	While Selection.Next() Do
		ObjectsToUnlink.Insert(Selection.Ref, True);
		If GroupInOrder = Undefined Then
			GroupInOrder = Selection.Ref;
		EndIf;
		If Selection.Ref = RefToNew Then
			GroupByRefToNew = Selection.Ref;
		ElsIf Selection.Description = GroupDescription
		        And GroupByDescription = Undefined Then
			GroupByDescription = Selection.Ref;
		EndIf;
	EndDo;
	
	If GroupByRefToNew <> Undefined Then
		GroupObject = GroupByRefToNew.GetObject();
		ObjectsToUnlink.Delete(GroupByRefToNew);
		
	ElsIf GroupByDescription <> Undefined Then
		GroupObject = GroupByDescription.GetObject();
		ObjectsToUnlink.Delete(GroupByDescription);
	Else
		GroupObject = GroupInOrder.GetObject();
		ObjectsToUnlink.Delete(GroupInOrder);
	EndIf;
	
	For Each KeyAndValue In ObjectsToUnlink Do
		CurrentObject = KeyAndValue.Key.GetObject();
		CurrentObject.PredefinedDataName = "";
		InfobaseUpdate.WriteObject(CurrentObject);
	EndDo;
	
	Return GroupObject;
	
EndFunction

// 
Function GroupByDescription(Description, FullCatalogName)
	
	Query = New Query;
	Query.SetParameter("Description", Description);
	Query.Text =
	"SELECT TOP 1
	|	UserGroups.Ref AS Ref
	|FROM
	|	&Table AS UserGroups
	|WHERE
	|	UserGroups.Description = &Description
	|
	|ORDER BY
	|	Ref";
	Query.Text = StrReplace(Query.Text, "&Table", FullCatalogName);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	EndIf;
	
	Return Undefined;
	
EndFunction

// See also updating the information base undefined.customizingmachine infillingelements
// 
// Parameters:
//  Settings - See InfobaseUpdateOverridable.OnSetUpInitialItemsFilling.Settings
//
Procedure OnSetUpInitialItemsFilling(Settings) Export
	
	Settings.OnInitialItemFilling = False;
	
EndProcedure

// See also updating the information base undefined.At firstfillingelements
// 
// Parameters:
//   LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//   Items - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//   TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export

	Item = Items.Add();
	Item.PredefinedDataName = "AllUsers";
	Item.Description = NStr("en = 'All users';", Common.DefaultLanguageCode());
	
EndProcedure

#EndRegion


#EndIf
