///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Fills in the value of the object's additional ordering details.
//
// Parameters:
//  Object - CatalogObject
//         - ChartOfCharacteristicTypesObject - 
//                                          
//
Procedure SetOrderingAttributeValue(Object) Export
	
	If StandardSubsystemsServer.IsMetadataObjectID(Object) Then
		Return;
	EndIf;
	
	// 
	Information = GetInformationForMoving(Object.Ref.Metadata());
	If Not ObjectHasAdditionalOrderingAttribute(Object, Information) Then
		Return;
	EndIf;
	
	// 
	If Information.HasParent And Common.ObjectAttributeValue(Object.Ref, "Parent") <> Object.Parent Then
		Object.AddlOrderingAttribute = 0;
	EndIf;
	
	// 
	If Object.AddlOrderingAttribute = 0 Then
		Object.AddlOrderingAttribute =
			ItemOrderSetupInternal.GetNewAdditionalOrderingAttributeValue(
					Information,
					?(Information.HasParent, Object.Parent, Undefined),
					?(Information.HasOwner, Object.Owner, Undefined));
	EndIf;
	
EndProcedure

// Resets the value of the additional ordering attribute for the object.
//
// Parameters:
//  Source          - CatalogObject
//                    - ChartOfCharacteristicTypesObject - 
//  CopiedObject - CatalogRef
//                    - ChartOfCharacteristicTypesRef - 
//
Procedure ClearOrderAttributeValue(Source, CopiedObject) Export
	
	If StandardSubsystemsServer.IsMetadataObjectID(Source) Then
		Return;
	EndIf;
	
	Information = GetInformationForMoving(Source.Ref.Metadata());
	If ObjectHasAdditionalOrderingAttribute(Source, Information) Then
		Source.AddlOrderingAttribute = 0;
	EndIf;
	
EndProcedure

// Returns a structure with information about the object's metadata.
// 
// Parameters:
//  ObjectMetadata - MetadataObject -  metadata of the object being moved.
//
// Returns:
//  Structure - 
//
Function GetInformationForMoving(ObjectMetadata) Export
	
	Information = New Structure;
	
	AttributeMetadata = ObjectMetadata.Attributes.AddlOrderingAttribute;
	
	Information.Insert("FullName",    ObjectMetadata.FullName());
	
	IsCatalog = Metadata.Catalogs.Contains(ObjectMetadata);
	IsCCT        = Metadata.ChartsOfCharacteristicTypes.Contains(ObjectMetadata);
	
	If IsCatalog Or IsCCT Then
		
		Information.Insert("HasGroups", ObjectMetadata.Hierarchical
			And ?(IsCCT, True, ObjectMetadata.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems));
		
		Information.Insert("ForGroups",     (AttributeMetadata.Use <> Metadata.ObjectProperties.AttributeUse.ForItem));
		Information.Insert("ForItems", (AttributeMetadata.Use <> Metadata.ObjectProperties.AttributeUse.ForFolder));
		Information.Insert("HasParent",  ObjectMetadata.Hierarchical);
		Information.Insert("FoldersOnTop", ?(Not Information.HasParent, False, ObjectMetadata.FoldersOnTop));
		Information.Insert("HasOwner", ?(IsCCT, False, (ObjectMetadata.Owners.Count() <> 0)));
		
	Else
		
		Information.Insert("HasGroups",   False);
		Information.Insert("ForGroups",     False);
		Information.Insert("ForItems", True);
		Information.Insert("HasParent", False);
		Information.Insert("HasOwner", False);
		Information.Insert("FoldersOnTop", False);
		
	EndIf;
	
	Return Information;
	
EndFunction

#EndRegion

#Region Internal

// Moves an item up or down in the list.
// 
// Parameters:
//  Ref - CatalogRef
//         - ChartOfCharacteristicTypesRef - 
//  ExecutionParameters - See AttachableCommandsClientServer.CommandExecuteParameters
//
Procedure Attachable_MoveItem(Ref, ExecutionParameters) Export
	Direction = ExecutionParameters.CommandDetails.Id;
	ErrorText = ItemOrderSetupInternal.MoveItem(ExecutionParameters.Source, Ref, Direction);
	ExecutionParameters.Result.Text = ErrorText;
EndProcedure

// See AttachableCommandsOverridable.OnDefineAttachableCommandsKinds
Procedure OnDefineAttachableCommandsKinds(AttachableCommandsKinds) Export
	Kind = AttachableCommandsKinds.Add();
	Kind.Name         = "ItemOrderSetup";
	Kind.SubmenuName  = "ItemOrderSetup";
	Kind.Title   = NStr("en = 'Item order setup';");
	Kind.FormGroupType = FormGroupType.ButtonGroup;
	Kind.Representation = ButtonGroupRepresentation.Compact;
EndProcedure

// See AttachableCommandsOverridable.OnDefineCommandsAttachedToObject
Procedure OnDefineCommandsAttachedToObject(FormSettings, Sources, AttachedReportsAndDataProcessors, Commands) Export
	
	ObjectsWithCustomizableOrder = New Array;
	For Each Type In Metadata.DefinedTypes.ObjectWithCustomOrder.Type.Types() Do
		MetadataObject = Metadata.FindByType(Type);
		ObjectsWithCustomizableOrder.Add(MetadataObject.FullName());
	EndDo;
	
	NeedOutputCommands = False;
	For Each Source In Sources.Rows Do
		If ObjectsWithCustomizableOrder.Find(Source.FullName) <> Undefined Then
			NeedOutputCommands = AccessRight("Update", Source.Metadata);
			Break;
		EndIf;
	EndDo;
	If Not NeedOutputCommands Then
		Return;
	EndIf;
	
	Command = Commands.Add();
	Command.Kind = "ItemOrderSetup";
	Command.Id = ItemMovementDirectionUp();
	Command.Presentation = NStr("en = 'Move item up';");
	Command.Order = 1;
	Command.Picture = PictureLib.MoveUp;
	Command.ChangesSelectedObjects = True;
	Command.MultipleChoice = False;
	Command.Handler = "ItemOrderSetup.Attachable_MoveItem";
	Command.ButtonRepresentation = ButtonRepresentation.Picture;
	Command.Purpose = "ForList";
	
	Command = Commands.Add();
	Command.Kind = "ItemOrderSetup";
	Command.Id = ItemMovementDirectionDown();
	Command.Presentation = NStr("en = 'Move item down';");
	Command.Order = 2;
	Command.Picture = PictureLib.MoveDown;
	Command.ChangesSelectedObjects = True;
	Command.MultipleChoice = False;
	Command.Handler = "ItemOrderSetup.Attachable_MoveItem";
	Command.ButtonRepresentation = ButtonRepresentation.Picture;
	Command.Purpose = "ForList";
	
EndProcedure

Function ItemMovementDirectionUp() Export
	Return "Up";
EndFunction

Function ItemMovementDirectionDown() Export
	Return "Down";
EndFunction


#EndRegion

#Region Private

Function ObjectHasAdditionalOrderingAttribute(Object, Information)
	
	If Not Information.HasParent Then
		// 
		Return True;
		
	ElsIf Object.IsFolder And Not Information.ForGroups Then
		// 
		Return False;
		
	ElsIf Not Object.IsFolder And Not Information.ForItems Then
		// 
		Return False;
		
	Else
		Return True;
		
	EndIf;
	
EndFunction

// The event subscription handler fills in the reorder Requestionvalue.
// Fills in the value of the object's additional ordering details.
//
// Parameters:
//  Source - CatalogObject
//           - ChartOfCharacteristicTypesObject - 
//  Cancel    - Boolean -  indicates that the object was not recorded.
//
Procedure FillOrderingAttributeValue(Source, Cancel) Export
	
	If Source.DataExchange.Load Then 
		Return; 
	EndIf;
	
	// 
	If Cancel Then
		Return;
	EndIf;
	
	SetOrderingAttributeValue(Source);
	
EndProcedure

#EndRegion
