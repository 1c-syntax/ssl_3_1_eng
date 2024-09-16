///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenCommonTransportSettings(Command)
	
	Filter              = New Structure("CorrespondentEndpoint", Record.CorrespondentEndpoint);
	FillingValues = New Structure("CorrespondentEndpoint", Record.CorrespondentEndpoint);
	
	DataExchangeClient.OpenInformationRegisterWriteFormByFilter(Filter, FillingValues, "DataAreasExchangeTransportSettings", ThisObject);
	
EndProcedure

#EndRegion
