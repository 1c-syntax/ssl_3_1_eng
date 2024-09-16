///////////////////////////////////////////////////////////////////////////////////////////////////////
// 
//  
// 
// 
// 
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

#Region ForCallsFromOtherSubsystems

// Returns the current (used by the calling code) version of the message interface
//
// Returns:
//   String
//
Function Version() Export
	
	Return "1.0.0.2";
	
EndFunction

#EndRegion

#EndRegion

#Region Private

// Returns the namespace of the current (used by the calling code) version of the message interface.
//
// Parameters:
//   Version - String -  if this parameter is set, the specified version is included in the namespace instead of the current version.
//
// Returns:
//   String
//
Function Package(Val Version = "") Export
	
	If IsBlankString(Version) Then
		Version = Version();
	EndIf;
	
	Return "http://www.1c.ru/1cFresh/ApplicationExtensions/Manifest/" + Version;
	
EndFunction

// Returns the name of the message programming interface
//
// Returns:
//   String
//
Function Public() Export
	
	Return "ApplicationExtensionsCore";
	
EndFunction

// Registers message handlers as message channel handlers.
//
// Parameters:
//  HandlersArray - Array -  General modules or Manager modules.
//
Procedure MessagesChannelsHandlers(Val HandlersArray) Export
	
EndProcedure

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionAssignmentObject
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTODataObject
//
Function TypeRelatedObject(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionAssignmentObject");
	
EndFunction

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionSubsystemsAssignment
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function AssignmentToSectionsType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionSubsystemsAssignment");
	
EndFunction

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionCatalogsAndDocumentsAssignment
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function AssignmentToCatalogsAndDocumentsType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionCatalogsAndDocumentsAssignment");
	
EndFunction

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionCommand
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function CommandType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionCommand");
	
EndFunction

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionReportVariantAssignment
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function ReportOptionAssignmentType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionReportVariantAssignment");
	
EndFunction

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionReportVariant
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function ReportOptionType1(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionReportVariant");
	
EndFunction

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionCommandSettings
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function CommandSettingsType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionCommandSettings");
	
EndFunction

// Returns the type of {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d}ExtensionManifest
//
// Parameters:
//  PackageToUse - String -  namespace of the message interface version for which
//    the message type is obtained.
//
// Returns:
//  XDTOObjectType
//
Function ManifestType(Val PackageToUse = Undefined) Export
	
	Return GenerateMessageType(PackageToUse, "ExtensionManifest");
	
EndFunction

// Returns a dictionary of matches
// of enumeration values of the viewadditional reports and Processing to values of the XDTO type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d} ExtensionCategory
//
// Returns:
//  Structure
//
Function AdditionalReportsAndDataProcessorsKindsDictionary() Export
	
	Dictionary = New Structure();
	Manager = Enums.AdditionalReportsAndDataProcessorsKinds;
	
	Dictionary.Insert("AdditionalProcessor", Manager.AdditionalDataProcessor);
	Dictionary.Insert("AdditionalReport", Manager.AdditionalReport);
	Dictionary.Insert("ObjectFilling", Manager.ObjectFilling);
	Dictionary.Insert("Report", Manager.Report);
	Dictionary.Insert("PrintedForm", Manager.PrintForm);
	Dictionary.Insert("LinkedObjectCreation", Manager.RelatedObjectsCreation);
	Dictionary.Insert("TemplatesMessages", Manager.MessageTemplate);
	
	Return Dictionary;
	
EndFunction

// Returns a dictionary of matches
// of enumeration values for the method of additional processing To values of the XDTO type {http://www.1c.ru/1cFresh/ApplicationExtensions/Core/a.b.c.d} ExtensionStartupType
//
// Returns:
//  Structure
//
Function AdditionalReportsAndDataProcessorsCallMethodsDictionary() Export
	
	Dictionary = New Structure();
	Manager = Enums.AdditionalDataProcessorsCallMethods;
	
	Dictionary.Insert("ClientCall", Manager.ClientMethodCall);
	Dictionary.Insert("ServerCall", Manager.ServerMethodCall);
	Dictionary.Insert("FormOpen", Manager.OpeningForm);
	Dictionary.Insert("FormFill", Manager.FillingForm);
	Dictionary.Insert("SafeModeExtension", Manager.SafeModeScenario);
	
	Return Dictionary;
	
EndFunction

Function GenerateMessageType(Val PackageToUse, Val Type)
		
	If PackageToUse = Undefined Then
		PackageToUse = Package();
	EndIf;
	
	Return XDTOFactory.Type(PackageToUse, Type);
	
EndFunction

#EndRegion