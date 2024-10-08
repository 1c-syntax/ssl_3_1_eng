﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	If ValueIsFilled(Parameters.SubjectOf) Then 
		SubjectOf = Parameters.SubjectOf;
		List.Parameters.SetParameterValue("SubjectOf", SubjectOf);
	EndIf;
	
	List.Parameters.SetParameterValue("User", Users.CurrentUser());
	List.Parameters.SetParameterValue("ShowNotesByOtherUsers", False);
	List.Parameters.SetParameterValue("ShowDeleted", False);
	
	If Not Users.IsFullUser() Then
		Items.Author.Visible = False;
		Items.ShowNotesByOtherUsers.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	List.Parameters.SetParameterValue("ShowNotesByOtherUsers", ShowNotesByOtherUsers);
	List.Parameters.SetParameterValue("ShowDeleted", ShowDeleted);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ShowNotesByOtherUsersOnChange(Item)
	List.Parameters.SetParameterValue("ShowNotesByOtherUsers", ShowNotesByOtherUsers);
EndProcedure

&AtClient
Procedure ShowDeletedOnChange(Item)
	List.Parameters.SetParameterValue("ShowDeleted", ShowDeleted);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Not Copy Then
		Cancel = True;
		FormParameters = New Structure("SubjectOf", SubjectOf);
		OpenForm("Catalog.Notes.ObjectForm", FormParameters);
	EndIf;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ForDesktop");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DeletionMark");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.ImportantLabelFont);
	
EndProcedure

#EndRegion

