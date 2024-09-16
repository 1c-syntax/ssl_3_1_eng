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
	
	Return "http://www.1c.ru/SaaS/Exchange/Manage/3.0.1.1";
	
EndFunction

// The current version of the message interface (used by the calling code).
//
// Returns:
//   String - 
//
Function Version() Export
	
	Return "3.0.1.1";
	
EndFunction

// Name of the message programming interface.
//
// Returns:
//   String - 
//
Function Public() Export
	
	Return "ExchangeManage";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(DataExchangeMessagesManagementMessageHandler_2_1_2_1);
	HandlersArray.Add(DataExchangeMessagesManagementMessageHandler_3_0_1_1);
	
EndProcedure

// Registers handlers for broadcast messages.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(DataExchangeMessagesManagementTranslationHandler_2_1_2_1);
	
EndProcedure

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Manage/a.b.c.d}SetupExchangeStep1
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SetUpExchangeStep1Message(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetupExchangeStep1");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Manage/a.b.c.d}SetupExchangeStep2
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SetUpExchangeStep2Message(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetupExchangeStep2");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Manage/a.b.c.d}DownloadMessage
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ImportExchangeMessageMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DownloadMessage");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Manage/a.b.c.d}GetData
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function GetCorrespondentDataMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GetData");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Manage/a.b.c.d}GetCommonNodsData
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function GetCommonDataOfCorrespondentNodeMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GetCommonNodsData");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/Exchange/Manage/a.b.c.d}GetCorrespondentParams
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function GetCorrespondentAccountingParametersMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GetCorrespondentParams");
	
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
