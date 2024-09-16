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
	
	ReadOnly = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure EnableEditing(Command)
	
	ReadOnly = False;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	// 
	AppearanceItem = List.SettingsComposer.Settings.ConditionalAppearance.Items.Add();
	AppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	DecorationTextItem = AppearanceItem.Appearance.Items.Find("Text");
	DecorationTextItem.Value = NStr("en = 'Allowed empty access group';");
	DecorationTextItem.Use = True;
	
	FilterElement = AppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue  = New DataCompositionField("AccessGroup");
	FilterElement.ComparisonType   = DataCompositionComparisonType.Equal;
	FilterElement.RightValue = Catalogs.AccessGroups.EmptyRef();
	FilterElement.Use  = True;
	
	FieldItem = AppearanceItem.Fields.Items.Add();
	FieldItem.Field = New DataCompositionField("AccessGroup");
	FieldItem.Use = True;
	
EndProcedure

#EndRegion
