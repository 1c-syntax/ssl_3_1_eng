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
	
	// 
	If Not Parameters.Property("ExchangePlanName") Then
		
		Raise NStr("en = 'This is a dependent form and opens from a different form.';", Common.DefaultLanguageCode());
		
	EndIf;
	
	ExchangePlanName     = Parameters.ExchangePlanName;
	
	ExchangePlanSynonym = Metadata.ExchangePlans[ExchangePlanName].Synonym;
	
	ObjectsConversionRules = Enums.DataExchangeRulesTypes.ObjectsConversionRules;
	ObjectsRegistrationRules = Enums.DataExchangeRulesTypes.ObjectsRegistrationRules;
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(), EventLogLevel.Error,,,
		Parameters.DetailErrorDescription);
		
	Items.ErrorMessageText.Title = StringFunctions.FormattedString(
		StringFunctionsClientServer.SubstituteParametersToString(Items.ErrorMessageText.Title,
			ExchangePlanSynonym,
			Parameters.BriefErrorDescription));
	
	RulesFromFile = InformationRegisters.DataExchangeRules.RulesFromFileUsed(ExchangePlanName, True);
	
	If RulesFromFile.ConversionRules And RulesFromFile.RecordRules Then
		RulesType = NStr("en = 'conversions and registrations';");
	ElsIf RulesFromFile.ConversionRules Then
		RulesType = NStr("en = 'conversions';");
	ElsIf RulesFromFile.RecordRules Then
		RulesType = NStr("en = 'registrations';");
	EndIf;
	
	Items.RulesTextFromFile.Title = StringFunctionsClientServer.SubstituteParametersToString(
		Items.RulesTextFromFile.Title, ExchangePlanSynonym, RulesType);
	
	UpdateStartTime = Parameters.UpdateStartTime;
	If Parameters.UpdateEndTime = Undefined Then
		UpdateEndTime = CurrentSessionDate();
	Else
		UpdateEndTime = Parameters.UpdateEndTime;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExitApplication(Command)
	Close(True);
EndProcedure

&AtClient
Procedure GoToEventLog(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("StartDate", UpdateStartTime);
	FormParameters.Insert("EndDate", UpdateEndTime);
	FormParameters.Insert("ShouldNotRunInBackground", True);
	EventLogClient.OpenEventLog(FormParameters);
	
EndProcedure

&AtClient
Procedure Restart(Command)
	Close(False);
EndProcedure

&AtClient
Procedure ImportRulesSet(Command)
	
	DataExchangeClient.ImportDataSyncRules(ExchangePlanName);
	
EndProcedure

#EndRegion