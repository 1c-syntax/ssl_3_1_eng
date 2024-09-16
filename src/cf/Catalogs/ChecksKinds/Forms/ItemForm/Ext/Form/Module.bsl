///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateTableRowsCounters();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAdditionalProperties

&AtClient
Procedure ObjectPropertiesOnChange(Item)
	
	UpdateTableRowsCounters();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateTableRowsCounters()
	
	SetPageTitle(Items.AdditionalPropertiesPage, Object.ObjectProperties, NStr("en = 'Additional properties';"));
	
EndProcedure

&AtClient
Procedure SetPageTitle(PageItem, AttributeTabularSection, DefaultTitle)
	
	PageHeader = DefaultTitle;
	If AttributeTabularSection.Count() > 0 Then
		PageHeader = DefaultTitle + " (" + AttributeTabularSection.Count() + ")";
	EndIf;
	PageItem.Title = PageHeader;
	
EndProcedure

#EndRegion