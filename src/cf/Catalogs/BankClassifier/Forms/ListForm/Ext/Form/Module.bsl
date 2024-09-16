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
	
	DataProcessorName = "ImportBankClassifier";
	HasDataImportSource = Metadata.DataProcessors.Find(DataProcessorName) <> Undefined;
	
	CanUpdateClassifier = False;
	DataProcessorName = "ImportBankClassifier";
	If Metadata.DataProcessors.Find(DataProcessorName) <> Undefined Then
		CanUpdateClassifier = DataProcessors[DataProcessorName].ClassifierDownloadAvailable();
	EndIf;
	
	CanUpdateClassifier = CanUpdateClassifier
		And Not Common.IsSubordinateDIBNode()   // 
		And AccessRight("Update", Metadata.Catalogs.BankClassifier); // 
	
	Items.FormImportClassifier.Visible = CanUpdateClassifier And HasDataImportSource;
	
	If Common.DataSeparationEnabled() Or Common.IsSubordinateDIBNode() Then
		ReadOnly = True;
	EndIf;
	
	PromptToImportClassifier = CanUpdateClassifier And HasDataImportSource 
		And BankManagerInternal.PromptToImportClassifier();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If PromptToImportClassifier Then
		AttachIdleHandler("SuggestToImportClassifier", 1, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ImportClassifier(Command)
	
	BankManagerClient.OpenClassifierImportForm();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("OutOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

&AtClient
Procedure SuggestToImportClassifier()
	
	BankManagerClient.SuggestToImportClassifier();
	
EndProcedure

#EndRegion