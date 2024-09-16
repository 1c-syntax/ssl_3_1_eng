///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns the namespace of the current (used by the calling code) version of the message interface.
//
// Returns:
//   String
//
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/ApplicationExtensions/Management/" + Version();
	
EndFunction

// Returns the current (used by the calling code) version of the message interface.
//
// Returns:
//   String
//
Function Version() Export
	
	Return "1.0.1.2";
	
EndFunction

// Returns the name of the message programming interface.
//
// Returns:
//   String
//
Function Public() Export
	
	Return "ApplicationExtensionsManagement";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//  HandlersArray - Array -  General modules or Manager modules.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(AdditionalReportsAndDataProcessorsManagementMessagesMessageHandler_1_0_1_1);
	HandlersArray.Add(AdditionalReportsAndDataProcessorsManagementMessagesMessageHandler_1_0_1_2);
	
EndProcedure

// Registers handlers for broadcast messages.
//
// Parameters:
//  HandlersArray - Array -  General modules or Manager modules.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
	
	
EndProcedure

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}InstallExtension
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function MessageSetAdditionalReportOrDataProcessor(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "InstallExtension");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d} ExtensionCommandSettings
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function AdditionalReportOrDataProcessorCommandSettingType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionCommandSettings");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}DeleteExtension
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function MessageDeleteAdditionalReportOrDataProcessor(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DeleteExtension");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}DisableExtension
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function MessageDisableAdditionalReportOrDataProcessor(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DisableExtension");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}EnableExtension
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function MessageEnableAdditionalReportOrDataProcessor(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "EnableExtension");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}DropExtension
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function MessageWithdrawAdditionalReportOrDataProcessor(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "DropExtension");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Management/a.b.c.d}SetExtensionSecurityProfile
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function MessageSetAdditionalReportOrDataProcessorExecutionModeInDataArea(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "SetExtensionSecurityProfile");
	
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