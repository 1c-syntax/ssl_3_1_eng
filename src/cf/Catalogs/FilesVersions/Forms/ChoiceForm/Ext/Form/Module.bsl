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
	
	If Parameters.Filter.Property("Owner") Then
		Items.ListOwner.Visible = False;
	EndIf;
	
	// 
	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue  = New DataCompositionField("DeletionMark");
	DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = True;
	DataFilterItem.Use  = True;
	
	FilesOperationsInternal.SetFilterByDeletionMark(List.Filter);
	
	If Common.IsMobileClient() Then
		Items.Comment.Visible = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListOnActivateRow(Item)
	
	If Items.List.CurrentRow <> Undefined 
	   And TypeOf(Items.List.CurrentData) = Type("FormDataStructure")
	   And Items.List.CurrentData.Property("Author") Then
		Items.FormDelete.Enabled =
			Items.List.CurrentData.Author = UsersClient.AuthorizedUser();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Delete(Command)
	
	If Items.List.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	FilesOperationsInternalClient.DeleteData(
		New NotifyDescription("AfterDeleteData", ThisObject),
		Items.List.CurrentData.Ref, UUID);
	
EndProcedure

&AtClient
Procedure ShowMarkedFiles(Command)
	
	FilesOperationsInternalClient.ChangeFilterByDeletionMark(List.Filter, Items.ShowMarkedFiles);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AfterDeleteData(Result, AdditionalParameters) Export
	
	Items.List.Refresh();
	
EndProcedure

#EndRegion
