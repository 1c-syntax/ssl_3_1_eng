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
	
	SetConditionalAppearance();
	
	Assignees.Parameters.SetParameterValue("NoAddressObject", NStr("en = '<Without business object>';"));
	
	ConfigureRoleListRepresentation();

EndProcedure

&AtServer
Procedure ConfigureRoleListRepresentation()
	
	CommonClientServer.SetDynamicListFilterItem(Assignees, 
		"PerformerRole", Parameters.PerformerRole, DataCompositionComparisonType.Equal);
	RoleProperties = Common.ObjectAttributesValues(Parameters.PerformerRole, "UsedByAddressingObjects,AdditionalAddressingObjectTypes,MainAddressingObjectTypes");
	If RoleProperties.UsedByAddressingObjects Then
		GroupingField = Assignees.Group.Items.Add(Type("DataCompositionGroupField"));
		GroupingField.Field = New DataCompositionField("MainAddressingObject");
		GroupingField.Use = True;
		If Not RoleProperties.AdditionalAddressingObjectTypes.IsEmpty() Then
			GroupingField = Assignees.Group.Items.Add(Type("DataCompositionGroupField"));
			GroupingField.Field = New DataCompositionField("AdditionalAddressingObject");
			GroupingField.Use = True;
		EndIf;
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AssigneesAfterDeleteRow(Item)
	Notify("WriteRoleAddressing", Undefined, Undefined);
EndProcedure

#EndRegion


#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearanceItem = Assignees.ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	FormattedField = ConditionalAppearanceItem.Fields.Items.Add();
	FormattedField.Field = New DataCompositionField("Performer");
	FormattedField.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("Performer.Invalid");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", Metadata.StyleItems.InaccessibleCellTextColor.Value);
	
EndProcedure


#EndRegion