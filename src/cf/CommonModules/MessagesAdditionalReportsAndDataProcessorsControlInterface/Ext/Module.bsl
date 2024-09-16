///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ForCallsFromOtherSubsystems

// Returns the current (used by the calling code) version of the message interface.
//
// Returns:
//   String
//
Function Version() Export
	
	Return "1.0.1.1";
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns the namespace of the current (used by the calling code) version of the message interface.
//
// Returns:
//   String
//
Function Package() Export
	
	Return "http://www.1c.ru/1cFresh/ApplicationExtensions/Control/" + Version();
	
EndFunction

// Returns the name of the message programming interface.
//
// Returns:
//   String
//
Function Public() Export
	
	Return "ApplicationExtensionsControl";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//  HandlersArray - Array -  General modules or Manager modules.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
EndProcedure

// Registers handlers for broadcast messages.
//
// Parameters:
//  HandlersArray - Array -  General modules or Manager modules.
//
Procedure MessagesTranslationHandlers(Val HandlersArray) Export
	
	HandlersArray.Add(MessagesAdditionalReportsAndDataProcessorsControlTranslationHandler_1_0_0_1);
	
EndProcedure

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Control/a.b.c.d}ExtensionInstalled
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function AdditionalReportOrDataProcessorInstalledMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionInstalled");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Control/a.b.c.d} ExtensionDeleted
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function AdditionalReportOrDataProcessorDeletedMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionDeleted");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Control/a.b.c.d} ExtensionInstallFailed
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function ErrorOfAdditionalReportOrDataProcessorInstallationMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionInstallFailed");
	
EndFunction

// Returns the message type {http://www.1c.ru/1cFresh/ApplicationExtensions/Control/a.b.c.d} ExtensionDeleteFailed
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function ErrorOfAdditionalReportOrDataProcessorDeletionMessage(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionDeleteFailed");
	
EndFunction

Function GenerateMessageType(Val PackageToUse, Val Type)
	
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion
