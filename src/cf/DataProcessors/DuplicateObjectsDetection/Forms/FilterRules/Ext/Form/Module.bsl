///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

// 
//
//     
//                                                                 
//     
//                                                
//     
//     
//
// 
//
//     
//     
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MasterFormID = Parameters.MasterFormID;
	
	PrefilterComposer = New DataCompositionSettingsComposer;
	PrefilterComposer.Initialize( 
		New DataCompositionAvailableSettingsSource(Parameters.CompositionSchemaAddress) );
		
	FilterComposerSettingsAddress = Parameters.FilterComposerSettingsAddress;
	PrefilterComposer.LoadSettings(GetFromTempStorage(FilterComposerSettingsAddress));
	DeleteFromTempStorage(FilterComposerSettingsAddress);
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("en = 'Filter rule: %1';"), 
		Parameters.FilterAreaPresentation);
	
	IsMobileClient = Common.IsMobileClient();
	If IsMobileClient Then
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
		Items.HiddenAtMobileClientGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And IsMobileClient Then
		NotifyChoice(FilterComposerSettingsAddress());
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	If Modified Then
		NotifyChoice(FilterComposerSettingsAddress());
	Else
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FilterComposerSettingsAddress()
	Return PutToTempStorage(PrefilterComposer.Settings, MasterFormID)
EndFunction


#EndRegion

