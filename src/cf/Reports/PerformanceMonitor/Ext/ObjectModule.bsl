﻿///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	PeriodSetting = SettingsComposer.Settings.DataParameters.Items.Find("Period");
	PeriodUserSetting = SettingsComposer.UserSettings.Items.Find(PeriodSetting.UserSettingID); 
	Period = ?(PeriodUserSetting <> Undefined, PeriodUserSetting.Value, PeriodSetting.Value); // StandardPeriod
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("BeginOfPeriod"); 
	DataParameter.Value = ToUniversalTime(Period.StartDate);
	DataParameter.Use = True;
	
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("EndOfPeriod");
	DataParameter.Value = ToUniversalTime(Period.EndDate);
	DataParameter.Use = True;
	
	ComparisonPeriodSetting = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriod");
	ComparisonPeriodUserSetting = SettingsComposer.UserSettings.Items.Find(ComparisonPeriodSetting.UserSettingID);
	
	If ComparisonPeriodUserSetting <> Undefined
		And ComparisonPeriodUserSetting.Use Then
	
		Period = ComparisonPeriodUserSetting.Value; // StandardPeriod
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodStartNumber");
		DataParameter.Value = (ToUniversalTime(Period.StartDate) - Date(1,1,1)) * 1000;
		DataParameter.Use = True;
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodEndNumber");
		DataParameter.Value = (ToUniversalTime(Period.EndDate) - Date(1,1,1)) * 1000;
		DataParameter.Use = True;		
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonType");
		DataParameterComparisonType = SettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If DataParameterComparisonType.Value = "LeftJoin" Then
			QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
			DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "LEFT JOIN");
		ElsIf DataParameterComparisonType.Value = "InnerJoin" Then
			QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
			DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "INNER JOIN");
		ElsIf DataParameterComparisonType.Value = "FullJoin" Then
			QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
			DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "FULL JOIN");
		EndIf;
	Else
		
		If ComparisonPeriodUserSetting = Undefined Then
			ComparisonPeriodSetting.Use = False;
			DataParameterComparisonType = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonType");
			DataParameterComparisonType.Use = False;
		EndIf;
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodStartNumber");
		DataParameter.Value = 2;
		DataParameter.Use = True;
		
		DataParameter = SettingsComposer.Settings.DataParameters.Items.Find("ComparisonPeriodEndNumber");
		DataParameter.Value = 1;
		DataParameter.Use = True;
		
		QueryText = DataCompositionSchema.DataSets.DataSetMeasurements.Query;
		DataCompositionSchema.DataSets.DataSetMeasurements.Query = StrReplace(QueryText, "{LEFT JOIN}", "LEFT JOIN");
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("en = 'Invalid object call on the client.';");
#EndIf