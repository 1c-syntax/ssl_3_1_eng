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
	
	CloseOnOwnerClose = True;
	
	Title = Parameters.Title;
	
	If Parameters.Property("SettingsComposerAddress", SettingsComposerAddress) Then
		// 
		Data = GetFromTempStorage(SettingsComposerAddress);
 		CompositionSchemaAddress = PutToTempStorage(Data.CompositionSchema, UUID);
		SettingsComposer = New DataCompositionSettingsComposer;
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(CompositionSchemaAddress));
		SettingsComposer.LoadSettings(Data.Settings);
	Else
		CompositionSchemaAddress = "";
		SettingsComposer = Parameters.SettingsComposer;
	EndIf;
	
	Parameters.Property("DataPeriod", DataPeriod);
	
	If Parameters.PeriodSelection Then
		ExportForPeriod = True;
	Else
		ExportForPeriod = False;
		// 
		Items.DataPeriod.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetPeriodFilterEnabled();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataPeriodClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	NotifyChoice(SelectionResult());
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetPeriodFilterEnabled()
	Items.DataPeriod.Enabled = ExportForPeriod;
EndProcedure

&AtServer
Function SelectionResult()
	Result = New Structure;
	Result.Insert("ChoiceAction",      Parameters.ChoiceAction);
	Result.Insert("SettingsComposer", SettingsComposer);
	Result.Insert("DataPeriod",        ?(ExportForPeriod, DataPeriod, New StandardPeriod));
	
	Result.Insert("SettingsComposerAddress");
	If Not IsBlankString(SettingsComposerAddress) Then
		Data = New Structure;
		Data.Insert("Settings", SettingsComposer.Settings);
		
		CompositionSchema = ?(IsBlankString(CompositionSchemaAddress), Undefined, GetFromTempStorage(CompositionSchemaAddress));
		Data.Insert("CompositionSchema", CompositionSchema);
		
		Result.SettingsComposerAddress = PutToTempStorage(Data, Parameters.FormStorageAddress);
	EndIf;
		
	Return Result;
EndFunction

#EndRegion
