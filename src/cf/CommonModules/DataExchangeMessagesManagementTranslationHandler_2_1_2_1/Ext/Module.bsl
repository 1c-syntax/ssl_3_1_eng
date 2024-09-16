///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// The version number that the handler is intended to broadcast from.
//
// Returns:
//   String - 
//
Function SourceVersion() Export
	
	Return "3.0.1.1";
	
EndFunction

// Namespace of the version that the handler is intended to broadcast from.
//
// Returns:
//   String -  name space.
//
Function SourceVersionPackage() Export
	
	Return "http://www.1c.ru/SaaS/Exchange/Manage/3.0.1.1";
	
EndFunction

// The version number that the handler is intended to translate to.
//
// Returns:
//   String - 
//
Function ResultingVersion() Export
	
	Return "2.1.2.1";
	
EndFunction

// Namespace of the version that the handler is intended to translate to.
//
// Returns:
//   String -  name space.
//
Function ResultingVersionPackage() Export
	
	Return "http://www.1c.ru/SaaS/Exchange/Manage";
	
EndFunction

// Handler for checking the execution of standard translation processing.
//
// Parameters:
//   SourceMessage    - XDTODataObject -  broadcast message.
//   StandardProcessing - Boolean -  to cancel the standard translation processing
//                          , this parameter must be set to False within this procedure.
//                          In this case, the function will be called instead of performing standard translation processing.
//                          Broadcast messages () of the broadcast handler.
//
Procedure BeforeTranslate(Val SourceMessage, StandardProcessing) Export
	
	BodyType = SourceMessage.Type();
	
	If BodyType = Interface().SetUpExchangeStep1Message(SourceVersionPackage()) Then
		StandardProcessing = False;
	ElsIf BodyType = Interface().ImportExchangeMessageMessage(SourceVersionPackage()) Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

// Handler for performing an arbitrary message translation. Called only
// if the value of the standard Processing parameter
// was set to False when executing the procedure before Translation.
//
// Parameters:
//   SourceMessage - XDTODataObject -  broadcast message.
//
// Returns:
//   XDTODataObject - 
//
Function MessageTranslation(Val SourceMessage) Export
	
	BodyType = SourceMessage.Type();
	
	If BodyType = Interface().SetUpExchangeStep1Message(SourceVersionPackage()) Then
		Return TranslateMessageConfigureExchangeStep1(SourceMessage);
	ElsIf BodyType = Interface().ImportExchangeMessageMessage(SourceVersionPackage()) Then
		Return TranslateMessageImportExchangeMessage(SourceMessage);
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function Interface()
	
	Return DataExchangeMessagesManagementInterface;
	
EndFunction

Function TranslateMessageConfigureExchangeStep1(Val SourceMessage)
	
	Result = XDTOFactory.Create(
		Interface().SetUpExchangeStep1Message(ResultingVersionPackage()));
		
	Result.SessionId = SourceMessage.SessionId;
	Result.Zone      = SourceMessage.Zone;
	
	Result.CorrespondentZone = SourceMessage.CorrespondentZone;
	
	Result.ExchangePlan = SourceMessage.ExchangePlan;
	Result.CorrespondentCode = SourceMessage.CorrespondentCode;
	Result.CorrespondentName = SourceMessage.CorrespondentName;
	Result.Code = SourceMessage.Code;
	Result.EndPoint = SourceMessage.EndPoint;
	
	If SourceMessage.IsSet("XDTOSettings") Then
		XDTOSettings = XDTOSerializer.ReadXDTO(SourceMessage.XDTOSettings);
		
		FiltersSettings = New Structure;
		FiltersSettings.Insert("XDTOCorrespondentSettings", XDTOSettings);
		
		Result.FilterSettings = XDTOSerializer.WriteXDTO(FiltersSettings);
	Else
		Result.FilterSettings = XDTOSerializer.WriteXDTO(New Structure);
	EndIf;
	
	Return Result;
	
EndFunction

Function TranslateMessageImportExchangeMessage(Val SourceMessage)
	
	Result = XDTOFactory.Create(
		Interface().ImportExchangeMessageMessage(ResultingVersionPackage()));
		
	Result.SessionId = SourceMessage.SessionId;
	Result.Zone      = SourceMessage.Zone;
	
	Result.CorrespondentZone = SourceMessage.CorrespondentZone;
	
	Result.ExchangePlan = SourceMessage.ExchangePlan;
	Result.CorrespondentCode = SourceMessage.CorrespondentCode;
	
	Return Result;
	
EndFunction

#EndRegion
