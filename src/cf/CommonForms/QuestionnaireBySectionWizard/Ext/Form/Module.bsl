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
	
	If Not Parameters.Property("QuestionnaireTemplate") Then
		Cancel = True;
		Return;
	Else
		QuestionnaireTemplate = Parameters.QuestionnaireTemplate;
	EndIf;
	
	SetFormAttributesValuesAccordingToQuestionnaireTemplate();
	Surveys.SetQuestionnaireSectionsTreeItemIntroductionConclusion(SectionsTree, NStr("en = 'Introduction';"), "Introduction");
	Surveys.FillSectionsTree(ThisObject,SectionsTree);
	Surveys.SetQuestionnaireSectionsTreeItemIntroductionConclusion(SectionsTree, NStr("en = 'Closing statement';"), "ClosingStatement");
	SurveysClientServer.GenerateTreeNumbering(SectionsTree,True);
	
	Items.SectionsTree.CurrentRow = 0;
	CreateFormAccordingToSection();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SectionsNavigationButtonAvailabilityControl();
	
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SectionsTreeSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.SectionsTree.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ExecuteFillingFormCreation();
	SectionsNavigationButtonAvailabilityControl();
	
EndProcedure

&AtClient
Procedure Attachable_OnChangeQuestionsWithConditions(Item)

	AvailabilityControlSubordinateQuestions();

EndProcedure

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure HideShowSectionsTree(Command)

	ChangeSectionsTreeVisibility();
	
EndProcedure

&AtClient
Procedure PreviousSection(Command)
	
	ChangeSection("Back");
	
EndProcedure

&AtClient
Procedure NextSection(Command)
	
	ChangeSection("GoForward");
	
EndProcedure

&AtClient
Procedure SelectSection(Command)
	
	ExecuteFillingFormCreation();
	SectionsNavigationButtonAvailabilityControl();

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

EndProcedure

// Used for creating a filling form.
&AtServer
Procedure CreateFormAccordingToSection()
	
	// Determine the section.
	CurrentDataSectionsTree = SectionsTree.FindByID(Items.SectionsTree.CurrentRow);
	If CurrentDataSectionsTree = Undefined Then
		Return;
	EndIf;
	
	CurrentSectionNumber = Items.SectionsTree.CurrentRow;
	Surveys.CreateFillingFormBySection(ThisObject,CurrentDataSectionsTree);
	Surveys.GenerateQuestionsSubordinationTable(ThisObject);
	
	Items.FooterPreviousSection.Visible = (SectionQuestionsTable.Count() > 0);
	Items.FooterNextSection.Visible  = (SectionQuestionsTable.Count() > 0);
	
	SurveysClientServer.SwitchQuestionnaireBodyGroupsVisibility(ThisObject, True);
	
EndProcedure

// Starts the process of creating a filling form according to sections.
&AtClient
Procedure ExecuteFillingFormCreation()
	
	SurveysClientServer.SwitchQuestionnaireBodyGroupsVisibility(ThisObject, False);
	AttachIdleHandler("EndBuildFillingForm",0.1,True);
	
EndProcedure

// Finishes generation of a questionnaire filling form.
&AtClient
Procedure EndBuildFillingForm()
	
	CreateFormAccordingToSection();
	AvailabilityControlSubordinateQuestions();
	SectionsNavigationButtonAvailabilityControl();
	
EndProcedure

// Manages availability of navigation buttons by sections.
&AtClient
Procedure SectionsNavigationButtonAvailabilityControl()
	
	Items.PreviousSection.Visible       = (Items.SectionsTree.CurrentRow <> 0);
	Items.FooterPreviousSection.Visible = (Items.SectionsTree.CurrentRow > 0);
	Items.NextSection.Visible        = (SectionsTree.FindByID(Items.SectionsTree.CurrentRow +  1) <> Undefined);
	Items.FooterNextSection.Visible  = (SectionsTree.FindByID(Items.SectionsTree.CurrentRow +  1) <> Undefined);
	
EndProcedure

// Changes the current section
&AtClient
Procedure ChangeSection(Direction)
	
	Items.SectionsTree.CurrentRow = CurrentSectionNumber + ?(Direction = "GoForward",1,-1);
	CurrentSectionNumber = CurrentSectionNumber + ?(Direction = "GoForward",1,-1);
	CurrentDataSectionsTree = SectionsTree.FindByID(Items.SectionsTree.CurrentRow);
	If CurrentDataSectionsTree.QuestionsCount = 0 And CurrentDataSectionsTree.RowType = "Section"  Then
		ChangeSection(Direction);
	EndIf;
	ExecuteFillingFormCreation();
	
EndProcedure

// Changes sections tree visibility.
&AtClient
Procedure ChangeSectionsTreeVisibility()

	Items.SectionsTreeGroup.Visible         = Not Items.SectionsTreeGroup.Visible;
	Items.HideShowSectionsTree.Title = ?(Items.SectionsTreeGroup.Visible,NStr("en = 'Hide sections';"), NStr("en = 'Show sections';"));

EndProcedure 

// Controls form items availability.
&AtClient
Procedure AvailabilityControlSubordinateQuestions()
	
	For Each CollectionItem In DependentQuestions Do
		
		QuestionName = SurveysClientServer.GetQuestionName(CollectionItem.DoQueryBox);
		
		For Each SubordinateQuestion In CollectionItem.SubordinateItems Do
			
			ItemOfSubordinateQuestion = Items[SubordinateQuestion.SubordinateQuestionItemName];
			ItemOfSubordinateQuestion.ReadOnly = Not ThisObject[QuestionName];
			If StrOccurrenceCount(SubordinateQuestion.SubordinateQuestionItemName, "Attribute") = 0 Then
				
				Try
					ItemOfSubordinateQuestion.AutoMarkIncomplete = 
						ThisObject[QuestionName] And SubordinateQuestion.IsRequired;
				Except
					// 
				EndTry;
				
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure 

// Sets values of form attributes defined in a questionnaire template.
//
&AtServer
Procedure SetFormAttributesValuesAccordingToQuestionnaireTemplate()

	AttributesQuestionnaireTemplate = Common.ObjectAttributesValues(QuestionnaireTemplate,"Title,Introduction,ClosingStatement");
	FillPropertyValues(ThisObject,AttributesQuestionnaireTemplate);

EndProcedure

#EndRegion
