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
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Manage/" + Version();
	
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
	
	Return "ExchangeAdministrationManage";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesDataExchangeAdministrationManagementMessageHandler_2_1_2_1);
	HandlersArray.Add(MessagesDataExchangeAdministrationManagementMessageHandler_3_0_1_1);
	
EndProcedure

// Registers handlers for broadcast messages.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesDataExchangeAdministrationManagementTranslation_2_1_2_1);
	
EndProcedure

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}ConnectCorrespondent
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ConnectCorrespondentMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ConnectCorrespondent");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}SetTransportParams
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SetTransportSettingsMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetTransportParams");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}GetSyncSettings
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function GetDataSynchronizationSettingsMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GetSyncSettings");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}DeleteSync
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function DeleteSynchronizationSettingMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DeleteSync");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}EnableSync
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function EnableSynchronizationMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "EnableSync");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}DisableSync
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function DisableSynchronizationMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DisableSync");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}PushSync
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function PushSynchronizationMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "PushSync");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d}PushTwoApplicationSync
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function PushSynchronizationBetweenTwoApplicationsMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "PushTwoApplicationSync");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Manage/a.b.c.d} ExecuteSync
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function ExecuteDataSynchronizationMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExecuteSync");
	
EndFunction

// 
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType 
//
Function MessageDisableSyncOverSM(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DisableSyncInSM");
	
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
