///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the version number that the handler is intended to broadcast from.
//
// Returns:
//   String
//
Function SourceVersion() Export
	
	Return "3.0.1.1";
	
EndFunction

// Returns the namespace of the version that the handler is intended to broadcast from.
//
// Returns:
//   String
//
Function SourceVersionPackage() Export
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Manage/" + SourceVersion();
	
EndFunction

// Returns the version number that the handler is intended to translate to.
//
// Returns:
//   String
//
Function ResultingVersion() Export
	
	Return "2.1.2.1";
	
EndFunction

// Returns the namespace of the version that the handler is intended to translate to.
//
// Returns:
//   String
//
Function ResultingVersionPackage() Export
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Manage";
	
EndFunction

// Handler for checking the execution of standard translation processing
//
// Parameters:
//  SourceMessage - XDTODataObject -  broadcast message,
//  StandardProcessing - Boolean -  to cancel standard translation processing
//    , this parameter must be set to False within this procedure.
//    In this case, instead of performing standard translation processing, the function will be called
//    Broadcast messages () of the broadcast handler.
//
Procedure BeforeTranslate(Val SourceMessage, StandardProcessing) Export
	
EndProcedure

// Handler for performing an arbitrary message translation. Called only
//  if the value of the standard Processing parameter
//  was set to False when executing the procedure before Translation.
//
// Parameters:
//  SourceMessage - XDTODataObject -  broadcast message.
//
// Returns:
//  XDTODataObject - 
//
Function MessageTranslation(Val SourceMessage) Export
	
EndFunction

#EndRegion




