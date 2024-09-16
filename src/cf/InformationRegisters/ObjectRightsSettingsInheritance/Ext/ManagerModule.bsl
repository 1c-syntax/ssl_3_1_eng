///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Updates the hierarchy of owners of object rights settings.
// For example, the hierarchy of elements in the folder directory.
//
// Parameters:
//  RightsSettingsOwners - DefinedType.RightsSettingsOwner -  for example, a reference link.Folder
//                          files or another type by which the rights are configured directly.
//                        - Array - 
//                        - Undefined - 
//                        - DefinedType.RightsSettingsOwnerObject - 
//                          
//                          
//
//  HasChanges         - Boolean -  (return value) - if a record was made,
//                          it is set to True, otherwise it is not changed.
//
Procedure UpdateRegisterData(Val RightsSettingsOwners = Undefined, HasChanges = Undefined) Export
	
	If RightsSettingsOwners = Undefined Then
		AvailableRights = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
		
		Query = New Query;
		QueryText =
		"SELECT
		|	CurrentTable.Ref
		|FROM
		|	&CurrentTable AS CurrentTable";
		
		For Each KeyAndValue In AvailableRights.ByFullNames Do
			
			Query.Text = StrReplace(QueryText, "&CurrentTable", KeyAndValue.Key);
			// 
			Selection = Query.Execute().Select();
			
			While Selection.Next() Do
				// 
				UpdateOwnerParents(Selection.Ref, HasChanges);
			EndDo;
		EndDo;
		
	ElsIf TypeOf(RightsSettingsOwners) = Type("Array") Then
		
		For Each RightsSettingsOwner In RightsSettingsOwners Do
			// 
			UpdateOwnerParents(RightsSettingsOwner, HasChanges);
		EndDo;
	Else
		UpdateOwnerParents(RightsSettingsOwners, HasChanges);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Updates the parents of the owner of the object rights settings.
// For example, the directory of folder Files.
// 
// Parameters:
//  RightsSettingsOwner - DefinedType.RightsSettingsOwner -  for example, Spravochniki.Folders
//                          of files or other types for which rights are configured directly.
//                       - DefinedType.RightsSettingsOwnerObject - 
//                         
//                         
//
//  HasChanges        - Boolean -  (return value) - if a record was made,
//                         it is set to True, otherwise it is not changed.
//
//  UpdateHierarchy     - Boolean -  forces updates to the lower hierarchy,
//                         regardless of changes to the owner's parents.
//
//  ObjectsWithChanges  - Array -  for internal use only.
//
Procedure UpdateOwnerParents(RightsSettingsOwner, HasChanges = False, UpdateHierarchy = False, ObjectsWithChanges = Undefined) Export
	
	SetPrivilegedMode(True);
	
	AvailableRights = AccessManagementInternal.RightsForObjectsRightsSettingsAvailable();
	OwnerType = TypeOf(RightsSettingsOwner);
	
	ErrorTitle =
		NStr("en = 'An error occurred when updating the hierarchy of rights owners by Access Values.';")
		+ Chars.LF
		+ Chars.LF;
	
	If AvailableRights.ByTypes.Get(OwnerType) = Undefined Then
		Raise ErrorTitle + StringFunctionsClientServer.SubstituteParametersToString(
			NStr("en = 'No object rights settings are specified
			           |for the ""%1"" type.';"),
			String(OwnerType));
	EndIf;
	
	If AvailableRights.ByRefsTypes.Get(OwnerType) = Undefined Then
		Ref = UsersInternal.ObjectRef2(RightsSettingsOwner);
		Object = RightsSettingsOwner;
	Else
		Ref = RightsSettingsOwner;
		Object = Undefined;
	EndIf;
	
	Hierarchical = AvailableRights.HierarchicalTables.Get(OwnerType) <> Undefined;
	UpdateRequired = False;
	
	If Hierarchical Then
		ObjectParentProperties = ParentProperties(Ref);
		
		If Object <> Undefined Then
			// 
			If ObjectParentProperties.Ref <> Object.Parent Then
				UpdateRequired = True;
			EndIf;
			ObjectParentProperties.Ref      = Object.Parent;
			ObjectParentProperties.Inherit = SettingsInheritance(Object.Parent);
		Else
			UpdateRequired = True;
		EndIf;
	Else
		If Object = Undefined Then
			UpdateRequired = True;
		EndIf;
	EndIf;
	
	If Not UpdateRequired Then
		Return;
	EndIf;
	
	Block = New DataLock;
	Block.Add("InformationRegister.ObjectRightsSettingsInheritance");
	
	If Object = Undefined Then
		AdditionalProperties = Undefined;
	Else
		AdditionalProperties = New Structure("LeadingObjectBeforeWrite", Object);
	EndIf;
	
	BeginTransaction();
	Try
		Block.Lock();
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Object.Set(Ref);
		
		// 
		If Hierarchical Then
			NewRecords = ObjectParents(Ref, Ref, ObjectParentProperties);
		Else
			NewRecords = AccessManagementInternalCached.BlankRecordSetTable(
				Metadata.InformationRegisters.ObjectRightsSettingsInheritance.FullName()).Get(); // ValueTable
			
			NewRow = NewRecords.Add();
			NewRow.Object   = Ref;
			NewRow.Parent = Ref;
		EndIf;
		
		Data = New Structure;
		Data.Insert("RecordSet",           RecordSet);
		Data.Insert("NewRecords",            NewRecords);
		Data.Insert("AdditionalProperties", AdditionalProperties);
		
		HasCurrentChanges = False;
		AccessManagementInternal.UpdateRecordSet(Data, HasCurrentChanges);
		
		If HasCurrentChanges Then
			HasChanges = True;
			
			If ObjectsWithChanges <> Undefined Then
				ObjectsWithChanges.Add(Ref);
			EndIf;
		EndIf;
		
		If Hierarchical And (HasCurrentChanges Or UpdateHierarchy) Then
			UpdateOwnerHierarchy(Ref, HasChanges, ObjectsWithChanges);
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If ObjectsWithChanges <> Undefined Then
		ObjectsWithChanges = CommonClientServer.CollapseArray(ObjectsWithChanges);
	EndIf;
	
EndProcedure

// Fills the Recordset with the object's parents, including itself as the parent.
//
// Parameters:
//  Ref                  - DefinedType.RightsSettingsOwner -  a link in the hierarchy of a reference Object or a reference Object.
//  ObjectRef2           - DefinedType.RightsSettingsOwner
//                          - Undefined - 
//  ObjectParentProperties - Structure:
//                            * Ref      - DefinedType.RightsSettingsOwner -  a reference to the parent of the source object,
//                                            which may differ from the parent
//                                            recorded in the database.
//                            * Inherit - Boolean -  inheritance of settings by the parent.
//  GetInheritance    - Boolean
//
// Returns:
//  InformationRegisterRecordSet.ObjectRightsSettingsInheritance
//
Function ObjectParents(Ref, ObjectRef2 = Undefined, ObjectParentProperties = "", GetInheritance = True) Export
	
	NewRecords = AccessManagementInternalCached.BlankRecordSetTable(
		Metadata.InformationRegisters.ObjectRightsSettingsInheritance.FullName()).Get(); // ValueTable
	
	// 
	If GetInheritance Then
		Inherit = SettingsInheritance(Ref);
	Else
		Inherit = True;
		NewRecords.Columns.Add("Level", New TypeDescription("Number"));
	EndIf;
	
	String = NewRecords.Add();
	String.Object      = Ref;
	String.Parent    = Ref;
	String.Inherit = Inherit;
	
	If Not Inherit Then
		Return NewRecords;
	EndIf;
	
	If Ref = ObjectRef2 Then
		CurrentParentProperties = ObjectParentProperties;
	Else
		CurrentParentProperties = ParentProperties(Ref);
	EndIf;
	
	While ValueIsFilled(CurrentParentProperties.Ref) Do
	
		String = NewRecords.Add();
		String.Object   = Ref;
		String.Parent = CurrentParentProperties.Ref;
		String.UsageLevel = 1;
		
		If Not GetInheritance Then
			String.Level = String.Parent.Level();
		EndIf;
		
		If Not CurrentParentProperties.Inherit Then
			Break;
		EndIf;
		
		// 
		CurrentParentProperties = ParentProperties(CurrentParentProperties.Ref);
	EndDo;
	
	Return NewRecords;
	
EndFunction

Function SettingsInheritance(Ref) Export
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	
	Query.Text =
	"SELECT
	|	SettingsInheritance.Inherit
	|FROM
	|	InformationRegister.ObjectRightsSettingsInheritance AS SettingsInheritance
	|WHERE
	|	SettingsInheritance.Object = &Ref
	|	AND SettingsInheritance.Parent = &Ref";
	
	Selection = Query.Execute().Select();
	
	Return ?(Selection.Next(), Selection.Inherit, True);
	
EndFunction

// For the procedure, update the owner's Parent.
Procedure UpdateOwnerHierarchy(Ref, HasChanges, ObjectsWithChanges)
	
	// 
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	|	TableWithHierarchy.Ref AS SubordinateRef
	|FROM
	|	&TableWithHierarchy AS TableWithHierarchy
	|WHERE
	|	TableWithHierarchy.Ref IN HIERARCHY(&Ref)
	|	AND TableWithHierarchy.Ref <> &Ref";
	
	Query.Text = StrReplace(
		Query.Text, "&TableWithHierarchy", Ref.Metadata().FullName() );
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		// 
		NewRecords = ObjectParents(Selection.SubordinateRef, Ref);
		
		RecordSet = CreateRecordSet();
		RecordSet.Filter.Object.Set(Selection.SubordinateRef);
		
		Data = New Structure;
		Data.Insert("RecordSet", RecordSet);
		Data.Insert("NewRecords",  NewRecords);
		
		HasCurrentChanges = False;
		AccessManagementInternal.UpdateRecordSet(Data, HasCurrentChanges);
		
		If HasCurrentChanges Then
			HasChanges = True;
			
			If ObjectsWithChanges <> Undefined Then
				ObjectsWithChanges.Add(Ref);
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

// For procedures update the parent of the Owner, parent of the Object.
Function ParentProperties(Ref)
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	|	CurrentTable.Parent
	|INTO RefParent
	|FROM
	|	ObjectsTable AS CurrentTable
	|WHERE
	|	CurrentTable.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RefParent.Parent
	|FROM
	|	RefParent AS RefParent
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Parents.Inherit AS Inherit
	|FROM
	|	InformationRegister.ObjectRightsSettingsInheritance AS Parents
	|WHERE
	|	Parents.Object = Parents.Parent
	|	AND Parents.Object IN
	|			(SELECT
	|				RefParent.Parent
	|			FROM
	|				RefParent AS RefParent)";
	
	Query.Text = StrReplace(Query.Text, "ObjectsTable", Ref.Metadata().FullName());
	
	QueryResults = Query.ExecuteBatch(); // Array of QueryResult 
	
	Selection = QueryResults[1].Select();
	Parent = ?(Selection.Next(), Selection.Parent, Undefined);
	
	Selection = QueryResults[2].Select();
	Inherit = ?(Selection.Next(), Selection.Inherit, True);
	
	Return New Structure("Ref, Inherit", Parent, Inherit);
	
EndFunction

#EndRegion

#EndIf
