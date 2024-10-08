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
	
	If Parameters.ChoiceMode Then
		StandardSubsystemsServer.SetFormAssignmentKey(ThisObject, "SelectionPick");
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;
	
	If Parameters.Filter.Property("Owner") Then
		Property = Parameters.Filter.Owner;
		Parameters.Filter.Delete("Owner");
	EndIf;
	
	If Not ValueIsFilled(Property) Then
		Items.Property.Visible = True;
		SetValuesOrderByProperties(List);
	EndIf;
	
	Items.List.ChoiceMode = Parameters.ChoiceMode;
	
	SetHeader();
	
	OnChangeProperty();
	
	CurrentLanguageSuffix = Common.CurrentUserLanguageSuffix();
	If CurrentLanguageSuffix = Undefined Then
		
		ListProperties = Common.DynamicListPropertiesStructure();
		
		ListProperties.QueryText = List.QueryText + "
		|LEFT JOIN Catalog.ObjectPropertyValueHierarchy.Presentations AS PresentationValues
		| ON (PresentationValues.Ref = ValuesOverridable.Ref)
		| AND PresentationValues.LanguageCode = &LanguageCode";
		
		ListProperties.QueryText = StrReplace(ListProperties.QueryText, "ValuesOverridable.Description AS Description",
			"CAST(ISNULL(PresentationValues.Description, ValuesOverridable.Description) AS STRING(150)) AS Description");
		
		Common.SetDynamicListProperties(Items.List, ListProperties);
		
		CommonClientServer.SetDynamicListParameter(
			List, "LanguageCode", CurrentLanguage().LanguageCode, True);
		
	ElsIf ValueIsFilled(CurrentLanguageSuffix) Then
		
		If Common.SubsystemExists("StandardSubsystems.NationalLanguageSupport") Then
			ModuleNationalLanguageSupportServer = Common.CommonModule("NationalLanguageSupportServer");
			ModuleNationalLanguageSupportServer.OnCreateAtServer(ThisObject);
		EndIf;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_AdditionalAttributesAndInfo"
	   And Source = Property Then
		
		AttachIdleHandler("IdleHandlerOnChangeProperty", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PropertyOnChange(Item)
	
	OnChangeProperty();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy
	   And Items.List.Representation = TableRepresentation.List Then
		
		Parent = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetValuesOrderByProperties(List)
	
	Var Order;
	
	// 
	Order = List.SettingsComposer.Settings.Order;
	Order.UserSettingID = "DefaultOrder";
	
	Order.Items.Clear();
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Owner");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
	OrderItem = Order.Items.Add(Type("DataCompositionOrderItem"));
	OrderItem.Field = New DataCompositionField("Description");
	OrderItem.OrderType = DataCompositionSortDirection.Asc;
	OrderItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	OrderItem.Use = True;
	
EndProcedure

&AtServer
Procedure SetHeader()
	
	TitleLine = "";
	
	If ValueIsFilled(Property) Then
		TitleLine = Common.ObjectAttributeValue(
			Property, "ValueChoiceFormTitle",, CurrentLanguage().LanguageCode);
	EndIf;
	
	If IsBlankString(TitleLine) Then
		
		If ValueIsFilled(Property) Then
			If Not Parameters.ChoiceMode Then
				TitleLine = NStr("en = '""%1"" property values';");
			Else
				TitleLine = NStr("en = 'Select ""%1"" property value';");
			EndIf;
			
			TitleLine = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, String(Property));
		
		ElsIf Parameters.ChoiceMode Then
			TitleLine = NStr("en = 'Select property value';");
		EndIf;
	EndIf;
	
	If Not IsBlankString(TitleLine) Then
		AutoTitle = False;
		Title = TitleLine;
	EndIf;
	
EndProcedure

&AtClient
Procedure IdleHandlerOnChangeProperty()
	
	OnChangeProperty();
	
EndProcedure

&AtServer
Procedure OnChangeProperty()
	
	If ValueIsFilled(Property) Then
		
		AdditionalValuesOwner = Common.ObjectAttributeValue(
			Property, "AdditionalValuesOwner");
		
		If ValueIsFilled(AdditionalValuesOwner) Then
			ReadOnly = True;
			
			ValueType = Common.ObjectAttributeValue(
				AdditionalValuesOwner, "ValueType");
			
			CommonClientServer.SetDynamicListFilterItem(
				List, "Owner", AdditionalValuesOwner);
			
			AdditionalValuesWithWeight = Common.ObjectAttributeValue(
				AdditionalValuesOwner, "AdditionalValuesWithWeight");
		Else
			ReadOnly = False;
			ValueType = Common.ObjectAttributeValue(Property, "ValueType");
			
			CommonClientServer.SetDynamicListFilterItem(
				List, "Owner", Property);
			
			AdditionalValuesWithWeight = Common.ObjectAttributeValue(
				Property, "AdditionalValuesWithWeight");
		EndIf;
		
		If TypeOf(ValueType) = Type("TypeDescription")
		   And ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
			
			Items.List.ChangeRowSet = True;
		Else
			Items.List.ChangeRowSet = False;
		EndIf;
		
		Items.List.Representation = TableRepresentation.HierarchicalList;
		Items.Owner.Visible = False;
		Items.Weight.Visible = AdditionalValuesWithWeight;
	Else
		CommonClientServer.DeleteDynamicListFilterGroupItems(
			List, "Owner");
		
		Items.List.Representation = TableRepresentation.List;
		Items.List.ChangeRowSet = False;
		Items.Owner.Visible = True;
		Items.Weight.Visible = False;
	EndIf;
	
	Items.List.Header = Items.Owner.Visible Or Items.Weight.Visible;
	
EndProcedure

#EndRegion
