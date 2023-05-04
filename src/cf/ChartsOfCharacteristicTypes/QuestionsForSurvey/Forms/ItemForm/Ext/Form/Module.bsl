﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
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
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// 
	CommonClientServer.SetDynamicListFilterItem(AnswersOptions,"Owner", Object.Ref, DataCompositionComparisonType.Equal, ,True);
	
	SetAnswerType();
	
	If ReplyType = Enums.TypesOfAnswersToQuestion.String Then
		StringLength = Object.Length;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Object.RadioButtonType = Enums.RadioButtonTypesInQuestionnaires.RadioButton;
		Object.CheckBoxType = Enums.CheckBoxKindsInQuestionnaires.InputField;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription("ChartOfCharacteristicTypesRef.QuestionsForSurvey");
	PlacementParameters.CommandBar = Items.FormCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription("CatalogRef.QuestionnaireAnswersOptions");
	PlacementParameters.CommandBar = Items.TableAnswersOptionsCommandBar;
	PlacementParameters.GroupsPrefix = "QuestionnaireAnswersOptions";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	DescriptionBeforeEditing = Object.Description;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Object.Ref.IsEmpty() Then
		OnChangeAnswerType();
	EndIf;
	VisibilityManagement();
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	If Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.Number") Then
		
		If Object.MinValue > Object.MaxValue Then
			CommonClient.MessageToUser(
				NStr("en = 'The minimum allowed value cannot be greater than the maximum allowed value.';"),,
				"Object.MinValue");
			Cancel = True;
		EndIf;
		
	ElsIf Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.String") Then	
		
		Object.Length = StringLength;
		If StringLength = 0 Then
			CommonClient.MessageToUser(NStr("en = 'The string length is not specified.';"),,"StringLength");
			Cancel = True;
		EndIf;
		
	ElsIf Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.Text") Then
		
		Object.Length = 1024;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	AnswersOptionsTableAvailability(ThisObject);
	CommonClientServer.SetDynamicListFilterItem(AnswersOptions,
	                                                                        "Owner",
	                                                                        Object.Ref,
	                                                                        DataCompositionComparisonType.Equal,
	                                                                        ,
	                                                                        True);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReplyTypeOnChange(Item)
	
	OnChangeAnswerType();
	
EndProcedure

&AtClient
Procedure TableAnswersOptionsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,True);
	
EndProcedure

&AtClient
Procedure CommentRequiredOnChange(Item)
	
	CommentNoteRequiredAvailable();
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	If Object.Wording = DescriptionBeforeEditing Then
	
		Object.Wording = Object.Description;
	
	EndIf;
	
	DescriptionBeforeEditing = Object.Description;
	
EndProcedure

&AtClient
Procedure TableAnswersOptionsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,False);
	
EndProcedure

&AtClient
Procedure TableAnswersOptionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,False);
	
EndProcedure

&AtClient
Procedure LengthOnChange(Item)
	
	SetPrecisionBasedOnNumberLength();
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClient
Procedure AccuracyOnChange(Item)
	
	SetPrecisionBasedOnNumberLength();
	
EndProcedure

&AtClient
Procedure PresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	ClosingNotification1 = New NotifyDescription("WordingEditOnClose", ThisObject);
	CommonClient.ShowMultilineTextEditingForm(ClosingNotification1, Item.EditText, NStr("en = 'Wording';"));
	
EndProcedure

#EndRegion

#Region FormCommandHandlers

// StandardSubsystems.AttachableCommands
// 
// Parameters:
//   Command - FormCommand
// 
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If StrStartsWith(Command.Name, "QuestionnaireAnswersOptions") Then
		AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.TableAnswersOptions);
	Else
		AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	If StrStartsWith(ExecutionParameters.CommandNameInForm, "QuestionnaireAnswersOptions") Then
		AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.TableAnswersOptions);
	Else
		AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.TableAnswersOptions);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Length.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Length");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;

	FilterGroup1 = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup1.GroupType = DataCompositionFilterItemsGroupType.OrGroup;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfAnswersToQuestion.String;

	ItemFilter = FilterGroup1.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ReplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfAnswersToQuestion.Number;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReplyType.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ReplyType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.TypesOfAnswersToQuestion.InfobaseValue;

	Item.Appearance.SetParameterValue("MarkIncomplete", True);

EndProcedure

&AtClient
Procedure VisibilityManagement()
	
	CommentPossible = Not (Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.MultipleOptionsFor") 
	                        Or Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.Text"));
	Items.CommentRequired.Enabled  = CommentPossible;
	Items.Comment.Enabled           = CommentPossible;
	If Not CommentPossible Then
		Object.CommentRequired = False;
		Object.CommentNote = "";
	EndIf;
	CommentNoteRequiredAvailable();
	
	If Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.String") Then 
		Items.DependentParameters.CurrentPage = Items.StringPage;
	ElsIf Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.Number") Then
		Items.DependentParameters.CurrentPage = Items.NumericAttributesPage;
	ElsIf Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.InfobaseValue") Then
		Items.DependentParameters.CurrentPage = Items.IsEmpty;
	ElsIf Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.OneVariantOf") 
	      Or Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.MultipleOptionsFor") Then
		Items.DependentParameters.CurrentPage = Items.AnswersOptions; 
		AnswersOptionsTableAvailability(ThisObject);
	Else
		Items.DependentParameters.CurrentPage = Items.IsEmpty;
	EndIf;
	
	If Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.OneVariantOf") Then
		Items.RadioButtonTypeGroup.CurrentPage = Items.ShowRadioButtonType;
	ElsIf Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.Boolean") Then
		Items.RadioButtonTypeGroup.CurrentPage = Items.ShowRadioButtonTypeBooleanTypeGroup;
	Else
		Items.RadioButtonTypeGroup.CurrentPage = Items.HideRadioButtonTypeGroup;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnChangeAnswerType()

	If TypeOf(ReplyType) = Type("EnumRef.TypesOfAnswersToQuestion") Then
		
		Object.ReplyType = ReplyType;
		
	ElsIf TypeOf(ReplyType) = Type("TypeDescription") Then
		
		Object.ReplyType   = PredefinedValue("Enum.TypesOfAnswersToQuestion.InfobaseValue");
		Object.ValueType = ReplyType;
		
	EndIf;
	
	VisibilityManagement();
	
	If Object.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.Number") Then
		SetPrecisionBasedOnNumberLength();
	EndIf;

EndProcedure 

&AtClient
Procedure CommentNoteRequiredAvailable()
	
	Items.CommentNote.AutoMarkIncomplete = Object.CommentRequired;
	Items.CommentNote.ReadOnly            = Not Object.CommentRequired;
	
	ClearMarkIncomplete();
	
EndProcedure

&AtClientAtServerNoContext
Procedure AnswersOptionsTableAvailability(Form)
	
	If Form.Object.Ref.IsEmpty() Then
		Form.Items.TableAnswersOptions.ReadOnly  = True;
		Form.AnswersOptionsInfo                       = NStr("en = 'Before you start editing the responses, save the question';");
	Else
		Form.Items.TableAnswersOptions.ReadOnly = False;
		Form.AnswersOptionsInfo                      = NStr("en = 'Possible responses to questions:';");
	EndIf; 
	
	If Form.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.OneVariantOf") Then
		Form.Items.OpenEndedQuestion.Visible = False;
	ElsIf Form.ReplyType = PredefinedValue("Enum.TypesOfAnswersToQuestion.MultipleOptionsFor") Then
		Form.Items.OpenEndedQuestion.Visible = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenQuestionnaireAnswersQuestionsCatalogItemForm(Item,InsertMode)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Owner",Object.Ref);
	ParametersStructure.Insert("ReplyType",Object.ReplyType);
	ParametersStructure.Insert("Description",Object.ReplyType);
	
	If Not InsertMode Then
		CurrentData = Items.TableAnswersOptions.CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf;
		ParametersStructure.Insert("Key",CurrentData.Ref);
	Else
		CurrentData = Items.TableAnswersOptions.CurrentData;
		If CurrentData <> Undefined Then
			ParametersStructure.Insert("Description",CurrentData.Description);
		EndIf;
	EndIf;
		
	OpenForm("Catalog.QuestionnaireAnswersOptions.ObjectForm", ParametersStructure,Item);
	
EndProcedure

&AtServer
Procedure SetAnswerType()
	
	For Each EnumerationValue In Metadata.Enums.TypesOfAnswersToQuestion.EnumValues Do
		
		If Enums.TypesOfAnswersToQuestion[EnumerationValue.Name] = Enums.TypesOfAnswersToQuestion.InfobaseValue Then 
			
			For Each AvailableType In FormAttributeToValue("Object").Metadata().Type.Types() Do
				
				If AvailableType = Type("String") Or AvailableType = Type("Boolean") Or AvailableType = Type("Number") Or AvailableType = Type("Date") Or AvailableType = Type("CatalogRef.QuestionnaireAnswersOptions") Then
					Continue;
				EndIf;
				
				TypesArray = New Array;
				TypesArray.Add(AvailableType);
				Items.ReplyType.ChoiceList.Add(New TypeDescription(TypesArray));
				
			EndDo;
			
		Else
			Items.ReplyType.ChoiceList.Add(Enums.TypesOfAnswersToQuestion[EnumerationValue.Name]);
		EndIf;
		
	EndDo;
	
	If Object.ReplyType = Enums.TypesOfAnswersToQuestion.InfobaseValue Then
		
		ReplyType = Object.ValueType;
		
	ElsIf Object.ReplyType = Enums.TypesOfAnswersToQuestion.EmptyRef() Then
		
		ReplyType = Items.ReplyType.ChoiceList[0].Value;
		
	Else
		
		ReplyType = Object.ReplyType;
		
	EndIf;
	
EndProcedure

// Sets precision of a numerical answer based on the selected length.
//
&AtClient
Procedure SetPrecisionBasedOnNumberLength()

	If Object.Length > 15 Then
		Object.Length = 15;
	EndIf;
	
	If Object.Length = 0 Then
		Object.Accuracy = 0;
	ElsIf Object.Length <= Object.Accuracy Then
		Object.Accuracy = Object.Length - 1;
	EndIf;
	
	If Object.Accuracy > 3 Then
		Object.Accuracy = 3;
	EndIf;
	
	If (Object.Length - Object.Accuracy) > 12 Then
		Object.Length = Object.Accuracy + 12;
	EndIf;
	
EndProcedure

&AtClient
Procedure WordingEditOnClose(ReturnText, AdditionalParameters) Export
	
	If Object.Wording <> ReturnText Then
		Object.Wording = ReturnText;
		Modified = True;
	EndIf;
	
EndProcedure

#EndRegion
