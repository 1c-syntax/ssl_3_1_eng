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
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"PresentationAdditionalInfo",
		NStr("en = 'Additional information records';"),
		True);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"PresentationAdditionalAttributes",
		NStr("en = 'Additional attributes';"),
		True);
	
	// 
	DataGroup2 = List.SettingsComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
	DataGroup2.UserSettingID = "GroupPropertiesBySets";
	DataGroup2.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	GroupFields = DataGroup2.GroupFields;
	
	DataGroupItem = GroupFields.Items.Add(Type("DataCompositionGroupField"));
	DataGroupItem.Field = New DataCompositionField("PropertiesSetGroup");
	DataGroupItem.Use = True;
	
EndProcedure

#EndRegion
