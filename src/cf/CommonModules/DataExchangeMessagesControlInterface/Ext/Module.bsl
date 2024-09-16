///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Namespace of the current (used by the calling code) version of the message interface.
//
// Returns:
//   String -  name space.
//
Function Package() Export
	
	Return "http://www.1c.ru/SaaS/Exchange/Control";
	
EndFunction

// The current version of the message interface (used by the calling code).
//
// Returns:
//   String - 
//
Function Version() Export
	
	Return "2.1.2.1";
	
EndFunction

// Name of the message programming interface.
//
// Returns:
//   String - 
//
Function Public() Export
	
	Return "ExchangeControl";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(DataExchangeMessagesControlMessageHandler_2_1_2_1);
	
EndProcedure

// Registers handlers for broadcast messages.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
EndProcedure

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}SetupExchangeStep1Completed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ExchangeSetupStep1CompletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetupExchangeStep1Completed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}SetupExchangeStep2Completed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ExchangeSetupStep2CompletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetupExchangeStep2Completed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}SetupExchangeStep1Failed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ExchangeSetupErrorStep1Message(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetupExchangeStep1Failed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}SetupExchangeStep2Failed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ExchangeSetupErrorStep2Message(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetupExchangeStep2Failed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}DownloadMessageCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ExchangeMessageImportCompletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DownloadMessageCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}DownloadMessageFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ExchangeMessageImportErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DownloadMessageFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}GettingDataCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function CorrespondentDataGettingCompletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingDataCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}GettingCommonNodsDataCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function GettingCommonDataOfCorrespondentNodeCompletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingCommonNodsDataCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}GettingDataFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function CorrespondentDataGettingErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingDataFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}GettingCommonNodsDataFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function CorrespondentNodeCommonDataGettingErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingCommonNodsDataFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}GettingCorrespondentParamsCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function GettingCorrespondentAccountingParametersCompletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingCorrespondentParamsCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Control/a.b.c.d}GettingCorrespondentParamsFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function CorrespondentAccountingParametersGettingErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingCorrespondentParamsFailed");
	
EndFunction

#EndRegion

#Region Private

Function GenerateMessageType(Val PackageToUse, Val Type)
	
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion
