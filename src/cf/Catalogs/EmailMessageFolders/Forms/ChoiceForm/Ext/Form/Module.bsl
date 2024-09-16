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
	
	ProcessPassedParameters();
	
	SetPredefinedFilters();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OwnerOnChange(Item)
	
	OnChangeOwnerAtServer();
	
EndProcedure

&AtClient
Procedure OwnerClearing(Item, StandardProcessing)
	
	OnChangeOwnerAtServer();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProcessPassedParameters()
	
	If Parameters.Filter.Property("Owner")
		And ValueIsFilled(Parameters.Filter.Owner) Then
		
		Owner = Parameters.Filter.Owner;
		Items.Owner.Visible = False;
		
	EndIf;
	
	If Not ValueIsFilled(Owner) Then
		Owner = EmailOperations.SystemAccount();
		OnChangeOwnerAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPredefinedFilters()
	
	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "DeletionMark",
	                                                                        False,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        NStr("en = 'Show only folders not marked for deletion';"),
	                                                                        True, 
	                                                                        DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

&AtServer
Procedure OnChangeOwnerAtServer()
	
	CommonClientServer.SetDynamicListFilterItem(List,
	                                                                        "Owner",
	                                                                        Owner,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        NStr("en = 'Filter by folder owner';"),
	                                                                        ValueIsFilled(Owner), 
	                                                                        DataCompositionSettingsItemViewMode.Inaccessible);
	
EndProcedure

#EndRegion