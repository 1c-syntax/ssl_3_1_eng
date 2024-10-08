﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

// 
Var IsNew, PreviousParent, PreviousAllAuthorizationObjects, PreviousRolesSet;

#EndRegion

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If AdditionalProperties.Property("VerifiedObjectAttributes") Then
		VerifiedObjectAttributes = AdditionalProperties.VerifiedObjectAttributes;
	Else
		VerifiedObjectAttributes = New Array;
	EndIf;
	
	Errors = Undefined;
	
	// 
	ErrorText = ParentCheckErrorText();
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.AddUserError(Errors,
			"Object.Parent", ErrorText, "");
	EndIf;
	
	// 
	VerifiedObjectAttributes.Add("Content.ExternalUser");
	
	// 
	ErrorText = PurposeCheckErrorText();
	If ValueIsFilled(ErrorText) Then
		CommonClientServer.AddUserError(Errors,
			"Object.Purpose", ErrorText, "");
	EndIf;
	VerifiedObjectAttributes.Add("Purpose");
	
	For Each CurrentRow In Content Do
		LineNumber = Content.IndexOf(CurrentRow);
		
		// 
		If Not ValueIsFilled(CurrentRow.ExternalUser) Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("en = 'The external user is not specified.';"),
				"Object.Content",
				LineNumber,
				NStr("en = 'The external user is not specified in line #%1.';"));
			Continue;
		EndIf;
		
		// 
		FoundValues = Content.FindRows(New Structure("ExternalUser", CurrentRow.ExternalUser));
		If FoundValues.Count() > 1 Then
			CommonClientServer.AddUserError(Errors,
				"Object.Content[%1].ExternalUser",
				NStr("en = 'Duplicate external user.';"),
				"Object.Content",
				LineNumber,
				NStr("en = 'Duplicate external user in line #%1.';"));
		EndIf;
	EndDo;
	
	CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, VerifiedObjectAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	// 
	If Common.FileInfobase() Then
		UsersInternal.LockRegistersBeforeWritingToFileInformationSystem(True);
	EndIf;
	// 
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not UsersInternal.CannotEditRoles() Then
		QueryResult = Common.ObjectAttributeValue(Ref, "Roles");
		If TypeOf(QueryResult) = Type("QueryResult") Then
			PreviousRolesSet = QueryResult.Unload();
		Else
			PreviousRolesSet = Roles.Unload(New Array);
		EndIf;
	EndIf;
	
	IsNew = IsNew();
	
	If Ref = ExternalUsers.AllExternalUsersGroup() Then
		FillPurposeWithAllExternalUsersTypes();
		AllAuthorizationObjects = False;
	EndIf;
	
	If Not IsNew Then
		PreviousValues1 = Common.ObjectAttributesValues(Ref,
			"Parent, AllAuthorizationObjects");
		PreviousAllAuthorizationObjects = PreviousValues1.AllAuthorizationObjects;
		PreviousParent              = PreviousValues1.Parent;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If UsersInternal.CannotEditRoles() Then
		IsExternalUserGroupRoleCompositionChanged = False;
	Else
		IsExternalUserGroupRoleCompositionChanged =
			UsersInternal.ColumnValueDifferences("Role",
				Roles.Unload(), PreviousRolesSet).Count() <> 0;
	EndIf;
	
	AllExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
	
	ErrorText = ParentCheckErrorText(AllExternalUsersGroup);
	If ValueIsFilled(ErrorText) Then
		Raise ErrorText;
	EndIf;
	
	If Ref = AllExternalUsersGroup Then
		If Not Parent.IsEmpty() Then
			ErrorText = NStr("en = 'The position of the ""All external users"" group cannot be changed. It is the root of the group tree.';");
			Raise ErrorText;
		EndIf;
		If Content.Count() > 0 Then
			ErrorText = NStr("en = 'Cannot add members to the ""All external users"" group. ';");
			Raise ErrorText;
		EndIf;
	Else
		ErrorText = PurposeCheckErrorText();
		If ValueIsFilled(ErrorText) Then
			Raise ErrorText;
		EndIf;
	EndIf;
	
	ChangesInComposition = UsersInternal.GroupsCompositionNewChanges();
	
	If Ref = AllExternalUsersGroup Then
		UsersInternal.UpdateAllUsersGroupComposition(
			Catalogs.ExternalUsers.EmptyRef(), ChangesInComposition);
		
	ElsIf AllAuthorizationObjects Then
		UsersInternal.UpdateGroupCompositionsByAuthorizationObjectType(Ref,
			Undefined, ChangesInComposition);
	Else
		If PreviousParent <> Parent Then
			UsersInternal.UpdateGroupsHierarchy(Ref, ChangesInComposition, False);
			
			If ValueIsFilled(PreviousParent) Then
				UsersInternal.UpdateHierarchicalUserGroupCompositions(PreviousParent,
					ChangesInComposition);
			EndIf;
		EndIf;
		
		UsersInternal.UpdateHierarchicalUserGroupCompositions(Ref,
			ChangesInComposition);
	EndIf;
	
	UsersInternal.AfterUserGroupsUpdate(ChangesInComposition);
	
	If IsExternalUserGroupRoleCompositionChanged Then
		UsersInternal.UpdateExternalUsersRoles(Ref);
	EndIf;
	
	SSLSubsystemsIntegration.AfterAddChangeUserOrGroup(Ref, IsNew);
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	UsersInternal.UpdateGroupsCompositionBeforeDeleteUserOrGroup(Ref);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillPurposeWithAllExternalUsersTypes()
	
	Purpose.Clear();
	
	BlankRefs = UsersInternalCached.BlankRefsOfAuthorizationObjectTypes();
	For Each EmptyRef In BlankRefs Do
		NewRow = Purpose.Add();
		NewRow.UsersType = EmptyRef;
	EndDo;
	
EndProcedure

Function ParentCheckErrorText(AllExternalUsersGroup = Undefined)
	
	If AllExternalUsersGroup = Undefined Then
		AllExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
	EndIf;
	
	If Parent = AllExternalUsersGroup Then
		Return NStr("en = 'Cannot set the ""All external users"" group as a parent.';");
	EndIf;
	
	If Ref = AllExternalUsersGroup Then
		If Not Parent.IsEmpty() Then
			Return NStr("en = 'Cannot move the ""All external users"" group.';");
		EndIf;
	Else
		If Parent = AllExternalUsersGroup Then
			Return NStr("en = 'Cannot add a subgroup to the ""All external users"" group. ';");
			
		ElsIf Common.ObjectAttributeValue(Parent, "AllAuthorizationObjects") = True Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot add a subgroup to group ""%1"" as
				           |it contains all external users of the specified types.';"), Parent);
		EndIf;
		
		If AllAuthorizationObjects And ValueIsFilled(Parent) Then
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot move group ""%1"" as
				           |it contains all external users of the specified types.';"), Ref);
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

Function PurposeCheckErrorText()
	
	// 
	If Purpose.Count() = 0 Then
		Return NStr("en = 'The type of group members is not specified.';");
	EndIf;
	
	// 
	If AllAuthorizationObjects Then
		
		// 
		AllExternalUsersGroup = ExternalUsers.AllExternalUsersGroup();
		AllExternalUsersPurpose = Common.ObjectAttributeValue(
			AllExternalUsersGroup, "Purpose").Unload().UnloadColumn("UsersType");
		PurposesArray = Purpose.UnloadColumn("UsersType");
		
		If CommonClientServer.ValueListsAreEqual(AllExternalUsersPurpose, PurposesArray) Then
			Return
				NStr("en = 'Cannot create a group having the same purpose
				           | as the predefined group ""All external users.""';");
		EndIf;
		
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("UsersTypes", Purpose.Unload());
		
		Query.Text =
		"SELECT
		|	UsersTypes.UsersType
		|INTO UsersTypes
		|FROM
		|	&UsersTypes AS UsersTypes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups.Purpose AS ExternalUsersGroups
		|WHERE
		|	TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				UsersTypes AS UsersTypes
		|			WHERE
		|				ExternalUsersGroups.Ref <> &Ref
		|				AND ExternalUsersGroups.Ref.AllAuthorizationObjects
		|				AND VALUETYPE(UsersTypes.UsersType) = VALUETYPE(ExternalUsersGroups.UsersType))";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
		
			Selection = QueryResult.Select();
			Selection.Next();
			
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'An existing group ""%1""
				           | includes all users of the specified types.';"),
				Selection.RefPresentation);
		EndIf;
	EndIf;
	
	// 
	// 
	If ValueIsFilled(Parent) Then
		
		ParentUsersType = Common.ObjectAttributeValue(
			Parent, "Purpose").Unload().UnloadColumn("UsersType");
		UsersType = Purpose.UnloadColumn("UsersType");
		
		For Each UserType In UsersType Do
			If ParentUsersType.Find(UserType) = Undefined Then
				Return StringFunctionsClientServer.SubstituteParametersToString(
					NStr("en = 'The group members type must be identical to the members type
					           |of the parent external user group ""%1.""';"), Parent);
			EndIf;
		EndDo;
	EndIf;
	
	// 
	// 
	If AllAuthorizationObjects
		And ValueIsFilled(Ref) Then
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.Text =
		"SELECT
		|	PRESENTATION(ExternalUsersGroups.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups AS ExternalUsersGroups
		|WHERE
		|	ExternalUsersGroups.Parent = &Ref";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			Return
				NStr("en = 'Cannot change the type of group 
				           | members as the group contains subgroups.';");
		EndIf;
	EndIf;
	
	// 
	// 
	If ValueIsFilled(Ref) Then
		
		Query = New Query;
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("UsersTypes", Purpose);
		Query.Text =
		"SELECT
		|	UsersTypes.UsersType AS UsersType
		|INTO UsersTypes
		|FROM
		|	&UsersTypes AS UsersTypes
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	PRESENTATION(ExternalUserGroupsAssignment.Ref) AS RefPresentation
		|FROM
		|	Catalog.ExternalUsersGroups.Purpose AS ExternalUserGroupsAssignment
		|WHERE
		|	ExternalUserGroupsAssignment.Ref.Parent = &Ref
		|	AND NOT TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					UsersTypes AS UsersTypes
		|				WHERE
		|					VALUETYPE(ExternalUserGroupsAssignment.UsersType) = VALUETYPE(UsersTypes.UsersType))";
		
		QueryResult = Query.Execute();
		If Not QueryResult.IsEmpty() Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			
			Return StringFunctionsClientServer.SubstituteParametersToString(
				NStr("en = 'Cannot change the type of group members
				           |as the group contains the subgroup ""%1"" with different member types.';"),
				Selection.RefPresentation);
		EndIf;
	EndIf;
	
	Return "";
	
EndFunction

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf