///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlersForm

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Not AccessRight("Edit", Metadata.Catalogs.AddIns) Then
		
		Items.FormUpdateFromFile.Visible = False;
		Items.FormSaveAs.Visible = False;
		Items.PerformUpdateFrom1CITSPortal.Visible = False;
		Items.ListContextMenuUpdateFromFile.Visible = False;
		Items.ListContextMenuSaveAs.Visible = False;
		
	EndIf;
	
	If Not AddInsInternal.CanImportFromPortal() Then 
		
		Items.UpdateFrom1CITSPortal.Visible = False;
		Items.PerformUpdateFrom1CITSPortal.Visible = False;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetFilter();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFilterOnChange(Item)
	
	SetFilter();
	
EndProcedure

#EndRegion

#Region ListFormTableItemEventHandlers

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then 
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure UpdateFromThePortal(Command)
	
	ReferencesArrray = Items.List.SelectedRows;
	
	If ReferencesArrray.Count() = 0 Then 
		Return;
	EndIf;
	
	Notification = New NotifyDescription("AfterUpdateAddInFromPortal", ThisObject);
	
	AddInsInternalClient.UpdateAddInsFromPortal(Notification, ReferencesArrray);
	
EndProcedure

&AtClient
Procedure UpdateFromFile(Command)
	
	RowData = Items.List.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", RowData.Ref);
	FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
	
	OpenForm("Catalog.AddIns.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure SaveAs(Command)
	
	RowData = Items.List.CurrentData;
	If RowData = Undefined Then
		Return;
	EndIf;
	
	AddInsInternalClient.SaveAddInToFile(RowData.Ref);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterUpdateAddInFromPortal(Result, AdditionalParameters) Export
	
	Items.List.Refresh();
	
EndProcedure

/////////////////////////////////////////////////////////
// 

&AtServer
Procedure SetFilter()
	
	FilterParameters = New Map();
	FilterParameters.Insert("UseFilter", UseFilter);
	SetListFilter(List, FilterParameters);
	
EndProcedure

&AtServerNoContext
Procedure SetListFilter(List, FilterParameters)
	
	If FilterParameters["UseFilter"] = 0 Then 
		CommonClientServer.SetDynamicListFilterItem(
			List, "Use",,,, False);
	ElsIf FilterParameters["UseFilter"] = 1 Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "Use", Enums.AddInUsageOptions.Used,,, True);
	ElsIf FilterParameters["UseFilter"] = 2 Then
		CommonClientServer.SetDynamicListFilterItem(
			List, "Use", Enums.AddInUsageOptions.isDisabled,,, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("Use");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AddInUsageOptions.isDisabled;
	
	ConditionalAppearanceItem.Appearance.SetParameterValue(
		"TextColor", Metadata.StyleItems.InaccessibleCellTextColor.Value);
	
EndProcedure

#EndRegion