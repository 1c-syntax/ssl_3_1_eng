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
	
	Return "http://www.1c.ru/SaaS/ExchangeAdministration/Control";
	
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
	
	Return "ExchangeAdministrationControl";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesDataExchangeAdministrationControlMessageHandler_2_1_2_1);
	
EndProcedure

// Registers handlers for broadcast messages.
//
// Parameters:
//   HandlersArray - Array of CommonModule -  a collection of modules containing handlers.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
EndProcedure

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}CorrespondentConnectionCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function CorrespondentConnectionCompletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "CorrespondentConnectionCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}CorrespondentConnectionFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function CorrespondentConnectionErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "CorrespondentConnectionFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}GettingSyncSettingsCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function DataSynchronizationSettingsReceivedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingSyncSettingsCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}GettingSyncSettingsFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function DataSynchronizationSettingsReceivingErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "GettingSyncSettingsFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}EnableSyncCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SynchronizationEnabledSuccessfullyMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "EnableSyncCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}DisableSyncCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SynchronizationDisabledMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DisableSyncCompleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}EnableSyncFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SynchronizationEnablingErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "EnableSyncFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}DisableSyncFailed
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SynchronizationDisablingErrorMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DisableSyncFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/SaaS/ExchangeAdministration/Control/a.b.c.d}SyncCompleted
//
// Parameters:
//   PackageToUse - String -  namespace of the message interface version for which
//                                the message type is obtained.
//
// Returns:
//   XDTOObjectType - 
//
Function SynchronizationDoneMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SyncCompleted");
	
EndFunction

#EndRegion

#Region Private

// For internal use
//
Function GenerateMessageType(Val PackageToUse, Val Type)
	
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion
