///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("ExchangePlansWithRulesFromFile") Then
		
		Items.RulesSource.Visible = False;
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"RulesSource",
			Enums.DataExchangeRulesSources.File,
			DataCompositionComparisonType.Equal);
		
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	Cancel = True;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateAllStandardRules(Command)
	
	UpdateAllStandardRulesAtServer();
	Items.List.Refresh();
	
	ShowUserNotification(NStr("en = 'The rule update is completed.'"));
	
EndProcedure

&AtClient
Procedure UseStandardRules(Command)
	UseStandardRulesAtServer();
	Items.List.Refresh();
	ShowUserNotification(NStr("en = 'The rule update is completed.'"));
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateAllStandardRulesAtServer()
	
	DataExchangeServer.UpdateDataExchangeRules();
	
	RefreshReusableValues();
	
EndProcedure

&AtServer
Procedure UseStandardRulesAtServer()
	
	For Each Record In Items.List.SelectedRows Do
		BeginTransaction();

		Try
			DataLock = New DataLock;
			DataLockItem = DataLock.Add("InformationRegister.DataExchangeRules");
			DataLockItem.SetValue("ExchangePlanName", Record.ExchangePlanName);
			DataLockItem.SetValue("RulesKind", Record.RulesKind);
			DataLockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();

			RecordManager = InformationRegisters.DataExchangeRules.CreateRecordManager();
			FillPropertyValues(RecordManager, Record);
			RecordManager.Read();
			RecordManager.RulesSource = Enums.DataExchangeRulesSources.ConfigurationTemplate;

			HasErrors = False;
			InformationRegisters.DataExchangeRules.ImportRules(HasErrors, RecordManager);

			If HasErrors Then
				RollbackTransaction();
			Else
				RecordManager.Write();
				CommitTransaction();
			EndIf;
		Except
			RollbackTransaction();

			ErrorMessage = ErrorProcessing.DetailErrorDescription(ErrorInfo());

			Event = NStr("en = 'Data exchange.Update rule'", Common.DefaultLanguageCode());

			WriteLogEvent(Event, EventLogLevel.Error,
				Metadata.InformationRegisters.DataExchangeRules, , ErrorMessage);
		EndTry;
	EndDo;
	
	DataExchangeInternal.ResetObjectsRegistrationMechanismCache();
	RefreshReusableValues();
	
EndProcedure

#EndRegion
