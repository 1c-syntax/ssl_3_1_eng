///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Specifies that the specified event is an event about changing a set of properties.
//
// Parameters:
//  Form      - ClientApplicationForm -  form, which was caused by the processing of the alert.
//  EventName - String       -  name of the event to process.
//  Parameter   - Arbitrary -  parameters passed in the event.
//             - Structure:
//                  * Ref - CatalogRef.AdditionalAttributesAndInfoSets -  a modified set of properties.
//                           - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - 
//                                                                                             
//
// Returns:
//  Boolean - 
//           
//
Function ProcessNotifications(Form, EventName, Parameter) Export
	
	If Not Form.PropertiesUseProperties
	 Or Not Form.PropertiesUseAddlAttributes Then
		
		Return False;
	EndIf;
	
	If EventName = "Write_AdditionalAttributesAndInfoSets" Then
		If Not Parameter.Property("Ref") Then
			Return True;
		Else
			Return Form.PropertiesObjectAdditionalAttributeSets.FindByValue(Parameter.Ref) <> Undefined;
		EndIf;
		
	ElsIf EventName = "Write_AdditionalAttributesAndInfo" Then
		
		If Form.PropertiesParameters.Property("DeferredInitializationExecuted")
			And Not Form.PropertiesParameters.DeferredInitializationExecuted
			Or Not Parameter.Property("Ref") Then
			Return True;
		Else
			Filter = New Structure("Property", Parameter.Ref); 
			If Form.PropertiesAdditionalAttributeDetails.FindRows(Filter).Count() > 0
				Or Form.Properties_LabelsApplied.FindByValue(Parameter.Ref) <> Undefined Then
				Return True;
			Else
				Return False;
			EndIf;
		EndIf;
	ElsIf EventName = "Write_LabelsChange" And Form = Parameter.Owner Then
		Form.Properties_LabelsApplied.LoadValues(Parameter.LabelsApplied);
		Form.Modified = True;
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

// Updates visibility, availability, and whether
// additional details must be filled in.
//
// Parameters:
//  Form  - ClientApplicationForm     -  the form being processed.
//  Object - FormDataStructure -  description of the object to which the properties are connected
//                                  . if the property is not specified or Undefined, the
//                                  object will be taken from the "Object"form details.
//
Procedure UpdateAdditionalAttributesDependencies(Form, Object = Undefined) Export
	
	If Not Form.PropertiesUseProperties
	 Or Not Form.PropertiesUseAddlAttributes Then
		
		Return;
	EndIf;
	
	If Form.PropertiesDependentAdditionalAttributesDescription.Count() = 0 Then
		Return;
	EndIf;
	
	If Object = Undefined Then
		ObjectDetails = Form.Object;
	Else
		ObjectDetails = Object;
	EndIf;
	
	For Each DependentAttributeDetails In Form.PropertiesDependentAdditionalAttributesDescription Do
		If DependentAttributeDetails.OutputAsHyperlink Then
			ProcessedItem = StrReplace(DependentAttributeDetails.ValueAttributeName, "AdditionalAttributeValue_", "Group_");
		Else
			ProcessedItem = DependentAttributeDetails.ValueAttributeName;
		EndIf;
		
		If DependentAttributeDetails.AvailabilityCondition <> Undefined Then
			Parameters = New Structure;
			Parameters.Insert("ParameterValues", DependentAttributeDetails.AvailabilityCondition.ParameterValues);
			Parameters.Insert("Form", Form);
			Parameters.Insert("ObjectDetails", ObjectDetails);
			Result = Eval(DependentAttributeDetails.AvailabilityCondition.ConditionCode);
			
			Item = Form.Items[ProcessedItem];
			If Item.Enabled <> Result Then
				Item.Enabled = Result;
			EndIf;
		EndIf;
		If DependentAttributeDetails.VisibilityCondition <> Undefined Then
			Parameters = New Structure;
			Parameters.Insert("ParameterValues", DependentAttributeDetails.VisibilityCondition.ParameterValues);
			Parameters.Insert("Form", Form);
			Parameters.Insert("ObjectDetails", ObjectDetails);
			Result = Eval(DependentAttributeDetails.VisibilityCondition.ConditionCode);
			
			Item = Form.Items[ProcessedItem];
			If Item.Visible <> Result Then
				Item.Visible = Result;
			EndIf;
		EndIf;
		If DependentAttributeDetails.FillingRequiredCondition <> Undefined Then
			If Not DependentAttributeDetails.RequiredToFill Then
				Continue;
			EndIf;
			
			Parameters = New Structure;
			Parameters.Insert("ParameterValues", DependentAttributeDetails.FillingRequiredCondition.ParameterValues);
			Parameters.Insert("Form", Form);
			Parameters.Insert("ObjectDetails", ObjectDetails);
			Result = Eval(DependentAttributeDetails.FillingRequiredCondition.ConditionCode);
			
			Item = Form.Items[ProcessedItem];
			If Not DependentAttributeDetails.OutputAsHyperlink
				And Item.AutoMarkIncomplete <> Result Then
				Item.AutoMarkIncomplete = Result;
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

// Checks for the presence of dependent additional details on the form
// and, if necessary, connects the handler for waiting for verification of the details ' dependencies.
//
// Parameters:
//  Form - ClientApplicationForm -  the form being checked.
//
Procedure AfterImportAdditionalAttributes(Form) Export
	
	If Not Form.PropertiesUseProperties
		Or Not Form.PropertiesUseAddlAttributes Then
		
		Return;
	EndIf;
	
	Form.AttachIdleHandler("UpdateAdditionalAttributesDependencies", 2);
	
EndProcedure

// Handler for commands from forms that have additional properties attached to them.
// 
// Parameters:
//  Form                - ClientApplicationForm -  a form with additional details that is pre
//                          -configured in the property Management procedure.Precontamination().
//  Item              - FormField
//                       - FormCommand - 
//  StandardProcessing - Boolean -  the returned parameter is set to False if you want to perform interactive
//                          actions with the user.
//  Object - FormDataStructure -  description of the object to which the properties are connected
//                                  . if the property is not specified or Undefined, the
//                                  object will be taken from the "Object"form details.
//
Procedure ExecuteCommand(Form,
						   Item = Undefined,
						   StandardProcessing = Undefined,
						   Object = Undefined) Export
	
	If Item = Undefined Then
		CommandName = "EditAdditionalAttributesComposition";
	ElsIf TypeOf(Item) = Type("FormCommand") Then
		CommandName = Item.Name;
	ElsIf TypeOf(Item) = Type("FormDecoration") Then
		CommandName = Item.Name;
	Else
		AttributeValue = Form[Item.Name];
		If Not ValueIsFilled(AttributeValue) Then
			EditAttributeHyperlink(Form, True, Item);
			StandardProcessing = False;
		EndIf;
		Return;
	EndIf;
	
	If CommandName = "EditAdditionalAttributesComposition" Then
		EditPropertiesContent(Form);
	ElsIf CommandName = "EditAttributeHyperlink" Then
		EditAttributeHyperlink(Form);
	ElsIf CommandName = "EditLabels"
		Or CommandName = "OtherLabels"
		Or StrFind(CommandName, "Label") = 1 Then
		EditLabels(Form, Object);
	EndIf;
	
EndProcedure

// 
//
// Parameters:
//  Form  - ClientApplicationForm     -  the form being processed.
//  Object - FormDataStructure -  description of the object to which the properties are connected
//                                  . if the property is not specified or Undefined, the
//                                  object will be taken from the "Object"form details.
//
Procedure EditLabels(Form, Object = Undefined) Export
	
	If Object = Undefined Then
		ObjectDetails = Form.Object;
	Else
		ObjectDetails = Object;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectDetails", ObjectDetails);
	
	OpenForm("CommonForm.LabelsEdit", FormParameters, Form, Form,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// 
//
// Parameters:
//  Form      - ClientApplicationForm     -  the form being processed.
//  CommandName - String - 
//
Procedure ApplyFilterByLabel(Form, CommandName) Export
	
	FilterItems1 = Form.List.Filter.Items;
	FilterGroup = Undefined;
	For Each FilterElement In FilterItems1 Do
		If FilterElement.UserSettingID = "FilterByLabels" Then
			FilterGroup = FilterElement;
			Break;
		EndIf;
	EndDo;
	
	NameOfLabel = StrReplace(CommandName, "FilterLabel_", "");
	LabelsLegendDetails = Form.Properties_LabelsLegendDetails;
	LegendLabels = LabelsLegendDetails.FindRows(New Structure("NameOfLabel", NameOfLabel));
	
	If LegendLabels.Count() = 0 Then
		Return;
	Else
		SelectedLabel = LegendLabels[0];
	EndIf;
	
	If FilterGroup = Undefined Then
		SelectedLabels = New Array;
		SelectedLabels.Add(SelectedLabel.Label);
	Else
		SelectedLabels = FilterGroup.RightValue;
		LabelIndex = SelectedLabels.Find(SelectedLabel.Label);
		If LabelIndex <> Undefined Then
			SelectedLabels.Delete(LabelIndex);
			SelectedLabel.FilterByLabel = False;
		Else
			SelectedLabels.Add(SelectedLabel.Label);
			SelectedLabel.FilterByLabel = True;
		EndIf;
	EndIf;
	
	If SelectedLabels.Count() = 0 Then
		FilterGroup.Use = False;
		Return;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		Form.List,
		"AdditionalAttributes.Property",
		SelectedLabels,
		DataCompositionComparisonType.InList,,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible,
		"FilterByLabels");
	
EndProcedure

#EndRegion

#Region Internal

Procedure OpenPropertiesList(CommandName) Export
	
	If CommandName = "AdditionalAttributes" Then
		PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes");
	ElsIf CommandName = "AdditionalInfo" Then
		PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalInfo");
	ElsIf CommandName = "Labels" Then
		PropertyKind = PredefinedValue("Enum.PropertiesKinds.Labels");
	Else
		PropertyKind = PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes");
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("PropertyKind", PropertyKind);
	OpenForm("Catalog.AdditionalAttributesAndInfoSets.ListForm", FormParameters,, PropertyKind);
	
EndProcedure

#EndRegion

#Region Private

// Opens the form for editing a set of additional details.
//
// Parameters:
//  Form - ClientApplicationForm -  the form from which the method is called.
//
Procedure EditPropertiesContent(Form)
	
	Sets = Form.PropertiesObjectAdditionalAttributeSets;
	
	If Sets.Count() = 0
	 Or Not ValueIsFilled(Sets[0].Value) Then
		
		ShowMessageBox(,
			NStr("en = 'Cannot get the additional attribute sets of the object.
			           |
			           |Probably some of the required object attributes are blank.';"));
	
	Else
		FormParameters = New Structure;
		FormParameters.Insert("PropertyKind",
			PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes"));
		
		OpenForm("Catalog.AdditionalAttributesAndInfoSets.ListForm", FormParameters);
		
		MigrationParameters = New Structure;
		MigrationParameters.Insert("Set", Sets[0].Value);
		MigrationParameters.Insert("Property", Undefined);
		MigrationParameters.Insert("IsAdditionalInfo", False);
		MigrationParameters.Insert("PropertyKind",
			PredefinedValue("Enum.PropertiesKinds.AdditionalAttributes"));
		
		BeginningLength = StrLen("AdditionalAttributeValue_");
		IsFormField = (TypeOf(Form.CurrentItem) = Type("FormField"));
		If IsFormField And Upper(Left(Form.CurrentItem.Name, BeginningLength)) = Upper("AdditionalAttributeValue_") Then
			
			SetID   = StrReplace(Mid(Form.CurrentItem.Name, BeginningLength +  1, 36), "x","-");
			PropertyID = StrReplace(Mid(Form.CurrentItem.Name, BeginningLength + 38, 36), "x","-");
			
			If StringFunctionsClientServer.IsUUID(Lower(SetID)) Then
				MigrationParameters.Insert("Set", SetID);
			EndIf;
			
			If StringFunctionsClientServer.IsUUID(Lower(PropertyID)) Then
				MigrationParameters.Insert("Property", PropertyID);
			EndIf;
		EndIf;
		
		Notify("GoAdditionalDataAndAttributeSets", MigrationParameters);
	EndIf;
	
EndProcedure

Procedure EditAttributeHyperlink(Form, HyperlinkAction = False, Item = Undefined)
	If Not HyperlinkAction Then
		ButtonName = Form.CurrentItem.Name;
		UniquePart = StrReplace(ButtonName, "Button_", "");
		AttributeName = "AdditionalAttributeValue_" + UniquePart;
	Else
		AttributeName = Item.Name;
		UniquePart = StrReplace(AttributeName, "AdditionalAttributeValue_", "");
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("ValueAttributeName", AttributeName);
	
	AttributesDetails1 = Form.PropertiesAdditionalAttributeDetails.FindRows(FilterParameters);
	If AttributesDetails1.Count() <> 1 Then
		Return;
	EndIf;
	AttributeDetails = AttributesDetails1[0];
	
	If Not AttributeDetails.RefTypeString Then
		Item = Form.Items[AttributeName]; // 
		If Item.Type = FormFieldType.InputField Then
			Item.Type = FormFieldType.LabelField;
			Item.Hyperlink = True;
		Else
			Item.Type = FormFieldType.InputField;
			If AttributeDetails.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
				Or AttributeDetails.ValueType.ContainsType(Type("CatalogRef.ObjectPropertyValueHierarchy")) Then
				ChoiceParameter = ?(ValueIsFilled(AttributeDetails.AdditionalValuesOwner),
					AttributeDetails.AdditionalValuesOwner, AttributeDetails.Property);
				ChoiceParametersArray1 = New Array;
				ChoiceParametersArray1.Add(New ChoiceParameter("Filter.Owner", ChoiceParameter));
				
				Item.ChoiceParameters = New FixedArray(ChoiceParametersArray1);
			EndIf;
		EndIf;
		
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("AttributeName", AttributeName);
	OpeningParameters.Insert("ValueType", AttributeDetails.ValueType);
	OpeningParameters.Insert("AttributeDescription", AttributeDetails.Description);
	OpeningParameters.Insert("RefTypeString", AttributeDetails.RefTypeString);
	OpeningParameters.Insert("AttributeValue", Form[AttributeName]);
	OpeningParameters.Insert("ReadOnly", Form.ReadOnly);
	If AttributeDetails.RefTypeString Then
		OpeningParameters.Insert("RefAttributeName", "ReferenceAdditionalAttributeValue" + UniquePart);
	Else
		OpeningParameters.Insert("Property", AttributeDetails.Property);
		OpeningParameters.Insert("AdditionalValuesOwner", AttributeDetails.AdditionalValuesOwner);
	EndIf;
	NotifyDescription = New NotifyDescription("EditAttributeHyperlinkCompletion", PropertyManagerClient, Form);
	OpenForm("CommonForm.EditHyperlink", OpeningParameters,,,,, NotifyDescription);
EndProcedure

Procedure EditAttributeHyperlinkCompletion(Result, AdditionalParameters) Export
	If TypeOf(Result) <> Type("Structure") Then
		Return;
	EndIf;
	
	Form = AdditionalParameters;
	Form[Result.AttributeName] = Result.Value;
	If Result.RefTypeString Then
		Form[Result.RefAttributeName] = Result.FormattedString;
	EndIf;
	Form.Modified = True;
EndProcedure

#EndRegion